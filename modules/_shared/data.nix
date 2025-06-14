{ internal, name, _file, ... }:
{ config, lib, ... } @ var: let
  inherit (lib)
    mkOption
    types
    ;
in {
  inherit _file;
  options.data = mkOption {
    type = types.attrs;
    default = {};
  };
  config = lib.mkIf (name == "homeManagerModules") {
    data = lib.mkBefore (var.osConfig.data or {});
  };
}
