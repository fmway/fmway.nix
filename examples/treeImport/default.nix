{ lib ? (import <nixpkgs> {}).lib, ... }:
let
  fmway = import ../../. { inherit lib; };
in 
fmway.treeImport ./.
