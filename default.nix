{ lib ? (import <nixpkgs> {}).lib }: let
  treeImport = import ./src/treeImport.nix rec {
    inherit lib;
    root = let
      small = import ./src/__util/small-functions.nix { inherit lib; };
      for-import = import ./src/__util/for-import.nix { inherit lib root; };
      tree-path = import ./src/tree-path.nix { inherit lib; };
      matchers = import ./src/matchers.nix { inherit lib root; };
    in small // for-import // {
      inherit tree-path matchers;
    };
  };
  result = treeImport {
   folder = ./src;
   variables = { inherit lib; allFunc = result; };
   depth = 0;
  };
in result
