{ inputs, ... }: let
  myInputs = inputs;
in {
  mkFlake = { enableOverlays ? false, inputs, ... } @ v1: let
    arg1 = removeAttrs v1 [ "enableOverlays" ] // {
      specialArgs = (v1.specialArgs or {}) // {
        inherit (myInputs.self.outputs) lib;
      };
    };
  in  { ... } @ v2: let
    arg2 = v2 // {
      imports = (v2.imports or []) ++ [
        {
          perSystem = { system, ... }: let
            pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = let
                o = v2.overlays or {};
              in
              if o ? default then
                [ o.default ]
              else
                map (x: o.${x}) (builtins.attrNames o); 
            };
          in {
            config._module.args.pkgs = inputs.nixpkgs.lib.mkIf enableOverlays pkgs;
          };
        }
      ];
    };
  in inputs.flake-parts.lib.mkFlake arg1 arg2;
}
