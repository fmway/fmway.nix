{ config, lib, pkgs, ... }: let

  inherit (builtins)
    isNull
    attrNames
    concatStringsSep
    map
  ;

  buildMe = { pname, src, name, icon, extraPkgs , x11Only, isElectron, env, ... } @ self: let
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
    
    extraInstallCommands = let
      genEnv = concatStringsSep " " (
        map (k: let
          v = lib.strings.toJSON env.${k};
        in "--set ${k} ${v}") (attrNames env)
      );
      wrapOzone = ''
        wrapProgram $out/bin/${pname} ${genEnv} \
          --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"
        '';
      wrapOnlyX11 = ''
        wrapProgram $out/bin/${pname} ${genEnv} \
          --set GDK_BACKEND x11
      '';
    in ''
      source "${pkgs.makeWrapper}/nix-support/setup-hook"
      ${lib.optionalString x11Only wrapOnlyX11}
      ${lib.optionalString (!x11Only && isElectron) wrapOzone}
      mkdir -p $out/share/icons/hicolor/512x512/apps
      install -m 444 -D ${appimageContents}/${pname}.desktop $out/share/applications/${pname}.desktop
      [ -e ${appimageContents}/usr/share ] &&
        cp -rf ${appimageContents}/usr/share $out ||
        cp -f ${appimageContents}/*.png $out/share/icons/hicolor/512x512/apps/
      ${lib.optionalString (!isNull icon) "cp -f ${icon} $out/share/icons/hicolor/512x512/apps/${pname}.png"}
    '';
  });

  cfg = config.programs.appimage;
in with lib; {
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
            default = self.pname + (optionalString (!isNull self.version) "-${self.version}");
          };
          icon = mkOption {
            type = with types; nullOr pathInStore;
            default = null;
          };
          src = mkOption {
            type = with types; oneOf [ package path ];
          };
          x11Only = mkEnableOption "only x11";
          isElectron = mkEnableOption "to add ozone features";
          env = mkOption {
            type = with types; attrsOf (nullOr (oneOf [ str int bool ]));
            default = {};
          };
          extraPkgs = mkOption {
            type = with types; functionTo (listOf package);
            default = pkgs: [];
          };
          meta = mkOption {
            type = types.attrs;
            default = {};
          };
          result = mkOption {
            type = types.package;
            default = buildMe self;
            readOnly = true;
          };
        };
      }));
      default = {};
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = map (name: let
      self = cfg.packages.${name};
    in self.result) (attrNames cfg.packages);
  };
}
