{ lib, ... }: let
  inherit (lib)
    recursiveUpdate
    fileContents
  ;

  inherit (builtins)
    fromJSON
    match
    isList
    pathExists
    head
    concatStringsSep
    isAttrs
  ;

  function = path: pkgs: obj:
    if pathExists path then
      let
        devbox = fromJSON (fileContents path);
        parse = { onStart ? false, packages ? false, env ? false }: obj:
          if onStart then let
            init =
              if devbox ? shell && devbox.shell ? init_hook then
                devbox.shell.init_hook
              else [];
            install =
              if devbox ? shell && devbox.shell ? scripts && devbox.shell.scripts ? install then
                [ devbox.shell.scripts.install ]
              else [];
            ob = recursiveUpdate {
                  idx.workspace.onStart = (
                    if init == [] then
                      {}
                    else { devbox-init = concatStringsSep " ; " init; }
                  ) // (
                    if install == [] then
                      {}
                    else { devbox-install = concatStringsSep " ; " install; }
                  );
                } obj;
            in parse { packages = true; } ob
          else if packages then let
            init = (
              if obj ? packages && isList obj.packages then
                obj.packages
              else []) ++ (
              if devbox ? packages && isList devbox.packages && devbox.packages != [] then
                map (x: let
                  matched = match "^(.+)@(.+)$" x;
                in pkgs.${head matched}) devbox.packages
              else []);
              ob = recursiveUpdate obj {
                packages = init;
              };
            in parse { env = true; } ob
          else if env then let
            init =
              if devbox ? env && isAttrs devbox.env && devbox.env != {} then
                devbox.env
              else {};
            ob = recursiveUpdate {
              env = init;
            } obj;
            in parse {} ob
          else obj;
      in parse { onStart = true; } obj
    else obj;
in function
