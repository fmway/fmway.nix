{
  description = "Collection of functions for nix in my own way";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # TODO
    # nix-parsec.url = "github:nprindle/nix-parsec";
  };

  outputs = { self, nixpkgs, ... } @ inputs: let
    pkgs = nixpkgs.legacyPackages.${builtins.currentSystem};
  in {
    fmway = import ./. {
      inherit (nixpkgs) lib;
      inherit pkgs;
    };
  };
}
