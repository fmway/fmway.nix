{ root, lib, ... }: let
  inherit (builtins)
    isString
    isAttrs
    fromJSON
    fromTOML
    mapAttrs
  ;
  inherit (root)
    hasSuffix'
    hasRegex
    hasFilename
    hasPrefix'
    doImport
    excludeItems
    getFilename
  ;

  inherit (lib)
    fileContents
  ;
  
  basicMatchers = {
    regex = re: path: hasRegex re (getFilename path);
    extension = ext: path: hasSuffix' ".${ext}" (getFilename path);
    suffix = suf: path: hasSuffix' suf (getFilename path);
    filename = file: path: hasFilename file path;
    prefix = pre: path: hasPrefix' pre (getFilename path);
  };

  basic = mapAttrs (key: value: let
    func = value;
  in selector: {
    _type = "matcher-by-${key}";
    isMatchedIn = path: func selector path;
    read = path: variables: fileContents path;
    inherit selector;
    __functor = self: args:
      self // (
        if isAttrs args then 
          args // rec {
            isMatchedIn = path: func selector path;
            selector = if args ? selector then args.selector else self.selector;
          }
        else if isString args then {
          selector = args;
          isMatchedIn = path: func args path;
        } else throw "${self._type} must be string or attrs");
  }) basicMatchers;

in basic // {
  nix = excludeItems [ "__functor" ] (basic.extension "nix" {
    _type = "matcher-by-nix";
    read = path: variables: doImport path variables;
  });
  json = excludeItems [ "__functor" ] (basic.extension "json" {
    _type = "matcher-by-json";
    read = path: variables: fromJSON (fileContents path);
  });
  toml = excludeItems [ "__functor" ] (basic.extension "toml" {
    _type = "matcher-by-toml";
    read = path: variables: fromTOML (fileContents path);
  });
}
