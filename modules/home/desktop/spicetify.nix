{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.home.desktop.spicetify;
  spicetify-nix = inputs.spicetify-nix;
  spicePkgs = spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  options.modulos.home.desktop.spicetify = {
    enable = lib.mkEnableOption "spicetify";
  };

  config = lib.mkIf cfg.enable {
    programs.spicetify = {
      enable = true;
      alwaysEnableDevTools = true;
      enabledExtensions = with spicePkgs.extensions; [
        adblock
        fullAppDisplay
        beautifulLyrics
        shuffle
      ];
      enabledCustomApps = with spicePkgs.apps; [
        lyricsPlus
        marketplace
        betterLibrary
      ];
    };
  };
}
