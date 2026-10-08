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

    # Puente para extensiones de Nautilus en Python. Debe estar en system.path
    # porque Nautilus sólo carga lib/nautilus/extensions-4 del sistema; así se
    # activa la integración de GSConnect (nautilus-gsconnect.py).
    environment.systemPackages = with pkgs; [
      nautilus-python
    ];
  };
}
