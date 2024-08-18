{
  description = "Collection of functions for nix in my own way";

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
  in {
    fmway = import ./. {
      inherit (nixpkgs) lib;
      inherit pkgs;
    };
  };
}
