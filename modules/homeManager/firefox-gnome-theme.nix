{ config, lib, pkgs, ... }: let

  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkIf
    mkBefore
    fileContents
  ;

  inherit (builtins)
    attrNames
  ;

  github = pkgs.fetchFromGitHub {
    owner = "rafaelmardojai";
    repo = "firefox-gnome-theme";
    rev = "v129";
    hash = "sha256-MOE9NeU2i6Ws1GhGmppMnjOHkNLl2MQMJmGhaMzdoJM=";
  };
  
  baseBrowsers = {
    firefox = ".mozilla/firefox";
    floorp = ".floorp";
    thunderbird = ".thunderbird";
  };
in {
  imports = map (browser: let
    cfg = config.programs.${browser};
  in {
    options.programs.${browser}.profiles = mkOption {
      type = types.attrsOf (types.submodule ({ config, ... }: {
        options = {
          gnome-theme = mkEnableOption "enable gnome-theme";
        };
        config = mkIf config.gnome-theme {
          userChrome = mkBefore ''@import "firefox-gnome-theme/userChrome.css'';
          userContent = mkBefore ''@import "firefox-gnome-theme/userContent.css'';
          extraConfig = mkBefore (fileContents "${github}/configuration/user.js");
        };
      }));
      config = mkIf cfg.enable {
        home.file = lib.listToAttrs (map (profile: {
          name = "${baseBrowsers.${browser}}/chrome/firefox-gnome-theme";
          value = mkIf cfg.profiles.${profile}.gnome-theme {
            source = github;
          };
        }) (attrNames cfg.profiles));
      };
    };
  }) (builtins.attrNames baseBrowsers);
}
