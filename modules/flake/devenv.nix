{ flake-parts-lib, lib, inputs, ... }: let
  inherit (inputs) devenv;
  mkScript = { config, pkgs, ... }: let
    inherit (config) procfileScript test;
    up =
      if procfileScript.name == "devenv-up" then
        "exec ${procfileScript} $@"
      else
        ''echo "No 'processes' option defined: https://devenv.sh/processes/" && exit 1'';
    default = lib.fileContents (
      lib.getExe (
        lib.elemAt (
          lib.filter (x: x.name == "devenv")
        (config.packages)) 0
      )
    );
    replaces = {
      "#!/usr/bin/env bash" = "#!${lib.getExe pkgs.bash}";
      "up)" = "up) ${up};";
      "test)" = "test) exec ${test};";
    };
  in pkgs.writeScriptBin "devenv"
    (lib.replaceStrings
      (lib.attrNames replaces)
      (lib.attrValues replaces)
    default);
in {
  imports = [
    devenv.flakeModule
  ];
  options.perSystem = flake-parts-lib.mkPerSystemOption ({ config, pkgs, system, ... }: {
    imports = [
      ({ config, pkgs, ... }: {
        config = lib.mkIf (config.devenv.shells != {}) {
          devShells = lib.mapAttrs (name: devenv: let
            shell = devenv.shell.overrideAttrs (old: {
              nativeBuildInputs =
                lib.filter
                  (x: x.name != "devenv")
                  (old.nativeBuildInputs or []) ++ [
                (mkScript { inherit pkgs; config = devenv; })
              ];
            }) // { 
              config = config.devenv.shells.${name};
              inherit (shell.config.outputs) options;
              inherit (shell.options._module.args.value) pkgs;
            };
          in lib.mkForce shell) config.devenv.shells;
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
}
