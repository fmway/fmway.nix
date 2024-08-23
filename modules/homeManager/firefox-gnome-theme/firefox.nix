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
    foldl'
  ;

  github = pkgs.fetchFromGitHub {
    owner = "rafaelmardojai";
    repo = "firefox-gnome-theme";
    rev = "v129";
    hash = "sha256-MOE9NeU2i6Ws1GhGmppMnjOHkNLl2MQMJmGhaMzdoJM=";
  };

  cfg = config.programs.firefox;

  chromes = profile: let
    enable = cfg.profiles.${profile}.gnome-theme;
    base = ".mozilla/firefox/${profile}/chrome";
  in {
    "${base}/userChrome.css" = mkIf enable {
      text = mkBefore ''
        @import "firefox-gnome-theme/userChrome.css";
      '';
    };
    "${base}/userContent.css" = mkIf enable {
      text = mkBefore ''
        @import "firefox-gnome-theme/userContent.css";
      '';
    };
    "${base}/firefox-gnome-theme" = mkIf enable {
      source = github;
    };
    "${base}/user.js" = mkIf enable {
      text = mkBefore (fileContents "${github}/configuration/user.js");
    };
    };
in {
  options.programs.firefox.profiles = mkOption {
    type = types.attrsOf (types.submodule {
      options = {
        gnome-theme = mkEnableOption "enable gnome-theme";
      };
    });
  };
  config = mkIf cfg.enable {
    home.file = foldl' (acc: curr: acc // (chromes curr)) {} (attrNames cfg.profiles);
  };
}
