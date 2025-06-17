{
  description = "Collection of functions and modules for nix in my own way";

  inputs = {
    nixpkgs.url = "github:nix-community/nixpkgs.lib";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
    infuse-nix.url = "git+https://codeberg.org/amjoseph/infuse.nix";
    infuse-nix.flake = false;
    read-tree.url = "https://code.tvl.fyi/plain/nix/readTree/default.nix";
    read-tree.flake = false;
    # TODO
    # nix-parsec.url = "github:nprindle/nix-parsec";
  };

  outputs = x: import ./flake-module.nix x;
}
