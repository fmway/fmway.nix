{ lib, self, ... }: let
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
  listNeedFixed = [ "$" "{" "}" "." "(" ")" "[" ];

  fixedInMatch = str:
    lib.foldl' (acc: curr: acc + (if lib.any (x: curr == x) listNeedFixed then "[${curr}]" else curr)) "" (lib.splitString "" str);

  # for handle ctx multiple postfix
  getCtx = str: postfix: let
    fn = str: let
      matches = lib.match "^(.*)${fixedInMatch postfix}(.*)$" str;
      h = lib.head matches;
      t = lib.last matches;
      h'= fn h;
    in if isNull matches then str else {
      pre = if lib.isString h' then h' else fn h'.pre;
      post= lib.optionalString (!lib.isString h') h'.post + t + postfix;
    };
    res = fn str;
  in rec {
    pre' = if lib.isString res then res else res.pre;
    pre  = lib.trim pre';
    post'= if lib.isString res then "" else res.post;
    post = lib.trim post';
  };

  mkParse = experimental: { _debug ? false, prefix ? "{{", postfix ? "}}", ... } @ variables: str: let
    matches = lib.match "^(.*)${fixedInMatch prefix}(.+)${fixedInMatch postfix}(.*)$" str;
    self = mkParse experimental (variables // { inherit prefix postfix;});
  in if isNull matches then str else let
    pre = lib.elemAt matches 0;
    c   = lib.elemAt matches 1;
    ctx = getCtx c postfix;
    rest=
      if ctx.pre == "" && ctx.post == "" then
        "${prefix}${c}${postfix}"
      else if experimental then
        builtins.scopedImport variables (builtins.toFile "mkParse-expr.nix" ctx.pre)
      else lib.getAttrFromPath (lib.splitString "." ctx.pre) variables;
    post= lib.elemAt matches 2;
    res = self pre + (if lib.isStringLike rest then rest else builtins.toJSON rest) + ctx.post' + self post;
  in if _debug then
    lib.warn "(mkParse) found: ${prefix}${ctx.pre'}${postfix}" res
  else res;
in {
  inherit fromJSON fromTOML;
  fromYAML = yaml: self.readYAML (builtins.toFile "file.yaml" yaml);
  fromJSONC = jsonc: self.readJSONC (builtins.toFile "file.jsonc" jsonc);

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
  mkParse = mkParse false;
  # mkParse with all functionality in nix (like math operation)
  mkParse'= mkParse true;
}
