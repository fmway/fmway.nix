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
    tail
    elemAt
    split
    ;
  inherit (lib)
    lists
    hasSuffix
    splitString
    hasPrefix
    fileContents
    listToAttrs
    flatten
    removePrefix
    removeSuffix
    ;
in rec {

  firstChar = str:
    head (filter (x: x != "") (flatten (split "(.)" str)));
  
  # get attr by array e.g getAttr' [ "kamu" "asu" ] { kamu = { asu = 8; dia = 10; }; lalu = true; } => 8
  getAttr' = key: obj:
    if isList key && length key < 1 then
      obj
    else if isString key then
      obj.${key}
    else let
      res = getAttr' (head key) obj;
    in getAttr' (tail key) res;

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

  replaceStrings' = var: { start ? "%(", end ? ")s" } @ prefix: str: let # %(var)s 
    names = attrNames var;
    from = map (x: "${start}${x}${end}") names; 
    to   = map (x: "${toString var.${x}}") names;
  in replaceStrings from to str;

  basename = k: let
    bs = baseNameOf k;
    matched = match "^(.*)\\.(.*)$" bs;
  in if matched == null then bs else head matched;

  getFilename = path:
    baseNameOf (toString path);

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

  hasExtension = ext: target: let
    exts = if isString ext then ext else map (x: ".${x}") ext;
  in hasSuffix' exts target;
  
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

  hasRegex = regex: target:
  if isList regex then
    let
      filtered = filter (x: hasRegex x target) regex;
    in if length filtered < 1 then false else true
  else let
    targetStr = toString target;
    matched = match regex targetStr;
  in if isNull matched then false else true;

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

  removeExtension = ext: target: let
    exts = if isString ext then ext else map (x: ".${x}") ext;
  in  removeSuffix' exts target;

  stringMultiply = str: count:
    foldl' (acc: _: str + acc) "" (lists.range 1 count);

  excludeList = excludes: inputs: let
    fixed = map (x: toString x) excludes;
    filtering = x: ! any (y: x == y) fixed;
  in filter filtering inputs;

  excludeAttr = excludes: inputs: let
    names = excludeList excludes (attrNames inputs);
    func = acc: name: {
      "${name}" = inputs.${name};
    } // acc;
  in foldl' func {} names;

  excludeItems = excludes: inputs:
  if isList inputs then
    excludeList excludes inputs
  else if isAttrs inputs then
    excludeAttr excludes inputs
  else throw "Exclude items only support list and attrs :(";

  excludePrefix = excludes: prefixs: let
    fixed = map (x: toString x) excludes;
    filtering = x: ! any (y: hasPrefix' y x) fixed;
  in filter filtering prefixs;

  excludeSuffix = excludes: suffixs: let
    fixed = map (x: toString x) excludes;
    filtering = x: ! any (y: hasSuffix' y x) fixed;
  in filter filtering suffixs;
}
