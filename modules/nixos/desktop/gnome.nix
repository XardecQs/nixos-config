{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.nixos.desktop.gnome;
in
{
  options.modulos.nixos.desktop.gnome = {
    enable = lib.mkEnableOption "gnome";
  };

  config = lib.mkIf cfg.enable {
    services = {
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
      xserver.xkb.layout = "latam";
    };
    programs.kdeconnect = {
      enable = true;
      package = pkgs.gnomeExtensions.gsconnect;
    };
  };
}
