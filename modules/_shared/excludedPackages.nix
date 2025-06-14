{ internal, _file, name, ... }:
{ config
, lib
, pkgs
, modulesPath
, utils ? {
  removePackagesByName = packages: packagesToRemove:
    let
      namesToRemove = map lib.getName packagesToRemove;
    in with lib;
      filter (x: !(elem (getName x) namesToRemove)) packages;
}
, ...
}: let
  contextModule =
    if name == "homeManagerModules" then
      "home-environment.nix"
    else
      "config/system-path.nix";
  defaultModule = import "${modulesPath}/${contextModule}" { inherit config lib pkgs modulesPath utils; };

  prefix = if name == "homeManagerModules" then "home" else "environment";
  packagePrefix = if name == "homeManagerModules" then "packages" else "systemPackages";
  
in {
  inherit _file;
  disabledModules = [ contextModule ];
  options = defaultModule.options // {
    ${prefix} = defaultModule.options.${prefix} // {
      ${packagePrefix} = let
        self = defaultModule.options.${prefix}.${packagePrefix};
      in self // {
        type = self.type // {
          merge = loc: defs:
            utils.removePackagesByName (self.type.merge loc defs) config.home.excludePackages;
        };
      };
      excludePackages = lib.mkOption {
        type = with lib.types; listOf package;
        description = "exclude package in `${prefix}.${packagePrefix}`";
        default = [];
      };
    };
  };
  inherit (defaultModule) config;
}
