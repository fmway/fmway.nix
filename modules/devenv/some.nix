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

      config = lib.mkIf (config.nixd.paths != []) {
        env.NIXD_PATH = lib.concatStringsSep ":" config.nixd.paths;
      };
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
