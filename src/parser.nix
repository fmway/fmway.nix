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
  fromYAML = yaml: readYAML (pkgs.writeText "file.yaml" yaml);
  fromJSONC = jsonc: readJSONC (pkgs.writeText "file.jsonc" jsonc);

  readYAML = FILE: fromJSON (
    readFile (
      runCommand "from-yaml"
        {
          inherit FILE;
          allowSubstitutes = false;
          preferLocalBuild = true;
        }
        ''
          cat "$FILE" | ${lib.getExe pkgs.yj} > $out
        ''
    )
  );
  readJSONC = FILE:
    fromJSON (
      readFile (
        runCommand "from-jsonc"
          {
            inherit FILE;
            allowSubstitutes = false;
            preferLocalBuild = true;
          }
          ''
            ${pkgs.gcc}/bin/cpp -P -E "$FILE" > $out
          ''
      )
    );
  readJSON = path: fromJSON (fileContents path);
  readTOML = path: fromTOML (fileContents path);
}
