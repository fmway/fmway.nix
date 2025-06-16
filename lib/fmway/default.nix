{ util, ... }: let
  inherit (builtins)
    attrNames
    foldl'
  ;
in foldl' (acc: curr: util.${curr} // acc) {} (attrNames util)
