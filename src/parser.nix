{ pkgs, lib, ... }: let
  inherit (lib)
    fileContents
  ;

  inherit (pkgs)
    runCommand
  ;

  inherit (builtins)
    readFile
    fromJSON
  ;
in rec {
  inherit fromJSON;
  # thanks to https://github.com/paulyoung/pub2nix
  fromYAML = yaml: fromJSON (
    readFile (
      runCommand "from-yaml"
        {
          inherit yaml;
          allowSubstitutes = false;
          preferLocalBuild = true;
        }
        ''
          echo "$yaml" | ${pkgs.remarshal}/bin/remarshal  \
            -if yaml \
            -of json \
            -o $out
        ''
    )
  );

  fromJSONC = jsonc: fromJSON (
    readFile (
      runCommand "from-jsonc"
        {
          inherit jsonc;
          allowSubstitutes = false;
          preferLocalBuild = true;
        }
        ''
          echo "$jsonc" | sed 's/\/\/.*$//g;s/\/\*.*\*\///g;/^[[:space:]]*$/d' > $out
        ''
    )
  );

  readYAML = path: fromYAML (fileContents path);
  readJSONC = path: fromJSONC (fileContents path);
  readJSON = path: fromJSON (fileContents path);
}
