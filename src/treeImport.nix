{ root, lib, allFunc ? root, ... }: let
  inherit (builtins)
    concatStringsSep
    length
    head
    isPath
    typeOf
    attrNames
    readFile
    tail
    isAttrs
    filter
    foldl'
  ;
  inherit (lib)
    recursiveUpdate
    splitString
    take
    last
  ;

  inherit (root)
    tree-path
    excludeItems
    hasPrefix'
    doImport
    matchers
    excludePrefix
    removePrefix'
    removeExtension
    hasSuffix'
    getAttr'
  ;

  getAlias = alias: path: let
    filtered = filter (x: x.match.isMatchedIn path && x ? alias) alias;
  in if length filtered >= 1 then (head filtered).alias else null; 

  getExt = arr: let
    filtered = filter (x: (x ? _type) && x._type == "matcher-by-extension") arr;
  in map (x: x.selector) filtered;

  toImport = self: super: root: variables: alias: get: 
  if isPath self then
    let
      res = if hasSuffix' ".nix" self then doImport self ({
        inherit root super;
        self = getAttr' get root;
      } // variables) else readFile self;
      aliased = getAlias alias self;
    in if isNull aliased then res else aliased res
  else if ! isAttrs self then
    self
  else let
    var = allFunc // variables // (
      if self ? ".var" then
        toImport self.".var" (getAttr' get root) root variables alias (get ++ [".var"])
      else {}
    );
    ali = (
      if self ? ".alias" then
        doImport self.".alias" (allFunc // var)
      else []
    ) ++ alias;
    obj = excludeItems [ ".var" ".alias" ] self;
    result = foldl' (acc: name: let
      val = obj.${name};
      isDefault = name == "default" && isPath val;
      gett = if isDefault then get else get ++ [name];
      sup = if isDefault then super else getAttr' get root;
      res = toImport val ({ inherit super; } // sup) root var ali gett;
    in recursiveUpdate acc (if isDefault then res else { "${name}" = res; })) {} (attrNames obj);
  in result;

  treeImport' = { folder, variables ? {}, depth ? 1, excludes ? [], includes ? [] }: let
    ext = [ "nix" ] ++ (getExt includes);
    toObj = arr: path:
      if length arr < 1 then
        path
      else let
        first = if length arr == 1 then removeExtension ext (head arr) else head arr;
        res = toObj (tail arr) path;
      in 
      if hasPrefix' "__" first then {
        ".var" = {
          "${removePrefix' "__" first}" = res;
        };
      } else { 
        "${first}" = res;
      };

    lists = tree-path { dir = folder; prefix = ""; };

    filteredByDepth = filter (x: let
      splitted = let
        res = splitString "/" x;
      in if last res == "default.nix" then take (length res - 1) res else res;
    in length splitted >= depth) lists;
    
    filteredByExcludes = excludePrefix excludes filteredByDepth;

    filteredByIncludes = filter (path: let
      filtered = filter (match:
        match.isMatchedIn path) ([(matchers.extension "nix")] ++ includes);
    in
      length filtered >= 1) filteredByExcludes;

    res = foldl' (acc: curr: let
      splitted = splitString "/" curr;
      path = folder + "/${curr}";
    in recursiveUpdate acc (toObj splitted path)) {} filteredByIncludes;
    result = toImport res null result variables [] [];
  # in toImport res null res variables [];
  in result;

  treeImport = obj: if isPath obj then
    treeImport { folder = obj; }
  else if isAttrs obj then
    if obj ? folder then
      excludeItems ["__functor"] (treeImport' obj)
    else
      recursiveUpdate obj { __functor = self: args: recursiveUpdate (excludeItems ["__functor"] self) (treeImport args); }
  else throw "treeImport only support path and attrs, not ${typeOf obj}";

in treeImport
