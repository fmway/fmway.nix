{ lib, root, ... }:
{
  genModules = moduleDir: args: let
    shareds = [ "nixosModules" "darwinModules" "homeManagerModules" ];
    re = lib.pipe moduleDir [
      builtins.readDir
      (lib.filterAttrs (_: v: v == "directory"))
      (lib.attrNames)
      (map (dir: let
        scope = "${root.toCamelCase dir}Modules";
      in {
        name = scope;
        value = let
          res = args: lib.pipe "${moduleDir}/${dir}" [
            (builtins.readDir)
            (lib.filterAttrs (name: type:
              (! isNull (builtins.match ".+[.]nix" name) && type == "regular") ||
              (
                type == "directory" &&
                lib.pathIsRegularFile "${moduleDir}/${dir}/${name}/default.nix"
              )
            ))
            (lib.attrNames)
            (map (name: let
              path = "${moduleDir}/${dir}/${name}";
              module = lib.removeSuffix ".nix" name;
            in {
              name = module;
              value = root.withImport' path (lib.optionalAttrs (scope != "SharedModules") {
                allModules = map (x: final.${scope}.${x}) (lib.filter (x: x != module) (lib.attrNames final.${scope}));
              } // args);
            }))
            (lib.listToAttrs)
          ];
        in if scope == "SharedModules" then
          res
        else res (final // args);
      }))
      (lib.listToAttrs)
    ];
    gen = lib.listToAttrs (map (name: {
      inherit name;
      value = re.SharedModules (final // args // { inherit name; }) // (re.${name} or {});
    }) shareds);
    final = removeAttrs re [ "SharedModules" ] // lib.optionalAttrs (re ? SharedModules) gen;
  in final;
}
