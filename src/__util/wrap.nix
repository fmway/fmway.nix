{ root, inputs, ... }: let
  selfInputs = inputs;
in {
  mkFlake = { inputs, ... } @ v1: let
    inherit (inputs) flake-parts;
    inherit (inputs.nixpkgs or selfInputs.nixpkgs) lib;
    overlay = lib: x:
      if lib.isAttrs x then
        lib.extend (_: _: x)
      else if lib.isFunction x then
        lib.extend x
      else if lib.isList x then
        lib.foldl' overlay lib x
      else throw "lib overlay doesn't support ${builtins.typeOf x}"
    ;
    overlay-lib = let
      default = v1.specialArgs.lib or {};
    in [
      {
        fmway = root // {
          getInput = x: inputs.${x} or selfInputs.${x};
        };
        inherit (selfInputs.self) infuse;
        flake-parts = flake-parts.lib;
      }
    ] ++ lib.flatten [ default ];
    arg1 = v1 // {
      specialArgs = (v1.specialArgs or {}) // {
        lib = overlay lib overlay-lib;
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
              lib = overlay super.lib overlay-lib;
            })
          ];
        };
      }
    ];
  });
}
