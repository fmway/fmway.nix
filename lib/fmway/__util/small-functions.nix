{ lib, ... }: let
  inherit (builtins)
    replaceStrings
    isAttrs
    attrNames
    foldl'
    match
    head
    isList
    filter
    any
    length
    isString
    genList
    removeAttrs
    elemAt
    split
    ;
  inherit (lib)
    hasSuffix
    splitString
    hasPrefix
    fileContents
    listToAttrs
    flatten
    removePrefix
    removeSuffix
    reverseList
    imap1
    ;
  addIndent = with-first: indent: str:
    lib.concatStringsSep "\n" (
      imap1 (i: x:
        lib.optionalString ((i != 1 || with-first) && lib.trim x != "") indent + x
      ) (lib.splitString "\n" str)
    );
in {
  inherit removeSuffix removePrefix hasPrefix hasSuffix replaceStrings;
  addIndent = addIndent true;
  addIndent'= addIndent false;
} // rec {

  # uniqBy' :: (Elem -> String) -> [Any] -> [Any]
  uniqBy = fn: arr:
    foldl' (acc: e: if any (x: fn x == fn e) acc then
      acc
    else acc ++ [ e ]) [] arr;

  # uniqLastBy' :: (Elem -> String) -> [Any] -> [Any]
  uniqLastBy = fn: arr: let
    rev = reverseList arr;
  in reverseList (uniqBy fn rev);

  # firstChar :: String -> String
  firstChar = str:
    head (filter (x: x != "") (flatten (split "(.)" str)));
  
  # readEnv :: Path -> {String}
  readEnv = file: let
    parseEnv = str: let
      res = split "^([^# ][^= ]+)=(.*)$" str;
    in if isNull res || length res <= 1 then null else elemAt res 1; # key=value => [ key value ]
    no-empty = x: x != ""; # env with no value will be ignored
    listMaybeEnv = splitString "\n" (fileContents file);
    list = filter (x: !isNull x) (map parseEnv (filter no-empty listMaybeEnv));
  in listToAttrs (map (curr: {
    name = elemAt curr 0;
    value = elemAt curr 1;
  }) list); # Just to parse .env file to mapAttrs;

  # replaceStrings' :: AttrSet -> AttrSet -> String -> String
  replaceStrings' = var: { start ? "%(", end ? ")s" } @ prefix: str: let # %(var)s 
    names = attrNames var;
    from = map (x: "${start}${x}${end}") names; 
    to   = map (x: "${toString var.${x}}") names;
  in replaceStrings from to str;

  # basename :: String -> String
  basename = k: let
    bs = baseNameOf k;
    matched = match "^(.*)\\.(.*)$" bs;
  in if matched == null then bs else head matched;

  # getFilename :: (Path | String) -> String
  getFilename = path:
    baseNameOf (toString path);

  # hasFilename :: String -> (String | Path) -> Bool
  hasFilename = filename: target:
    if isList filename then
      let
        filtered = filter (x: hasFilename x target) filename;
      in if length filtered < 1 then
        false
      else true
    else let
      target-filename = getFilename target;
    in filename == target-filename;

  # hasSuffix' :: (String | [String]) -> (Path | String) -> Bool
  hasSuffix' = suffix: target:
  if isList suffix then
    let
      filtered = filter (x: hasSuffix' x target) suffix;
    in if length filtered < 1 then
      false
    else true
  else let
    targetStr = toString target;
  in hasSuffix suffix targetStr;

  # hasExtension :: (String | [String]) -> (Path | String) -> Bool
  hasExtension = ext: target: let
    exts = if isString ext then ext else map (x: ".${x}") ext;
  in hasSuffix' exts target;
  
  # hasPrefix' :: (String | [String]) -> (Path | String) -> Bool
  hasPrefix' = prefix: target:
  if isList prefix then
    let
      filtered = filter (x: hasPrefix' x target) prefix;
    in if length filtered < 1 then
      false
    else true
  else let
    targetStr = toString target;
  in hasPrefix prefix targetStr;

  # hasRegex :: (String | [String]) -> (Path | String) -> Bool
  hasRegex = regex: target:
  if isList regex then
    let
      filtered = filter (x: hasRegex x target) regex;
    in if length filtered < 1 then false else true
  else let
    targetStr = toString target;
    matched = match regex targetStr;
  in if isNull matched then false else true;

  # removePrefix' :: (String | [String]) -> (Path | String) -> String
  removePrefix' = prefix: target:
  if isList prefix then
    let
      filtered = filter (x: hasSuffix' x target) prefix;
    in if length filtered < 1 then
      target
    else removePrefix' (head filtered) target
  else let
    targetStr = toString target;
  in removePrefix prefix targetStr;

  # removeSuffix' :: (String | [String]) -> (Path | String) -> String
  removeSuffix' = suffix: target:
  if isList suffix then
    let
      filtered = filter (x: hasSuffix' x target) suffix;
    in if length filtered < 1 then
      target
    else removeSuffix' (head filtered) target
  else let
    targetStr = toString target;
  in removeSuffix suffix targetStr;

  # removeExtension :: (String | [String]) -> (Path | String) -> String
  removeExtension = ext: target: let
    exts =
      if isString ext then
        ".${ext}"
      else
        map (x: ".${x}") ext;
  in removeSuffix' exts target;

  # stringMultiply :: String -> int -> String
  stringMultiply = str: count:
    foldl' (acc: _: str + acc) "" (genList (x: x) count);

  # excludeList :: [Any] -> [Any] -> [Any]
  excludeList = excludes: inputs: let
    fixed = map (x: toString x) excludes;
    filtering = x: ! any (y: x == y) fixed;
  in filter filtering inputs;

  # excludeAttr :: [Any] -> AttrSet -> AttrSet
  excludeAttr = lib.flip removeAttrs;

  # excludeItems :: [Any] -> (AttrSet -> AttrSet | [Any] -> [Any])
  excludeItems = excludes: inputs:
  if isList inputs then
    excludeList excludes inputs
  else if isAttrs inputs then
    excludeAttr excludes inputs
  else throw "Exclude items only support list and AttrSet :(";

  # excludePrefix :: [String] -> (String | [String]) -> [String]
  excludePrefix = excludes: prefixs: let
    fixed = map (x: toString x) excludes;
    filtering = x: ! any (y: hasPrefix' y x) fixed;
  in filter filtering prefixs;

  # excludeSuffix :: [String] -> (String | [String]) -> [String]
  excludeSuffix = excludes: suffixs: let
    fixed = map (x: toString x) excludes;
    filtering = x: ! any (y: hasSuffix' y x) fixed;
  in filter filtering suffixs;

  printPathv1 = config: x: let
    user = config.users.users.${x} or {};
    home-manager = config.home-manager.users.${x} or {};
    toString = arr: builtins.concatStringsSep ":" arr;
  in toString (
    # home-manager level
    (home-manager.home.sessionPath or [])
  ++lib.optionals (user != {}) [ 
    "${user.home}/.local/share/flatpak/exports" # flatpak user
    "${user.home}/.nix-profile/bin" # profile level
  ] ++ [
    "/var/lib/flatpak/exports" # flatpak
    "/etc/profiles/per-user/${user.name}/bin" # user level
    "/run/current-system/sw/bin" # system level
  ]);
  printPathv2 = config: user:
    lib.makeBinPath (
       config.environment.systemPackages # system packages
    ++ config.users.users.${user}.packages # user packages
    ++ lib.optionals (config ? home-manager && config.home-manager.users ? ${user}) config.home-manager.users.${user}.home.packages # home-manager packages
    );

  toCamelCase = str: let
    match = builtins.match "^(.*)[-_](.)(.*)$" str;
    cameled = imap1 (i: v: if i == 2 then
      lib.toUpper v
    else v) match;
  in if isNull match then
    str
  else toCamelCase (lib.concatStrings cameled);

  /*
    mkResolvePath :: (String | Path) -> String -> (Path | String)
    functions for resolve path by string, return itself if it doesn't seem like paths (./ , ../ or /). for example:
    ```nix
    let
      resolvePath = mkResolvePath ./.;
    in resolvePath "./mypath.json" # => ./path.json 
    ```
   */
  mkResolvePath = cwd: str: let
    matched = builtins.match "^([.]{1,2}/|/)(.+)$" str;
  in if isNull matched then
    str
  else let
    prefix = lib.head matched;
    ctx = lib.last matched;
  in if prefix == "./" then
    cwd + "/${ctx}"
  else if prefix == "../" then
    cwd + "/${ctx}"
  else /. + "/${ctx}";
}
