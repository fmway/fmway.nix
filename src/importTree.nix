{ root, lib, allFunc ? root, ... }: let
  inherit (builtins)
    isList
    isString
    isPath
    isAttrs
    isFunction
    pathExists
    warn
    readDir
    filter
    attrNames
    length
  ;

  getAlias = alias: path: let
    filtered = filter (x: x.match.isMatchedIn path && x ? alias) alias;
  in if length filtered >= 1 then (lib.last filtered).alias else null;

  getMatcher = matchers: path: let
    filtered = filter (x: x.isMatchedIn path) matchers;
  in if length filtered >= 1 then lib.last filtered else null;

  /*
    self = any
   */
  toImports = self: finalConfig: superConfig: includes: excludes: variables: alias: get:
    if isList self then let
      selfConfig = lib.getAttrFromPath get finalConfig;
    in 
      map (x: toImports x finalConfig selfConfig includes excludes variables alias get) self
    else if (isPath self || (lib.isString self && (pathExists self || throw "treeImport: ${self} No suck file or directory"))) && lib.pathIsDirectory self then
      let
        ext = root.matchers.getExt inc;
        settings = lib.optionalAttrs (pathExists "${self}/.settings.nix") (let
          res = root.doImport "${self}/.settings.nix" var; # TODO type checking
        in res);
        var = variables // { inherit settings; } //
        lib.optionalAttrs (pathExists "${self}/.var.nix" && warn ".var.nix will be removed, move to .settings.nix") (let
          res = root.doImport "${self}/.var.nix" variables;
        in res);
        ali = alias ++ (settings.alias or [])
        ++ lib.optionals (pathExists "${self}/.alias.nix" && warn ".alias.nix will be removed, move to .settings.nix") (let
          res = root.doImport "${self}/.alias.nix" var;
        in res);
        exc = excludes ++ (settings.excludes or []);
        inc = includes ++ (settings.includes or []);
        selfConfig = lib.getAttrFromPath get finalConfig;
        list = readDir self;
        fullPaths = map (x: "${x}") (attrNames list);
        filteredByIncludes = filter (x: let
          path = "${self}/${x}";
          filtered = filter (match:
            match.isMatchedIn path) inc;
        in lib.pathIsDirectory path || length filtered >= 1) fullPaths;
        filteredByExcludes = filter (x: let
          path = "${self}/${x}";
          filtered = filter (y:
            ((isPath y || (isString y && pathExists y)) && path != y) ||
            (isAttrs y && lib.hasPrefix "matcher-by" (y._type or "") && (y.isMatchedIn path)) ||
            (isString y && (let
              query = lib.splitString "/" y;
            in (lib.take (length query) (get ++ [x])) == query))
          ) exc;
        in length filtered == 0) filteredByIncludes;
        finalList = filteredByExcludes;
      in {
        imports = map (x: let
          path = "${self}/${x}";
          isDirectory = lib.pathIsDirectory path;
          isDefaultNix = x == "default.nix";
          gett = get ++ lib.optionals isDirectory [
            x
          ] ++ lib.optionals (! isDirectory && ! isDefaultNix) [
            (root.removeExtension ext x)
          ];
        in toImports path finalConfig (selfConfig // lib.optionalAttrs (! isDefaultNix) { inherit superConfig; }) inc exc var ali gett) finalList;
      }
    else
    let
      isThePath =
        isPath self || (isString self && lib.pathExists self);
      
      result = { pkgs, lib, ... } @ v: let
        selfConfig = lib.getAttrFromPath get finalConfig;
        aliased = if isThePath then getAlias alias self else null;
        matcher = getMatcher includes self;
        maybeResult1 = let
          vv = variables // {
            inherit selfConfig superConfig finalConfig;
          } // v;
        in
          if isThePath then
            matcher.read self vv
          else self;
      in 
        lib.optionalAttrs isThePath { _file = self; } //
        (if isNull aliased then
          lib.setAttrByPath get maybeResult1
        else let
          maybeResult2 = aliased maybeResult1;
        in if ! isFunction maybeResult2 then
          lib.setAttrByPath get maybeResult2
        else let
          key = (lib.take (length get - 1) get);
          last = lib.last get;
          maybeResult3 = aliased last maybeResult1;
        in lib.setAttrByPath key maybeResult3);
    in result;

  importTree = args:
  lib.throwIfNot (
    isList args &&
    lib.all (x: isPath x || (isString x && pathExists x) || isAttrs x || isFunction x) args
  ) "treeImport: mustbe listOf (path | string | attrs | function)" (
    [
    ({ pkgs, lib, config, options, ... } @ vars: {
      imports = map (x: let
        result = toImports x config null [ root.matchers.nix (root.matchers.extension "txt") ] (with root.matchers; [ (prefix ".settings") ]) {} [] [];
      in result) args;
    })
    ]
  );
in importTree
