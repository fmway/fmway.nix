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
    sharedModules = fmway.genTreeImports ./modules/_shared;
    hmModules = fmway.genTreeImports ./modules/homeManager;
    nixosModules = fmway.genImportsWithDefault ./modules/nixos;
  in {
    inherit fmway;
    homeManagerModules.default = self.homeManagerModules.fmway;
    homeManagerModules.fmway = {
      imports = hmModules ++ sharedModules;
      nixpkgs.overlays = [ (_: _: { lib = finalLib; }) ];
    };
    nixosModules.default = self.nixosModules.fmway;
    nixosModules.fmway = {
      imports = nixosModules ++ sharedModules;
      nixpkgs.overlays = [ (_: _: { lib = finalLib; }) ];
    };
    lib = finalLib;
    overlays.default = overlay;
  };
}
