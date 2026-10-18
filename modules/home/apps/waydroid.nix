{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.modulos.home.apps.waydroid;

  carpetas = cfg.carpetasCompartidas;
  conCarpetas = carpetas != [ ];

  mkdir = "${pkgs.coreutils}/bin/mkdir -p ${
    lib.concatMapStringsSep " " (c: "'${c.destino}'") carpetas
  }";
in
{
  options.modulos.home.apps.waydroid = {
    enable = lib.mkEnableOption "waydroid-helper (monitor de usuario y carpetas compartidas)";

    carpetasCompartidas = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            origen = lib.mkOption {
              type = lib.types.str;
              description = "Ruta absoluta en el host que se comparte.";
            };
            destino = lib.mkOption {
              type = lib.types.str;
              description = "Ruta absoluta en el host que Android verá como /sdcard/<nombre>.";
            };
          };
        }
      );
      default = [ ];
      description = ''
        Carpetas del host montadas dentro de Android con bindfs vía
        waydroid-helper. El destino debe estar bajo
        ~/.local/share/waydroid/data/media/0/ para verse en /sdcard.
      '';
      example = lib.literalExpression ''
        [
          {
            origen = "/home/usuario/Descargas";
            destino = "/home/usuario/.local/share/waydroid/data/media/0/Descargas";
          }
        ]
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.waydroid-monitor = {
      Unit = {
        Description = "Waydroid Session DBus Monitor";
        After = [ "dbus.service" ];
      };
      Service = {
        ExecStart = "${pkgs.waydroid-helper}/bin/waydroid-helper --start-monitor";
        Restart = "always";
        RestartSec = 5;
      }
      // lib.optionalAttrs conCarpetas {
        ExecStartPre = [ mkdir ];
        Environment = [
          "SOURCE=${lib.concatMapStringsSep ":" (c: c.origen) carpetas}"
          "TARGET=${lib.concatMapStringsSep ":" (c: c.destino) carpetas}"
        ];
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
