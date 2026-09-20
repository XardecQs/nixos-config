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
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.zenity
      gwalBin
    ];

    dconf.settings = {
      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom10/"
        ];
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom10" = {
        name = "Wallpaper aleatorio";
        command = "${gwalBin}/bin/gwal --random";
        binding = "<Super><Shift>w";
      };
    };
  };
}
