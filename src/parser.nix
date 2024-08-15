{ pkgs, lib, ... }: let
  inherit (lib)
    fileContents
  ;
in rec {
  # thanks to https://github.com/paulyoung/pub2nix
  fromYAML = yaml: builtins.fromJSON (
    builtins.readFile (
      pkgs.runCommand "from-yaml"
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

  readYAML = path: fromYAML (fileContents path);
}
