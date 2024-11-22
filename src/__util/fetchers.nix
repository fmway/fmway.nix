{ lib, root, ... }:
rec {
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
    in throw "fetchJSON not available for now"
      # builtins.fromJSON (
      #   lib.fileContents (
      #     pkgs.fetchurl (root.excludeItems [ "headers" "method" ] args // {
      #       curlOpts = "-X ${lib.toUpper method} ${headerToOptions}";
      #     })
      #   )
      # )
    ;
    parseArg = arg: method:
      (if builtins.isString arg then
        { url = arg; }
      else if builtins.isAttrs arg then
        arg
      else throw "Unknown fetchJSON args") // { inherit method; };
  in {
    __functor = self: arg:
      fetchJSON.get arg;
    get = arg: 
      do (parseArg arg "get");
    put = arg: 
      do (parseArg arg "put");
    post = arg: 
      do (parseArg arg "post");
    delete = arg:
      do (parseArg arg "delete");
  };
}
