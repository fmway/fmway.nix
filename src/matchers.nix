{ root, ... }: let

  inherit (root)
    hasSuffix'
    hasRegex
    hasFilename
    hasPrefix'
    getFilename
  ;
in {
  regex = let
    func = re: path: hasRegex re (getFilename path);
  in rec {
    _type = "matcher-by-regex";
    isMatchedIn = path: func selector path;
    selector = "(.*)";
    __functor = self: selector: self // {
      inherit selector;
      isMatchedIn = path: func selector path;
    };
  };
  extension = selector: let
    func = ext: path: hasSuffix' ".${ext}" (getFilename path);
  in {
    inherit selector;
    _type = "matcher-by-extension";
    isMatchedIn = path: func selector path;
    __functor = self: selector: self // {
      inherit selector;
      isMatchedIn = path: func selector path;
    };
  };
  suffix = selector: let
    func = suf: path: hasSuffix' suf (getFilename path);
  in {
    inherit selector;
    _type = "matcher-by-suffix";
    isMatchedIn = path: func selector path;
    __functor = self: selector: self // {
      inherit selector;
      isMatchedIn = path: func selector path;
    };
  };
  filename = selector: let
    func = file: path: hasFilename file path;
  in {
    inherit selector;
    _type = "matcher-by-filename";
    isMatchedIn = path: func selector path;
    __functor = self: suf: self // {
      selector = suf;
      isMatchedIn = path: func suf path;
    };
  };
  prefix = selector: let
    func = pre: path: hasPrefix' pre (getFilename path);
  in {
    inherit selector;
    _type = "matcher-by-prefix";
    isMatchedIn = path: func selector path;
    __functor = self: suf: self // {
      selector = suf;
      isMatchedIn = path: func suf path;
    };
  };
}
