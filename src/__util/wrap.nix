{ root, inputs, ... }: let
  inherit (inputs) flake-parts;
  selfInputs = inputs;
in {
  mkFlake = { inputs, ... } @ v1: let
    arg1 = v1 // {
      specialArgs = (v1.specialArgs or {}) // {
        lib = (v1.specialArgs.lib or {}) // inputs.nixpkgs.lib.extend (self: super: {
          fmway = root // {
            getInput = x: inputs.${x} or selfInputs.${x};
          };
          flake-parts = flake-parts.lib;
        });
      };
    };
  in arg2: let
    res = flake-parts.lib.evalFlakeModule arg1 arg2;
  in res.config.flake // {
    _self = { inherit (res) config options; };
  };
}
