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
  in {
    inherit fmway;
    homeManagerModules.default = {
      lib = { inherit fmway; };
      imports = fmway.genTreeImports ./modules/homeManager;
      # options.lib = lib.mkBefore { inherit fmway; };
      # nixpkgs.overlays = [ overlay ];
    };
    nixosModules.default = {
      lib = { inherit fmway; };
      imports = fmway.genImportsWithDefault ./modules/nixos;
      # options.lib = lib.mkBefore { inherit fmway; };
      # nixpkgs.overlays = [ overlay ];
    };
    overlays.default = overlay;
  };
}
