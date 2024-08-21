{
  description = "Collection of functions and modules for nix in my own way";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # TODO
    # nix-parsec.url = "github:nprindle/nix-parsec";
  };

  outputs = { self, nixpkgs, ... } @ inputs: let
    system = builtins.currentSystem;
    pkgs = import nixpkgs { inherit system; };
    inherit (nixpkgs) lib;
    fmway = import ./. { inherit pkgs lib; };
    overlay = self: super: { inherit fmway; };
    finalLib = self: super: {
      lib = lib.extend overlay;
    };
  in {
    inherit fmway;
    homeManagerModules.default = {
      imports = fmway.genTreeImports ./modules/homeManager;
      nixpkgs.overlays = [ finalLib ];
    };
    nixosModules.default = {
      imports = fmway.genImportsWithDefault ./modules/nixos;
      nixpkgs.overlays = [ finalLib ];
    };
    overlays.default = overlay;
  };
}
