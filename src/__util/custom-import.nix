{ root, lib, ... }: let
  inherit (builtins)
    isPath
    isAttrs
    isList
    foldl'
    length
  ;
  inherit (lib)
    recursiveUpdate
    path
  ;

  inherit (root)
    getNixsWithDefault
    getDefaultNixs
    getNixs
    basename
    excludeItems
    doImport
  ;

   templateSingleImport = { folder, variables, list, excludes, initial }: let
    filtered = if length excludes == 0 then list else excludeItems excludes list;
  in foldl' (acc: curr: {
    "${basename curr}" = doImport (path.append folder curr) variables;
  } // acc) initial filtered;
in rec {

  # generate object for single import for all <file>.nix exclude default.nix
  customImport' = var: let
    folder = if isPath var then var else var.folder;
    excludes = if isAttrs var && var ? excludes && isList var.excludes then var.excludes else [];
    variables = if isAttrs var && var ? variables && isAttrs var.variables then var.variables else if isPath var then null else {};
  in if isList folder then
    foldl' (acc: curr: recursiveUpdate acc (customImport' {
      folder = curr;
      inherit excludes variables;
    })) {} folder 
  else let
    list = getNixs folder;
  in templateSingleImport { inherit folder variables list excludes; initial = {}; };

  # customImport = var: customImport' var {};
  customImport = var: if (var ? folder) || isPath var then
    excludeItems ["__functor"] (customImport' var)
  else
    recursiveUpdate var { __functor = self: args: recursiveUpdate (excludeItems ["__functor"] self) (customImport args); };
  
  # generate object for single import for all directory that have default.nix
  customDefaultImport' = var: let
    folder = if isPath var then var else var.folder;
    variables = if isAttrs var && var ? variables && isAttrs var.variables then var.variables else if isPath var then null else {};
    excludes = if isAttrs var && var ? excludes && isList var.excludes then var.excludes else [];
  in if isList folder then
    foldl' (acc: curr: recursiveUpdate acc (customDefaultImport' {
      folder = curr;
      inherit excludes variables;
    })) {} folder 
  else let
    list = getDefaultNixs folder;
  in templateSingleImport { inherit folder variables list excludes; initial = {}; };

  # customDefaultImport = var: customDefaultImport' var {};
  customDefaultImport = var: if (var ? folder) || isPath var then
    excludeItems ["__functor"] (customDefaultImport' var)
  else
    recursiveUpdate var { __functor = self: args: recursiveUpdate (excludeItems ["__functor"] self) (customDefaultImport args); };

  # generate object for single import for all <file>.nix except default.nix also all directory that have default.nix
  customImportWithDefault' = var: let
    folder = if isPath var then var else var.folder;
    variables = if isAttrs var && var ? variables && isAttrs var.variables then var.variables else if isPath var then null else {};
    excludes = if isAttrs var && var ? excludes && isList var.excludes then var.excludes else [];
  in if isList folder then
    foldl' (acc: curr: recursiveUpdate acc (customImportWithDefault' {
      folder = curr;
      inherit excludes variables;
    })) {} folder 
  else let
    list = getNixsWithDefault folder;
  in templateSingleImport { inherit folder variables list excludes; initial = {}; };

  # customImportWithDefault = var: customImportWithDefault' var {};
  customImportWithDefault = var: if (var ? folder) || isPath var then
    excludeItems ["__functor"] (customImportWithDefault' var)
  else
    recursiveUpdate var { __functor = self: args: recursiveUpdate (excludeItems ["__functor"] self) (customImportWithDefault args); };
}
