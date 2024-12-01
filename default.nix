{ lib ? (import <nixpkgs> {}).lib, ... }: let
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
   variables = { inherit lib; };
   depth = 0;
  };
in result
