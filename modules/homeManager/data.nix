{ lib, nixosConfig, ... }: let
  inherit (lib)
    mkOption
    mkBefore
    mkIf
    types
    ;

in {
  options.data = mkOption {
    type = types.attrs;
    default = {};
  };
  config.data = mkIf (nixosConfig ? data) (mkBefore nixosConfig.data);
}
