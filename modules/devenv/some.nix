{ ... }:
{ config, pkgs, ... }: let
  gitignore = pkgs.writeText "gitignore" ''
    *
    .*
  '';
in {
  imports = [
    ({ config, lib, ... }: {
      options.nixd.paths = lib.mkOption {
        type = with lib.types; listOf str;
        default = [];
      };

      config.env.NIXD_PATH = let
        result = lib.concatStringsSep ":" config.nixd.paths;
      in lib.mkIf (config.nixd.paths != []) result;
    })
  ];
  config.tasks."devenv:gitignore" = {
    description = "register direnv & devenv to gitignore";
    exec = /* bash */ ''
      ROOT="${config.devenv.root}"
      [ ! -d "$ROOT/.devenv" ] || cp -f "${gitignore}" "$ROOT/.devenv/.gitignore"
      [ ! -d "$ROOT/.direnv" ] || cp -f "${gitignore}" "$ROOT/.direnv/.gitignore"
    '';
    before = [ "devenv:enterShell" ];
  };
}
