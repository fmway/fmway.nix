{ lib, root, ... }:
{
  genModules = moduleDir: args: lib.pipe moduleDir [
    builtins.readDir
    (lib.filterAttrs (_: v: v == "directory"))
    (lib.attrNames)
    (map (x: let
      name = "${root.toCamelCase x}Modules";
    in {
      inherit name;
      value = let
        res = args: lib.pipe "${moduleDir}/${x}" [
          (builtins.readDir)
          (lib.filterAttrs (n: t: ! isNull (builtins.match ".+[.]nix" n) && t == "regular"))
          (lib.attrNames)
          (map (y: let
            path = "${moduleDir}/${x}/${y}";
          in {
            name = lib.removeSuffix ".nix" y;
            value = root.withImport path args;
          }))
          (lib.listToAttrs)
        ];
      in if name == "SharedModules" then
        res
      else res args;
    }))
    (lib.listToAttrs)
    (x: let
      gen = lib.listToAttrs (map (name: {
        inherit name;
        value = x.SharedModules (args // { inherit name; }) // (x.${name} or {});
      }) [ "nixosModules" "darwinModules" "homeManagerModules" ]);
    in removeAttrs x [ "SharedModules" ] // lib.optionalAttrs (x ? SharedModules) gen)
  ];
}
