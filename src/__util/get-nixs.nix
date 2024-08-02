{ root, lib, ... }: let
 inherit (builtins)
  pathExists
  readDir
 ;
 inherit (lib)
  path
  filterAttrs
  mapAttrsToList
 ;

 inherit (root)
  hasSuffix'
 ;
in rec {
  # get all directory that have default.nix
  getDefaultNixs = folder: let
    filtered = key: value:
      value == "directory" &&
      pathExists (path.append folder "${key}/default.nix");
    dir = readDir folder;
  in mapAttrsToList (name: value: "${name}") (filterAttrs filtered dir);
  
  # get all <file>.nix except default.nix
  getNixs = folder: let
    filtered = key: value:
      value == "regular" &&
      hasSuffix' ".nix" key && key != "default.nix";
    dir = readDir folder;
  in mapAttrsToList (name: value: "${name}") (filterAttrs filtered dir);

  # get all <file>.nix except default.nix also all directory that have default.nix
  getNixsWithDefault = folder: (getNixs folder) ++ (getDefaultNixs folder);
}
