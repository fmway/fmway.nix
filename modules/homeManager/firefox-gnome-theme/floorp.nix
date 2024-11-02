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

  cfg = config.programs.floorp;

  chromes = profile: let
    enable = cfg.profiles.${profile}.gnome-theme;
    base = ".floorp/${profile}";
  in {
    "${base}/chrome/userChrome.css" = mkIf enable {
      text = mkBefore ''
        @import "firefox-gnome-theme/userChrome.css";
      '';
    };
    "${base}/chrome/userContent.css" = mkIf enable {
      text = mkBefore ''
        @import "firefox-gnome-theme/userContent.css";
      '';
    };
    "${base}/chrome/firefox-gnome-theme" = mkIf enable {
      source = github;
    };
    "${base}/user.js" = mkIf enable {
      text = mkBefore (fileContents "${github}/configuration/user.js");
    };
    };
in {
  options.programs.floorp.profiles = mkOption {
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
