isHomeManager:
{ lib
, osConfig
, config
, pkgs
, ... } @ variables: let
  cfg =
    if isHomeManager then
      config.features.script
    else config.programs.script;

  inherit (builtins)
    listToAttrs
    readFile
    pathExists
    isFunction
    isAttrs
    isString
    ;

  inherit (lib.fmway)
    doImport
    basename
    getNixs
  ;

  inherit (lib)
    mkIf
    mkEnableOption
    mkAfter
    mkBefore
    mkOption
    types
    recursiveUpdate
    setAttrByPath
    ;
    resultPath =
      (if isHomeManager then [ "home" ] else [ "environment" ]) ++
      [ "script" ];
    optionsPath = (if isHomeManager then [ "features" ] else [ "programs" ]) ++
      [ "script" ];
in {
  options = setAttrByPath resultPath (mkOption {
    type = types.attrsOf types.package;
    default = {};
  }) // setAttrByPath optionsPath {
    enable = mkEnableOption "enable script";
    cwd = mkOption {
      type = with types; oneOf [ path (listOf path) ];
      description = "directory script";
      example = ''
        cwd = ./scripts;
      '';
    };
    variables = mkOption {
      type = types.attrs;
      default = variables;
    };
  };
  config.${if isHomeManager then "home" else "environment"} = mkIf cfg.enable (let
    files =
      if builtins.isList cfg.cwd then
        lib.flatten (map (x: getNixs cfg.cwd) cfg.cwd)
      else getNixs cfg.cwd;
    result = map (file: let
      context = doImport (cfg.cwd + "/${file}") cfg.variables;
      name = basename file;
      value = 
        if isString context then 
          pkgs.writeScriptBin name context 
        else if isAttrs context then
          pkgs.writeShellApplication (recursiveUpdate { 
            inherit name;
            text = if pathExists (cfg.cwd + "/${name}.sh") then
                readFile (cfg.cwd + "/${name}.sh")
              else "echo ${name} executed";
          } context)
        else if isFunction context then let
          function = runtimeInputs: text:
            pkgs.writeShellApplication { 
              inherit name runtimeInputs text;
            };
        in context function
        else throw "${file} is not like scripts :)";
    in {
      inherit name value;
    }) files;
  in {
    ${if isHomeManager then "packages" else "systemPackages"} = mkAfter (map (x: x.value) result);
    script = listToAttrs result;
  });
}
