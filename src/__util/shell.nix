{ lib, ... }:
{
  createShell = pkgs: { extraFiles ? {}, ... } @ v: let
    module = lib.evalModules {
      modules = [
      ({ config, ... }: {
        options.result = lib.mkOption {
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
              result =
                if ! isNull config.source then
                  config.source
                else pkgs.writeText (lib.replaceStrings ["/"] ["-"] config.target) config.text;
            in lib.mkIf notNull result;
          }));
        };

        config.result = let
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
          in lib.concatStringsSep ":" r + lib.optionalString (gitignored != []) ":.gitignore=${generatedGitignore},block-append";
        };
      })
      { inherit extraFiles; }
      ];
    };
    args = removeAttrs v [ "extraFiles" ] // module.config.result;
  in pkgs.mkShell args;
}
