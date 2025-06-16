{ lib, ... }:
{
  createShell = pkgs: v: let
    module = lib.evalModules {
      specialArgs = { inherit self self'; };
      modules = (o.imports or []) ++ [
      { _module.args.pkgs = lib.mkDefault pkgs; }
      ({ config, ... }: {
        options.build.env = lib.mkOption {
          type = with lib.types; attrsOf str;
          default = {};
        };
        options.extraFiles = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule ({ name, config, ... }: {
            options = {
              enable = lib.mkEnableOption "" // { default = true; };
              addToGitignore = lib.mkEnableOption "";
              target = lib.mkOption {
                type = lib.types.str;
                readOnly = true;
              };
              source = lib.mkOption {
                type = with lib.types; nullOr package;
                default = null;
              };
              finalSource = lib.mkOption {
                type = lib.types.package;
                readOnly = true;
              };
              fileType = lib.mkOption {
                type = lib.types.enum [ "symlink" "block-append" "block" ];
                default = "symlink";
              };
              text = lib.mkOption {
                type = with lib.types; nullOr str;
                default = null;
              };
            };
            config.target = name;
            config.finalSource = let
              notNull = !isNull config.source || !isNull config.text;
              src =
                if ! isNull config.source then
                  config.source
                else pkgs.writeText (lib.replaceStrings ["/"] ["-"] config.target) config.text;
            in lib.mkIf notNull src;
          }));
        };

        config.build.env = let
          inherit (config) extraFiles;
          nonEmpty = extraFiles != {};
          filtered = lib.filter (x: extraFiles.${x}.enable) (lib.attrNames extraFiles);
          gitignored = lib.filter (x: extraFiles.${x}.addToGitignore) filtered;
        in lib.mkIf (nonEmpty && filtered != {}) {
          EXTRA_FILES_PATH = let
            r = map (x: let
              self = extraFiles.${x};
            in "${self.target}=${self.finalSource},${self.fileType}") filtered;
            generatedGitignore = pkgs.writeText ".gitignore" ''
              ${lib.concatStringsSep "\n" gitignored}
            '';
          in lib.concatStringsSep ":" r
           + lib.optionalString (gitignored != []) ":.gitignore=${generatedGitignore},block-append"
           + (o.EXTRA_FILES_PATH or "");
        };
      })
      { inherit extraFiles; }
      {
        extraFiles.".direnv/.gitignore" = {
          text = lib.mkDefault ''
            *
            .*
          '';
          fileType = lib.mkDefault "block";
        };
      }
      ];
    };
    extraFiles = o.extraFiles or {};
    o =
      if lib.isFunction v then
        v {
          inherit (module) config;
          inherit (module.options._module.args.value) pkgs;
          inherit lib self self';
        }
      else
        v;
    self' = removeAttrs o [ "extraFiles" "EXTRA_FILES_PATH" "imports" "_module" ] // module.config.build.env;
    self = pkgs.mkShell self' // {
      inherit (module.options._module.args.value) pkgs;
      inherit (module) config options;
      args = self';
    }; 
  in self;

  devenvToDevbox = pkgs: shell: let
    isDevboxed = x: lib.any (y: x == y) [
      "DEVENV_ROOT"
      "DEVENV_STATE"
      "DEVENV_DOTFILE"
    ];
    init = pkgs.writeScriptBin "env-init" /* bash */ ''
      #!${lib.getExe pkgs.bash}
      ${lib.pipe shell.env [
        (lib.attrNames)
        (map (x:
          "export ${x}=${
            lib.optionalString (isDevboxed x) "$DEVBOX_PROJECT_ROOT" +
            lib.escapeShellArg shell.env.${x}
          }"
        ))
        (lib.concatStringsSep "\n")
      ]}

      ${lib.replaceStrings [ "/.devenv/run" ] [ "$DEVBOX_PROJECT_ROOT/.devenv/run" ] shell.enterShell}
    '';
  in pkgs.symlinkJoin {
    inherit (shell) name;
    paths = shell.packages ++ [
      init
    ];
  };
}
