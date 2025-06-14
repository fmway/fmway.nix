{ inputs, config, pkgs, lib, ... }: let
  inherit (cfg) userPath dataPath;
  parseBoardConfig = path:
    lib.pipe path [
      (lib.fileContents)
      (lib.splitString "\n")
      (map lib.trim)
      (lib.filter (x: x != "" && isNull (lib.match "^#.*" x)))
      (map (x: let
        s = lib.splitString "=" x;
      in {
        name = lib.head s;
        value = lib.concatStringsSep "=" (lib.tail s);
      }))
      (lib.listToAttrs)
    ];

  listBoard = board-config:
    lib.pipe board-config [
      (lib.attrNames)
      (map (lib.match "^([^.]+)[.]build[.]board$"))
      (lib.filter lib.isList)
      (map (x: "${lib.elemAt x 0}"))
    ];

  parseLibraries = path:
    lib.pipe path [
      (builtins.readDir)
      (lib.filterAttrs (_: x: x == "directory"))
      (lib.attrNames)
      (map (name: let
        x = "${path}/${name}";
      in "-I${x}" + lib.optionalString (
          lib.pathExists "${x}/src" &&
          lib.pathIsDirectory "${x}/src"
        ) "/src"))
    ];
  cfg = config.arduino-cli;
  runtime.version = lib.pipe cfg.runtimeVersion [
    (lib.splitString ".")
    (lib.imap1 (i: v: if i != 1 && lib.toInt v < 10 then
      "0${v}"
    else v))
    (lib.concatStrings)
  ];
  defaultLibraries = parseLibraries "${userPath}/libraries";
  boards = lib.listToAttrs (lib.flatten (map (pkg: let
    r = parseBoardConfig "${pkg}/${pkg.dirName}/boards.txt";
    l = listBoard r;
  in map (board: {
    name = "${pkg.scope}:${pkg.architecture}:${board}";
    value = lib.pipe r [
      (lib.attrNames)
      (map (lib.match "^${board}[.](.+)$"))
      (lib.filter lib.isList)
      (map (lib.flip lib.elemAt 0))
      (lib.foldl' (acc: curr: acc // { "${curr}" = r."${board}.${curr}"; }) { package = pkg; })
    ];
  }) l) cfg.packages));
  sketchModule = { name, config, ... }: let
    base = "${dataPath}/${boards.${config.fqbn}.package.dirName}";
    dependenciesLibraries = lib.flatten (map (pkg: let
      basePkg = "${dataPath}/${pkg.dirName}";
    in lib.pipe basePkg [
      (builtins.readDir)
      (lib.filterAttrs (x: y:
        y == "directory" &&
        lib.pathExists "${basePkg}/${x}/include" &&
        lib.pathIsDirectory "${basePkg}/${x}/include"
      ))
      (lib.attrNames)
      (map (x: "-I${basePkg}/${x}/include"))
    ]) (boards.${config.fqbn}.package.toolsDependencies or []));
  in {
    options = {
      fqbn = lib.mkOption {
        type = lib.types.enum (lib.attrNames boards);
        description = "Fully Qualified Board Name";
      };
      port = lib.mkOption {
        type = lib.types.str;
        description = "Upload port address";
        default = "";
      };
      cFlags = lib.mkOption {
        type = with lib.types; listOf str;
        description = "cflags will be passed to .clangd";
      };
    }; 
    config = {
      cFlags =
        defaultLibraries
      ++parseLibraries "${base}/libraries"
      ++dependenciesLibraries
      ++[
        "-I${base}/cores/${boards.${config.fqbn}."build.core"}"
        "-I${base}/variants/${boards.${config.fqbn}."build.variant"}"
        # "-mmcu=${bCfg."${board}.build.mcu"}"
        "-DARDUINO=${runtime.version}"
        "-DARDUINO_${boards.${config.fqbn}."build.board"}"
        "-DARDUINO_ARCH_${lib.toUpper boards.${config.fqbn}.package.architecture}"
        "-DUSBCON"
        "-Wno-attributes"
      ];
    };
  };

  generatedClangd = lib.pipe cfg.sketch [
    (lib.attrNames)
    (map (x: {
      name = lib.optionalString (x != ".") "${x}/" + ".clangd";
      value.text = ''
        CompileFlags:
          Add:
          ${lib.concatStringsSep "\n  " (map (x: "- ${x}") cfg.sketch.${x}.cFlags)}
      '';
    }))
    (lib.listToAttrs)
  ];
  generatedSketch = lib.pipe cfg.sketch [
    (lib.attrNames)
    (map (x: {
      name = lib.optionalString (x != ".") "${x}/" + "sketch.yaml";
      value.text = ''
        default_fqbn: ${cfg.sketch.${x}.fqbn}
        default_port: ${cfg.sketch.${x}.port}
      '';
    }))
    (lib.listToAttrs)
  ];
in {
  imports = [
    inputs.arduino-nix.devenvModules.default
  ];
  options.arduino-cli.runtimeVersion = lib.mkOption {
    type = lib.types.str;
    description = "Runtime IDE version";
    default = pkgs.arduino.version;
  };
  options.arduino-cli.sketch = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule sketchModule);
    default = {};
  };
  config = lib.mkIf (cfg.sketch != {}) {
    files = lib.mkMerge [
      generatedClangd
      generatedSketch
    ];
  };
}
