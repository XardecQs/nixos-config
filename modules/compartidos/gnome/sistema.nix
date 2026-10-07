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

    # El loader gdk-pixbuf de libavif 1.4.1 tiene una firma con la máscara mal:
    # "zzz         " exige que el 4º byte del tamaño del box `ftyp` sea 0x20, así
    # que sólo reconoce AVIF de 32 bytes. Muchos codificadores (libheif, etc.)
    # escriben 3 compatible brands (ftyp de 28 bytes) y no se reconocen. Con
    # "xxxx        " el tamaño del box pasa a ser comodín y se aceptan todos.
    nixpkgs.overlays = [
      (final: prev: {
        libavif = prev.libavif.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            substituteInPlace contrib/gdk-pixbuf/loader.c \
              --replace-fail '"zzz         "' '"xxxx        "'
          '';
        });
      })
    ];

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
