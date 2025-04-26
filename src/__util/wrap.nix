{ root, inputs, ... }: let
  selfInputs = inputs;
in {
  mkFlake = { inputs, ... } @ v1: let
    inherit (inputs) flake-parts;
    overlay-lib = self: super: (v1.specialArgs.lib or {}) // {
      fmway = root // {
        getInput = x: inputs.${x} or selfInputs.${x};
      };
      flake-parts = flake-parts.lib;
    };
    arg1 = v1 // {
      specialArgs = (v1.specialArgs or {}) // {
        lib =
          (inputs.nixpkgs or selfInputs.nixpkgs).lib.extend overlay-lib;
      };
    };
  in arg2: flake-parts.lib.mkFlake arg1 ({ lib, ... }: {
    debug = lib.mkDefault true;
    imports = [
      arg2
      selfInputs.self.flakeModules.nixpkgs
      {
        perSystem = { ... }: {
          nixpkgs.overlays = [
            (self: super: {
              lib = super.lib.extend overlay-lib;
            })
          ];
        };
      }
    ];
  });
}
