{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.home.desktop.obs;
in
{
  options.modulos.home.desktop.obs = {
    enable = lib.mkEnableOption "obs";
  };

  config = lib.mkIf cfg.enable {
    programs.obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-pipewire-audio-capture
        droidcam-obs
      ];
    };
  };
}
