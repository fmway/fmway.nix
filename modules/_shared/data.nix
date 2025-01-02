{ config, lib, nixosConfig, ... } @ var: let
  inherit (lib)
    mkOption
    types
    ;
  isHomeManager = var ? osConfig;
in {
  options.data = mkOption {
    type = types.attrs;
    default = {};
  };
  config = lib.mkIf isHomeManager {
    data = lib.mkBefore nixosConfig.data;
  };
}
