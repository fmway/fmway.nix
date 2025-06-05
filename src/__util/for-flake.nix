{ lib, root, ... }:
{
  genModules = moduleDir: args: let
    modulesPath = builtins.toPath moduleDir;
    shareds = [ "nixosModules" "nixDarwinModules" "homeManagerModules" ];
    re = lib.pipe modulesPath [
      builtins.readDir
      (lib.filterAttrs (_: v: v == "directory"))
      (lib.attrNames)
      (map (dir: let
        scope = "${root.toCamelCase dir}Modules";
      in {
        name = scope;
        value = let
          res = args: lib.pipe "${modulesPath}/${dir}" [
            (builtins.readDir)
            (lib.filterAttrs (name: type:
              (! isNull (builtins.match ".+[.]nix" name) && type == "regular") ||
              (
                type == "directory" &&
                lib.pathIsRegularFile "${modulesPath}/${dir}/${name}/default.nix"
              )
            ))
            (lib.attrNames)
            (map (name: let
              _file = let
                path = "${modulesPath}/${dir}/${name}";
              in path + lib.optionalString (lib.pathIsDirectory path) "/default.nix";
              module = lib.removeSuffix ".nix" name;
            in {
              name = module;
              value = root.withImport' _file (lib.optionalAttrs (scope != "SharedModules") {
                allModules = map (x: final.${scope}.${x}) (lib.filter (x: x != module) (lib.attrNames final.${scope}));
              } // { inherit _file; } // args);
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
    final = removeAttrs re [ "SharedModules" ] // lib.optionalAttrs (re ? SharedModules) gen // {
      inherit modulesPath;
    };
  in final;
}
