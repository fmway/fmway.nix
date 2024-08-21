{ config, lib, pkgs, ... }: let
  inherit (builtins)
    map
    listToAttrs
  ;

  inherit (lib)
    mkIf
    mkBefore
  ;

  src = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "bat";
    rev = "d3feec47b16a8e99eabb34cdfbaa115541d374fc";
    hash = "sha256-s0CHTihXlBMCKmbBBb8dUhfgOOQu9PBCQ+uviy7o47w=";
  };

  themes = listToAttrs (map (x: rec {
    name = "Catppuccin ${x}";
    value = {
      inherit src;
      file = "themes/${name}.tmTheme";
    };
  }) [
    "Latte"
    "Frappe"
    "Macchiato"
    "Mocha"
  ]);

  cfg = config.programs.bat;
in {
  options = {};
  config.programs.bat = mkIf cfg.enable {
    themes = mkBefore themes;
  };
}
