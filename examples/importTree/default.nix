{ lib, ... }:
{
  options.anjim = lib.mkOption {
    type = lib.types.anything;
    default = null;
  };
  options.ngocok = lib.mkOption {
    type = lib.types.anything;
    default = null;
  };
}
