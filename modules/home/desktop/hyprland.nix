{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.home.desktop.hyprland;
in
{
  options.modulos.home.desktop.hyprland = {
    enable = lib.mkEnableOption "hyprland";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      waybar
      swww
      swaynotificationcenter
      wlogout
      hyprshot
      cliphist
      brightnessctl
      mpvpaper
      xfce.xfce4-appfinder
      nautilus
      pywal16
    ];
  };
}
