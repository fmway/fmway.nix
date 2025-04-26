{ root, inputs, ... }: let
  selfInputs = inputs;
in {
  mkFlake = { inputs, ... } @ v1: let
    inherit (inputs) flake-parts;
    arg1 = v1 // {
      specialArgs = (v1.specialArgs or {}) // {
        lib =
          (v1.specialArgs.lib or {}) //
          (inputs.nixpkgs or selfInputs.nixpkgs).lib.extend (self: super: {
            fmway = root // {
              getInput = x: inputs.${x} or selfInputs.${x};
            };
            flake-parts = flake-parts.lib;
          });
      };
    };
  in arg2: flake-parts.lib.mkFlake arg1 ({ lib, ... }: {
    debug = lib.mkDefault true;
    imports = [ arg2 ];
  });
}
