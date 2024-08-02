{
  description = "Collection of functions for nix in my own way";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    import ./. { inherit (nixpkgs) lib; };
}
