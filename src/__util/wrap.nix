{ root, ... }:
{
  mkFlake = { enableOverlays ? false, inputs, ... } @ v1: let
    arg1 = removeAttrs v1 [ "enableOverlays" ] // {
      specialArgs = (v1.specialArgs or {}) // {
        lib = inputs.nixpkgs.lib.extend (self: super: { fmway = root; flake-parts = inputs.flake-parts.lib; });
      };
    };
  in  { ... } @ v2: let
    arg2 = { pkgs, ... } @argv: let
      arg = if builtins.isAttrs v2 then v2 else v2 argv // { inherit pkgs; };
    in arg // {
      imports = (arg.imports or []) ++ [
        {
          perSystem = { system, ... }: let
            pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = let
                o = arg.flake.overlays or {};
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
