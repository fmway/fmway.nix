{ lib, config, ... }: let
  inherit (lib)
    mkOption
    types
    ;
  # cfg = config.wayland.windowManager.sway.my;
in {
  options.wayland.windowManager.sway.my = {
    extra = mkOption {
      type = types.attrs;
      default = {};
    };
  };
  config = {
    wayland.windowManager.sway.config.startup = let
      inherit (config.programs) autostart;
      result = map (p: let
        exe = lib.getExe p;
      in { command = exe; }) autostart.packages;
    in lib.mkIf autostart.enable result;
  };
}
