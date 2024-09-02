{ config, lib, pkgs, ... }: let
  inherit (lib)
    mkIf
    mkOption
    mkEnableOption
    types
    optionals
  ;

  inherit (builtins)
    isNull
    attrNames
  ;

  buildMe = { pname, src, name, extraPkgs, ... } @ self: let
    appimageContents = pkgs.appimageTools.extract {
      inherit pname name src;
      postExtract = ''
        main="$(basename "$(find $out -maxdepth 1 -name '*.desktop' | head -n 1)" .desktop)"
        execapp="$(cat "''${out}/''${main}.desktop" | grep Exec= | tr '=' ' ' | awk '{print $2}' | head -n 1)"
        mv $out/''${main}.desktop $out/${pname}.desktop
        substituteInPlace $out/${pname}.desktop \
          --replace "Exec=''${execapp}" 'Exec=${pname}'
      '';
    };
  in pkgs.appimageTools.wrapType2 ((if self.meta != {} then { inherit (self) meta; } else {}) // {
    inherit pname name src extraPkgs;
    extraInstallCommands = ''
      mkdir -p $out/share/icons/hicolor/512x512/apps
      install -m 444 -D ${appimageContents}/${pname}.desktop $out/share/applications/${pname}.desktop
      [ -e ${appimageContents}/usr/share ] &&
        cp -r ${appimageContents}/usr/share $out ||
        cp ${appimageContents}/*.png $out/share/icons/hicolor/512x512/apps/
    '';
  });

  cfg = config.programs.appimage;
in {
  options.programs.appimage = {
    enable = mkEnableOption "enable appimage";
    packages = mkOption {
      type = types.attrsOf (types.submodule ({ name, ... }: let
        self = cfg.packages.${name};
      in {
        options = {
          pname = mkOption {
            type = types.str;
            default = name;
          };
          version = mkOption {
            type = types.nullOr types.str;
            default = null;
          };
          name = mkOption {
            type = types.str;
            default = self.pname + (optionals (!isNull self.version) "-${self.version}");
          };
          src = mkOption {
            type = types.oneOf [ types.package types.path ];
          };
          extraPkgs = mkOption {
            type = types.functionTo (types.listOf types.package);
            default = pkgs: [];
          };
          meta = mkOption {
            type = types.attrs;
            default = {};
          };
        };
      }));
      default = {};
    };
    result = mkOption {
      type = types.listOf types.package;
      default = [];
    };
  };
  config = mkIf cfg.enable {
    home.packages = map (name: let
      self = cfg.packages.${name};
    in buildMe self) (attrNames cfg.packages);
  };
}