{
  description = "Collection of functions and modules for nix in my own way";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # TODO
    # nix-parsec.url = "github:nprindle/nix-parsec";
  };

  outputs = { self, nixpkgs, ... } @ inputs: let
    system = builtins.currentSystem;
    pkgs = import nixpkgs {
      inherit system;
    };
    fmway = import ./. {
      inherit (nixpkgs) lib;
      inherit pkgs;
    };
    overlay = self: super: {
      functions = fmway;
    };
  in {
    inherit fmway;
    homeManagerModules.default = {
      imports = fmway.genTreeImports ./modules/homeManager;
      nixpkgs.overlays = [ overlay ];
    };
    nixosModules.default = {
      imports = fmway.genImportsWithDefault ./modules/nixos;
      nixpkgs.overlays = [ overlay ];
    };
    overlays.default = overlay;
  };
}
