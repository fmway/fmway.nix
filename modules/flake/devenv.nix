{ lib, inputs, ... }: let
  superInputs = inputs;
in { flake-parts-lib, lib, inputs, ... }: let
  devenv = inputs.devenv or superInputs.devenv;
in {
  imports = [
    devenv.flakeModule
  ];
  options.perSystem = flake-parts-lib.mkPerSystemOption ({ config, pkgs, system, ... }: {
    imports = [
      ({ config, ... }: {
        config = lib.mkIf (config.devenv.shells != {}) {
          devShells = let
            # for lsp / completions
            shells = lib.mapAttrs (name: devenv: devenv.shell // { 
              config = config.devenv.shells.${name};
              inherit (shells.${name}.config.outputs) options;
              inherit (shells.${name}.options._module.args.value) pkgs;
            }) config.devenv.shells;
          in lib.mkForce shells;
        };
      })
    ];
    config.devenv.modules = [
      devenv.flakeModules.readDevenvRoot
      { _module.args = { systemConfig = config; inherit system; }; }
      ({ config, options, ... }: {
        outputs = { inherit options config; };  
      })
    ];
  });
  _file = ./devenv-modules.nix;
}
