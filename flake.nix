{
  description = "Collection of functions and modules for nix in my own way";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
    # TODO
    # nix-parsec.url = "github:nprindle/nix-parsec";
  };

  outputs = { self, nixpkgs, ... } @ inputs: let
    # TODO eachSystem
    inherit (nixpkgs) lib;
    fmway = let
      treeImport = import ./src/treeImport.nix rec {
        inherit lib;
        root = let
          var = { inherit lib root; };
          small = import ./src/__util/small-functions.nix var;
          for-import = import ./src/__util/for-import.nix var;
          tree-path = import ./src/tree-path.nix var;
          matchers = import ./src/matchers.nix var;
        in small // for-import // {
          inherit tree-path matchers;
        };
      };
    in treeImport {
      folder = ./src;
      variables = { inherit lib inputs; };
      depth = 0;
    };
    overlay = self: super: { inherit fmway; };
    finalLib = lib.extend overlay;
    sharedModules = isHM: map (x: { _file = x; imports = [ (import x isHM) ]; }) (fmway.genTreeImports ./modules/_shared);
    hmModules = fmway.genTreeImports ./modules/homeManager;
    nixosModules = fmway.genImportsWithDefault ./modules/nixos;
    flakeModules = builtins.listToAttrs (map (path: {
      name = fmway.basename path;
      value = "${./modules/flake}/${path}";
    }) (fmway.getNixs ./modules/flake));
  in {
    inherit fmway flakeModules;
    homeManagerModules.default = self.homeManagerModules.fmway // {
      nixpkgs.overlays = [ (_: _: { lib = finalLib; }) ];
    };
    homeManagerModules.fmway.imports = hmModules ++ sharedModules true;
    nixosModules.default = self.nixosModules.fmway // {
      nixpkgs.overlays = [ (_: _: { lib = finalLib; }) ];
    };
    nixosModules.fmway.imports = nixosModules ++ sharedModules false;
    lib = finalLib;
    overlays.default = overlay;
  };
}
