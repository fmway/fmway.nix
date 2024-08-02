{ root, lib, ... }: let
  inherit (builtins)
    filter
  ;
  inherit (root)
    tree-path
    hasSuffix'
    excludePrefix
  ;

in rec {
  genTreeImports' = folder: excludes: let
      list = tree-path { dir = folder; prefix = ""; };
      filtered = filter (x: hasSuffix' ".nix" (toString x)) list;
      excluded = excludePrefix excludes filtered;
  in map (x: folder + "/${x}") excluded;
  
  genTreeImports = folder: genTreeImports' folder [];
}
