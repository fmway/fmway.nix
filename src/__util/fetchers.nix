{ lib, pkgs, root, ... }:
{
  # fetchJSON = { ... } @ args:
  #   builtins.fromJSON (
  #     lib.fileContents (
  #       pkgs.fetchurl args
  #     )
  #   );
  fetchJSON = let
    do = { headers ? {}, method ? "get", ... } @ args: let
      headerToOptions = builtins.concatStringsSep " " (
        map (x:
          "-H '${x}: ${headers.${x}}'"
        ) (builtins.attrNames headers)
      );
    in
      builtins.fromJSON (
        lib.fileContents (
          pkgs.fetchurl (root.excludeItems [ "headers" "method" ] args // {
            curlOpts = "-X ${lib.toUpper method} ${headerToOptions}";
          })
        )
      )
    ;
  in {
    __functor = self: arg: let
      obj =
        if builtins.isString arg then
          { url = arg; }
        else if builtins.isAttrs arg then
          arg
        else throw "Unknown fetchJSON args";
    in do obj;
    get = arg: let
      obj =
        if builtins.isString arg then
          { url = arg; method = "get"; }
        else if builtins.isAttrs arg then
          arg // { method = "get"; }
        else throw "Unknown fetchJSON args";
    in do obj;
    put = arg: let
      obj =
        if builtins.isString arg then
          { url = arg;  method = "put"; }
        else if builtins.isAttrs arg then
          arg // { method = "put"; }
        else throw "Unknown fetchJSON args";
    in do obj;
    post = arg: let
      obj =
        if builtins.isString arg then
          { url = arg; method = "post"; }
        else if builtins.isAttrs arg then
          arg // { method = "post"; }
        else throw "Unknown fetchJSON args";
    in do obj;
    delete = arg: let
      obj =
        if builtins.isString arg then
          { url = arg; method = "delete"; }
        else if builtins.isAttrs arg then
          arg // { method = "delete"; }
        else throw "Unknown fetchJSON args";
    in do obj;
  };
}
