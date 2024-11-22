{
  description = "Collection of functions and modules for nix in my own way";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # TODO
    # nix-parsec.url = "github:nprindle/nix-parsec";
  };

  outputs = { self, nixpkgs, ... } @ inputs: let
    # TODO eachSystem
    inherit (nixpkgs) lib;
    fmway = import ./. { inherit lib; };
    overlay = self: super: { inherit fmway; };
    finalLib = lib.extend overlay;
  in {
    inherit fmway;
    homeManagerModules.default = self.homeManagerModules.fmway;
    homeManagerModules.fmway = {
      imports = fmway.genTreeImports ./modules/homeManager;
      nixpkgs.overlays = [ (_: _: { lib = finalLib; }) ];
    };
    nixosModules.default = self.nixosModules.fmway;
    nixosModules.fmway = {
      imports = fmway.genImportsWithDefault ./modules/nixos;
      nixpkgs.overlays = [ (_: _: { lib = finalLib; }) ];
    };
    lib = finalLib;
    overlays.default = overlay;
  };
}
