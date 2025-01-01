{ config
, pkgs
, lib
, ... } @ variables: let
  cfg = config.features.programs.auto-import;

  inherit (builtins)
    readDir
    attrNames
    listToAttrs
    ;

  inherit (lib.fmway)
    matchers
    removeExtension
    excludeItems
    treeImport
  ;

  enableFeatures = let
    dirs = attrNames (excludeItems [ ".alias.nix" ".var.nix" "default.nix" ] (readDir cfg.cwd)); 
  in listToAttrs (map (x: let
    exts = matchers.getExt (cfg.includes ++ [ matchers.nix ]); 
  in {
    name = removeExtension exts x;
    value = {
      enable = lib.mkDefault true;
    };
  }) dirs);

in {
  options.features.programs.auto-import = with lib;{
    enable = mkEnableOption "enable auto import";
    auto-enable = mkEnableOption "auto enable programs" // { default = true; };
    cwd = mkOption {
      type = with types; nullOr path;
      default = null;
    };
    excludes = mkOption {
      type = with types; listOf str;
      default = [];
    };

    includes = mkOption {
      type = with types; listOf attrs;
      default = [];
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && cfg.cwd != null && cfg.auto-enable) {
      programs = enableFeatures;
    })

    (lib.mkIf (cfg.enable && cfg.cwd != null) {
       programs = treeImport {
        folder = cfg.cwd;
        depth = 0; # include top-level default.nix
        inherit variables;
        inherit (cfg) excludes includes;
      };
    })
  ];
}
