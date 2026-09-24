{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.home.desktop.gwal;

  gwalBin = pkgs.writeShellScriptBin "gwal" ''
    export GWAL_DIRECTORIO='${cfg.directorio}'
    export GWAL_MODO='${cfg.modo}'
    export GWAL_EXTENSIONES='${lib.concatStringsSep " " cfg.extensiones}'
    export GWAL_ESTADO_DIRECTORIO='${cfg.estadoDirectorio}'
    export GWAL_NOTIFICACIONES='${lib.boolToString cfg.notificaciones}'
    exec ${pkgs.bash}/bin/bash ${./gwal.sh} "$@"
  '';
in
{
  options.modulos.home.desktop.gwal = {
    enable = lib.mkEnableOption "gwal: fondo de pantalla aleatorio para GNOME";

    directorio = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/Media/Imágenes/Wallpapers";
      description = "Directorio de imágenes para los fondos de pantalla";
    };

    modo = lib.mkOption {
      type = lib.types.enum [
        "todo"
        "claro"
        "oscuro"
        "auto"
      ];
      default = "auto";
      description = ''
        Modo de selección:
        - "todo": todas las imágenes (recursivo).
        - "claro"/"oscuro": subcarpeta correspondiente + imágenes sueltas de la raíz.
        - "auto": detecta el color-scheme de GNOME y elige claro u oscuro.
      '';
    };

    extensiones = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "jpeg"
        "jpg"
        "png"
        "gif"
        "pnm"
        "tga"
        "tiff"
        "webp"
        "bmp"
        "farbfeld"
      ];
      description = "Extensiones de imagen soportadas";
    };

    estadoDirectorio = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.local/state/gwal";
      description = "Directorio donde gwal guarda la lista de wallpapers ya usados";
    };

    notificaciones = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Muestra notificaciones de progreso (requiere notify-send)";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.zenity
      gwalBin
    ]
    ++ lib.optional cfg.notificaciones pkgs.libnotify;

    dconf.settings = {
      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom10/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom11/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom12/"
        ];
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom10" = {
        name = "Wallpaper aleatorio";
        command = "${gwalBin}/bin/gwal --random";
        binding = "<Super><Shift>w";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom11" = {
        name = "Wallpaper manual";
        command = "${gwalBin}/bin/gwal --pick";
        binding = "<Super><Shift>e";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom12" = {
        name = "Reiniciar historial de wallpapers";
        command = "${gwalBin}/bin/gwal --clear";
        binding = "<Super><Shift>r";
      };
    };
  };
}
