# devenv with nixpkgs.overlays
{ flake-parts-lib, lib, inputs, ... }: {
  options.perSystem = flake-parts-lib.mkPerSystemOption ({ config, pkgs, system, ... }: let
    devenv = lib.fmway.getInput "devenv";
    devenvType = (lib.evalModules {
      specialArgs = let
        moduleInputs = { inherit (devenv.inputs) git-hooks; } // inputs;
      in moduleInputs // {
        inputs = moduleInputs;
      };
      modules = [
        (devenv.modules + /top-level.nix)
        ({ config, pkgs, ... }: {
          packages = pkgs.lib.mkBefore [
            (import "${devenv}/src/devenv-devShell.nix" { inherit config pkgs; })
          ];
          devenv.warnOnNewVersion = false;
          devenv.flakesIntegration = true;
        })
        ({ config, options, ... }: {
          outputs = { inherit options config; };  
        })
        ({ config, options, ... }: let
          finalPkgs = pkgs.appendOverlays config.nixpkgs.overlays;
        in {
          options.nixpkgs.overlays = lib.mkOption {
            type = lib.types.listOf (lib.mkOptionType {
              name = "nixpkgs-overlay";
              description = "nixpkgs overlay";
              check = lib.isFunction;
              merge = lib.mergeOneOption;
            });
            default = [];
          };
          config = {
            _module.args = {
              pkgs = lib.mkOverride 101 finalPkgs.__splicedPackages;
            };
          };
          })
      ] ++ config.devenv.modules;
    }).type;

    shellPrefix = shellName: if shellName == "default" then "" else "${shellName}-";
  in

  {
    options.devenv.modules = lib.mkOption {
      type = lib.types.listOf lib.types.deferredModule;
      description = ''
        Extra modules to import into every shell.
        Allows flakeModules to add options to devenv for example.
      '';
      default = [ ];
    };
    options.devenv.shells = lib.mkOption {
      type = lib.types.lazyAttrsOf devenvType;
      description = ''
        The [devenv.sh](https://devenv.sh) settings, per shell.

        Each definition `devenv.shells.<name>` results in a value for
        [`devShells.<name>`](flake-parts.html#opt-perSystem.devShells).

        Define `devenv.shells.default` for the default `nix develop`
        invocation - without an argument.
      '';
      example = lib.literalExpression ''
        {
          # create devShells.default
          default = {
            # devenv settings, e.g.
            languages.elm.enable = true;
          };
        }
      '';
      default = { };
    };
    config.devShells = let
      # for lsp / completions
      shells = lib.mapAttrs (name: devenv: devenv.shell // { 
        config = config.devenv.shells.${name};
        inherit (shells.${name}.config.outputs) options;
        inherit (shells.${name}.options._module.args.value) pkgs;
      }) config.devenv.shells;
    in lib.mkIf (config.devenv.shells != {}) shells;

    config.packages =
      lib.concatMapAttrs
        (shellName: devenv:
          (lib.concatMapAttrs
            (containerName: container:
              { "${shellPrefix shellName}container-${containerName}" = container.derivation; }
            )
            devenv.containers
          ) // {
            "${shellPrefix shellName}devenv-up" = devenv.procfileScript;
            "${shellPrefix shellName}devenv-test" = devenv.test;
          }
        )
        config.devenv.shells;
  });
  _file = ./devenv-modules.nix;
}
