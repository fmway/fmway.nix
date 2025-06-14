{ lib, root, ... }:
{
  genModules' = shareds: moduleDir: args: let
    modulesPath = builtins.toPath moduleDir;
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
            (x: lib.attrNames x ++ [ "defaultWithout" ])
            (map (name: let
              ctx = if name != "defaultWithout" then name else "default.nix";
              _file = let
                path = /. + "${modulesPath}/${dir}/${ctx}";
              in path + lib.optionalString (lib.pathIsDirectory path) "/default.nix";
              module = lib.removeSuffix ".nix" ctx;
            in {
              name = if name == "defaultWithout" then name else module;
              value = let
                r = exc: root.withImport' _file (lib.optionalAttrs (scope != "SharedModules") {
                  allModules = map (x: final.${scope}.${x}) (
                    lib.filter (x:
                      x != module &&
                      x != "defaultWithout" &&
                      x != "default" &&
                      (exc == [] || lib.all (y: x != y) exc)
                    ) (lib.attrNames final.${scope}));
                } // { inherit _file; } // args);
              in if name == "defaultWithout" then r else r [];
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

  genModules = root.genModules' [ "nixosModules" "nixDarwinModules" "homeManagerModules" ];
}
