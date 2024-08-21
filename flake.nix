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
  in rec {
    fmway = import ./. {
      inherit (nixpkgs) lib;
      inherit pkgs;
    };
    homeManagerModules.default = fmway // {
      imports = fmway.genTreeImports ./modules/homeManager;
    };
    nixosModules.default = fmway // {
      imports = fmway.genImportsWithDefault ./modules/nixos;
    };
  };
}
