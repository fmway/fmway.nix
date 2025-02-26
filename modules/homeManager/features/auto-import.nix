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
  res = treeImport {
    folder = cfg.cwd;
    depth = 0; # include top-level default.nix
    inherit variables;
    inherit (cfg) excludes includes;
  };

in {
  options.features.programs.auto-import = with lib;{
    enable = mkEnableOption "enable auto import";
    auto-enable = mkEnableOption "auto enable programs" // { default = true; };
    cwd = mkOption {
      type = with types; path;
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

  config = lib.mkIf cfg.enable {
    programs = lib.recursiveUpdate res (lib.optionalAttrs (cfg.auto-enable) enableFeatures);
  };
}
