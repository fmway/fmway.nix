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

  buildMe = { pname, src, name, x11Only, extraPkgs, ... } @ self: let
    appimageContents = pkgs.appimageTools.extract {
      inherit pname name src;
      postExtract = ''
        main="$(basename "$(find $out -maxdepth 1 -name '*.desktop' | head -n 1)" .desktop)"
        execapp="$(cat "''${out}/''${main}.desktop" | grep Exec= | tr '=' ' ' | awk '{print $2}' | head -n 1)"
        [ -e $out/${pname}.desktop ] || mv $out/''${main}.desktop $out/${pname}.desktop
        substituteInPlace $out/${pname}.desktop \
          --replace "Exec=''${execapp}" 'Exec=${pname}'
      '';
    };
  in pkgs.appimageTools.wrapType2 ((if self.meta != {} then { inherit (self) meta; } else {}) // {
    inherit pname name src extraPkgs;
    nativeBuildInputs = lib.optionals x11Only [
      pkgs.makeWrapper
    ];
    extraInstallCommands = ''
      mkdir -p $out/share/icons/hicolor/512x512/apps
      install -m 444 -D ${appimageContents}/${pname}.desktop $out/share/applications/${pname}.desktop
      [ -e ${appimageContents}/usr/share ] &&
        cp -r ${appimageContents}/usr/share $out ||
        cp ${appimageContents}/*.png $out/share/icons/hicolor/512x512/apps/
    '';
    postInstall = lib.optionalString x11Only ''
      wrapProgram $out/bin/${pname} \
        --set GDK_BACKEND x11
    '';
  });

  cfg = config.programs.appimage;
in {
  options.programs.appimage = {
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
          x11Only = mkEnableOption "force run under x11";
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
    environment.systemPackages = map (name: let
      self = cfg.packages.${name};
    in buildMe self) (attrNames cfg.packages);
  };
}
