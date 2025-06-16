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

  outputs = { self, nixpkgs, ... } @ inputs: let
    inherit (nixpkgs) lib;
    readTree = import inputs.read-tree {};
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
      result = treeImport {
        folder = ./src;
        variables = { inherit lib inputs; };
        depth = 0;
      };
    in result // result.parser;
    infuse = let
      fn = import inputs.infuse-nix;
      defaultInfuse = fn { inherit lib; };
      mkFn = sugars: {
        _sugars = sugars;
        __functor = self': (fn { inherit lib; sugars = self'._sugars; }).v1.infuse;
        sugarify = { ... } @ sugars': mkFn (fmway.uniqLastBy (x: x.name) (sugars ++ lib.attrsToList sugars'));
      };
    in mkFn defaultInfuse.v1.default-sugars;
    overlay = self: super: {
      inherit fmway infuse readTree;
      inherit (fmway) mkFlake;
    };
    finalLib = lib.extend overlay;
  in {
    inherit fmway infuse readTree;
    lib = finalLib;

    # FIXME auto-import templates
    templates.devenv = {
      path = ./templates/devenv;
      description = "simple devenv";
    };
    templates.flake = {
      path = ./templates/flake;
      description = "flake-parts + fmway.nix";
    };
    templates.typst = {
      path = ./templates/typst;
      description = "flake-parts + fmway.nix + typix";
    };
    overlays.default = overlay;
  } // fmway.genModules' [ "nixosModules" "homeManagerModules" ] ./modules { lib = finalLib; inherit fmway infuse readTree inputs; };
}
