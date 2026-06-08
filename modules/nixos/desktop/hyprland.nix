{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.nixos.desktop.hyprland;
in
{
  options.modulos.nixos.desktop.hyprland = {
    enable = lib.mkEnableOption "hyprland";
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland.enable = true;

    services.displayManager.ly.enable = !config.modulos.nixos.desktop.gnome.enable;

    services.xserver.xkb.layout = "latam";

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    };

    environment.systemPackages = with pkgs; [
      nwg-displays
      blueman
      networkmanagerapplet
    ];
  };
}
