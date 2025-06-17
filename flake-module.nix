{ self, nixpkgs, ... } @ inputs: let
  inherit (nixpkgs) lib;
  readTree = import inputs.read-tree {};
  fmway = let
    var = { inherit lib root; };
    root = let
      small = import ./lib/fmway/__util/small-functions.nix var;
      for-import = import ./lib/fmway/__util/for-import.nix var;
      tree-path = import ./lib/fmway/tree-path.nix var;
      matchers = import ./lib/fmway/matchers.nix var;
    in small // for-import // {
      inherit tree-path matchers;
    };
    treeImport = import ./lib/fmway/treeImport.nix var;
    result = treeImport {
      folder = ./lib/fmway;
      variables = { inherit lib inputs; };
      depth = 0;
    };
  in result // result.parser;
  infuse = let
    fn = import inputs.infuse-nix;
    defaultInfuse = fn { inherit lib; };
    mkFn = sugars: {
      _sugars = sugars;
      __functor = self': (fn { inherit lib; sugars = self'._sugars; }).v1.infuse;
      sugarify = { ... } @ sugars': mkFn (fmway.uniqLastBy (x: x.name) (sugars ++ lib.attrsToList sugars'));
    };
  in mkFn defaultInfuse.v1.default-sugars;
  overlay = self: super: {
    inherit fmway infuse readTree mapListToAttrs;
    inherit (fmway) mkFlake;
  };
  finalLib = lib.extend overlay;
  mapListToAttrs = fn: l: lib.listToAttrs (map fn l);
in {
  inherit fmway infuse readTree;
  lib = finalLib;

  templates = let
    dir = ./templates;
    list = with lib; attrNames (
      filterAttrs (k: _: pathIsRegularFile "${dir}/${k}/flake.nix") (
        builtins.readDir dir
      )
    );
  in mapListToAttrs (name: {
    inherit name;
    value = let
      path = "${dir}/${name}";
      description = (import "${path}/flake.nix").description or "";
    in { inherit path description; };
  }) list;

  overlays.default = overlay;
} // fmway.genModules' [ "nixosModules" "homeManagerModules" ] ./modules { lib = finalLib; inherit fmway infuse readTree inputs; }
