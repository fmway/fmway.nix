{ lib, ... }:
{
  createShell = pkgs: v: let
    specialArgs = {
      inherit pkgs self;
    };
    module = lib.evalModules {
      inherit specialArgs;
      modules = (o.imports or []) ++ [
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
      ];
    };
    extraFiles = o.extraFiles or {};
    o =
      if lib.isFunction v then
        v (specialArgs // {
          inherit (module) config;
          inherit lib;
        })
      else
        v;
    args = removeAttrs o [ "extraFiles" "EXTRA_FILES_PATH" "imports" ] // module.config.build.env;
    self = pkgs.mkShell args // {
      inherit pkgs;
      inherit (module) config options;
    }; 
  in self;
}
