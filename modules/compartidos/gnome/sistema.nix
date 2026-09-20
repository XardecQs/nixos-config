{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.compartidos.gnome;
in
{
  config = lib.mkIf cfg.enable {
    services = {
      desktopManager.gnome.enable = true;
      xserver.xkb.layout = "latam";
    };

    programs.kdeconnect = {
      enable = true;
      package = lib.mkDefault pkgs.gnomeExtensions.gsconnect;
    };
  };
}
