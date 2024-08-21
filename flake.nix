{
  description = "Collection of functions and modules for nix in my own way";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # TODO
    # nix-parsec.url = "github:nprindle/nix-parsec";
  };

  outputs = { self, nixpkgs, ... } @ inputs: let
    # TODO eachSystem
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    inherit (nixpkgs) lib;
    fmway = import ./. { inherit pkgs lib; };
    overlay = self: super: { inherit fmway; };
    finalLib = lib.extend overlay;
  in {
    inherit fmway;
    homeManagerModules.default = {
      imports = fmway.genTreeImports ./modules/homeManager;
      nixpkgs.overlays = [ (_: _: { lib = finalLib; }) ];
    };
    nixosModules.default = {
      imports = fmway.genImportsWithDefault ./modules/nixos;
      nixpkgs.overlays = [ (_: _: { lib = finalLib; }) ];
    };
    lib = finalLib;
    overlays.default = overlay;
  };
}
