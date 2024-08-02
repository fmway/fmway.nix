{ root, lib, ... }: let
  inherit (builtins)
    foldl'
  ;
  inherit (lib)
    path
  ;
  inherit (root)
    getNixs
    getDefaultNixs
    getNixsWithDefault
    excludeItems
  ;
in rec {
  # generate array for imports keyword using getNixs
  genImports' = folder: excludes: let
    list = getNixs folder;
    excluded = excludeItems excludes list;
  in foldl' (acc: curr: [
    (path.append folder curr)
  ] ++ acc) [] excluded;

  genImports = folder: genImports' folder [];

  # generate array for imports keyword using getDefaultNixs
  genDefaultImports' = folder: excludes: let
    list = getDefaultNixs folder;
    excluded = excludeItems excludes list;
  in foldl' (acc: curr: [
    (path.append folder curr)
  ] ++ acc) [] excluded;

  genDefaultImports = folder: genDefaultImports' folder [];

  # generate array for imports keyword using getNixsWithDefault
  genImportsWithDefault' = folder: excludes: let
    list = getNixsWithDefault folder;
    excluded = excludeItems excludes list;
  in foldl' (acc: curr: [
    (path.append folder curr)
  ] ++ acc) [] excluded;

  genImportsWithDefault = folder: genImportsWithDefault' folder [];
}
