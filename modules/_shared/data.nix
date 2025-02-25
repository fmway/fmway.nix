isHomeManager:
{ config, lib, ... } @ var: let
  inherit (lib)
    mkOption
    types
    ;
in {
  options.data = mkOption {
    type = types.attrs;
    default = {};
  };
  config = lib.mkIf isHomeManager {
    data = lib.mkBefore (var.osConfig.data or {});
  };
}
