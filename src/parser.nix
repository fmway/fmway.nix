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
    fromTOML
  ;
in rec {
  inherit fromJSON fromTOML;
  fromYAML = yaml: fromJSON (
    readFile (
      runCommand "from-yaml"
        {
          inherit yaml;
          allowSubstitutes = false;
          preferLocalBuild = true;
        }
        ''
          echo "$yaml" | ${lib.getExe pkgs.yj} > $out
        ''
    )
  );

  fromJSONC = jsonc:
  fromJSON (
    readFile (
      runCommand "from-jsonc"
        {
          inherit jsonc;
          allowSubstitutes = false;
          preferLocalBuild = true;
        }
        ''
          echo "$jsonc" | sed 's/\(^\/\/\|[^"'"'"']+\/\/\).*$//g;s/\(^\/\*\|[^'"'"'"]+\/\*\).*\*\///g;/^[[:space:]]*$/d' > $out
        ''
    )
  );

  readYAML = path: fromYAML (fileContents path);
  readJSONC = path: fromJSONC (fileContents path);
  readJSON = path: fromJSON (fileContents path);
  readTOML = path: fromTOML (fileContents path);
}
