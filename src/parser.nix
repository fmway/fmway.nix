{ lib, ... }: let
  inherit (lib)
    fileContents
  ;

  # inherit (pkgs)
  #   runCommand
  # ;

  inherit (builtins)
    readFile
    fromJSON
    fromTOML
  ;
  # FIXME
  listNeedFixed = [ "$" "{" "}" "." "(" ")" ];

  fixedInMatch = str:
    lib.foldl' (acc: curr: acc + (if lib.any (x: curr == x) listNeedFixed then "[${curr}]" else curr)) "" (lib.splitString "" str);
in rec {
  inherit fromJSON fromTOML;
  fromYAML = yaml: readYAML (builtins.toFile "file.yaml" yaml);
  fromJSONC = jsonc: readJSONC (builtins.toFile "file.jsonc" jsonc);

  readYAML = FILE: throw "readYAML not available for now"
    # fromJSON (
    #   readFile (
    #     runCommand "from-yaml"
    #       {
    #         inherit FILE;
    #         allowSubstitutes = false;
    #         preferLocalBuild = true;
    #       }
    #       ''
    #         cat "$FILE" | ${lib.getExe pkgs.yj} > $out
    #       ''
    #   )
    # )
  ;
  readJSONC = FILE: throw "readJSONC not available for now"
    # fromJSON (
    #   readFile (
    #     runCommand "from-jsonc"
    #       {
    #         inherit FILE;
    #         allowSubstitutes = false;
    #         preferLocalBuild = true;
    #       }
    #       ''
    #         ${pkgs.gcc}/bin/cpp -P -E "$FILE" > $out
    #       ''
    #   )
    # )
    ;
  readJSON = path: fromJSON (fileContents path);
  readTOML = path: fromTOML (fileContents path);

  /*
    mkParse :: Attrs -> String -> String
    simple functions to handle variables inside string, first params has prefix and postfix that will inject the variable.
    example:
    ```nix
    let
      parse = mkParse {
        prefix = "\${{"; # github actions like
        postfix= "}}";
        myvar = "work";
        the.value.is = "work";
      };
    in parse "this is \${{ myvar }} and \${{ the.value.is }}" # => "this is work and work"
    ```
   */
  # FIXME handle function will be great
  mkParse = { prefix ? "{{", postfix ? "}}", ... } @ variables: str: let
    matches = lib.match "^(.*)${fixedInMatch prefix}(.+)${fixedInMatch postfix}(.*)$" str;
    self = mkParse (variables // { inherit prefix postfix;});
  in if isNull matches then str else let
    pre = lib.elemAt matches 0;
    rest= lib.getAttrFromPath (lib.splitString "." (lib.trim (lib.elemAt matches 1))) variables;
    post= lib.elemAt matches 2;
  in self pre + toString (if lib.isBool rest then builtins.toJSON rest else rest) + self post;
}
