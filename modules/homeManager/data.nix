{ lib, nixosConfig, ... }: let
  inherit (lib)
    mkOption
    mkBefore
    types
    ;

in {
  options.data = mkOption {
    type = types.attrs;
    default = {};
  };
  config.data = mkBefore nixosConfig.data;
}
