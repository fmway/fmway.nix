{ root, lib, ... }: let
  inherit (builtins)
    functionArgs
    attrNames
    isFunction
    filter
    hasAttr
  ;
  inherit (lib)
    listToAttrs
  ;

  # parse args only required to function
  getRequiredArgs = function: variables: let
    args = functionArgs function;
    argNames = filter (x: ! args.${x}) (attrNames args);
    result = listToAttrs (map (name: {
      inherit name;
      value = if hasAttr name variables then variables.${name}
        else if hasAttr name root then root.${name}
        else if name == "lib" then lib
        else abort "Jangan tolol bang! argument ${name} gak ada :(";
    }) argNames);
  in result;
in {
  doImport = path: variables: let
    imported = import path;
  in if isFunction imported && !isNull variables then
    imported (getRequiredArgs imported variables)
  else imported;
}
