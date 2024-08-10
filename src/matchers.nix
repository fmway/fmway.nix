{ root, lib, ... }: let
  inherit (builtins)
    isString
    isAttrs
    mapAttrs
  ;
  inherit (root)
    hasSuffix'
    hasRegex
    hasFilename
    hasPrefix'
    getFilename
  ;

  inherit (lib)
    fileContents
  ;
  
  matchers = {
    regex = re: path: hasRegex re (getFilename path);
    extension = ext: path: hasSuffix' ".${ext}" (getFilename path);
    suffix = suf: path: hasSuffix' suf (getFilename path);
    filename = file: path: hasFilename file path;
    prefix = pre: path: hasPrefix' pre (getFilename path);
  };

in mapAttrs (key: value: let
  func = value;
in selector: {
  _type = "matcher-by-${key}";
  isMatchedIn = path: func selector path;
  read = path: variables: fileContents path;
  __functor = self: args:
    self // (
      if isAttrs args then let
          obj = {
            isMatchedIn = path: func obj.selector path;
            selector = if args ? selector then args.selector else selector;
          };
        in args // obj
      else if isString args then {
        selector = args;
        isMatchedIn = path: func args path;
      } else throw "${self._type} must be string or attrs");
}) matchers
