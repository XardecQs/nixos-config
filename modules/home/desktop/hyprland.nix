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

    gtk = {
      enable = true;
      cursorTheme.name = "macos-tahoe-cursor";
      font.name = "SF Pro Display";
    };

    qt = {
      enable = true;
      platformTheme.name = "adwaita";
      style = {
        name = "Adwaita-dark";
        package = pkgs.adwaita-qt6;
      };
    };
  };
}
