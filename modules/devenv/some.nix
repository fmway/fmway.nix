{ config, lib, pkgs, ... }: let
  gitignore = pkgs.writeText "gitignore" ''
    *
    .*
  '';
in {
  imports = [
    ({ config, lib, ... }: {
      options.nixd.paths = lib.mkOption {
        type = with lib.types; listOf str;
      };

      options.backupFileExtension = lib.mkOption {
        type = with lib.types; nullOr str;
        description = "extensions to backup when its conflict";
        default = null;
      };

      config = lib.mkIf (config.nixd.paths != []) {
        env.NIXD_PATH = lib.concatStringsSep ":" config.nixd.paths;
      };
    })
    ({ name, inputs, pkgs, ... }: {
      nixd.paths = [
        "devenv (${name})=${inputs.self.outPath}#devShells.${pkgs.system}.${name}.options"
        "pkgs=${inputs.self.outPath}#devShells.${pkgs.system}.${name}.pkgs"
      ];
    })
  ];
  tasks."some:gitignore" = {
    description = "register direnv & devenv to gitignore";
    exec = /* bash */ ''
      [ ! -d "$DEVENV_ROOT/.devenv" ] || cp -f "${gitignore}" "$DEVENV_ROOT/.devenv/.gitignore"
      [ ! -d "$DEVENV_ROOT/.direnv" ] || cp -f "${gitignore}" "$DEVENV_ROOT/.direnv/.gitignore"
    '';
    before = [ "devenv:enterShell" ];
  };
  tasks."some:clean" = {
    description = "unlink previous files";
    before = [ "devenv:files" ];
    exec = /* bash */ ''
      cdd="$DEVENV_DOTFILE/.clean"
      if [ -e "$cdd" ]; then
        cat "$cdd" | while read i; do
          [ -e "$DEVENV_ROOT/$i" ] || continue
          if [ -L "$DEVENV_ROOT/$i" ]; then
            unlink "$DEVENV_ROOT/$i"
          ${lib.optionalString (!isNull config.backupFileExtension)
              ''else mv "$DEVENV_ROOT/$i" "$DEVENV_ROOT/$i${config.backupFileExtension}"''
            }
          fi
        done
      fi
    '' + lib.optionalString (config.files != []) /* bash */ ''
      cat <<EOF > "$cdd"
      ${lib.concatStringsSep "\n" (lib.attrNames config.files)}
      EOF
    '';
  };
}
