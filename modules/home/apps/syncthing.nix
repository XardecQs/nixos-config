{ lib, config, ... }:
let
  cfg = config.modulos.home.apps.syncthing;
in
{
  options.modulos.home.apps.syncthing = {
    enable = lib.mkEnableOption "syncthing";

    deviceName = lib.mkOption {
      type = lib.types.str;
      default = "Dispositivo";
      description = "Nombre del dispositivo remoto en Syncthing.";
    };

    deviceId = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "ID del dispositivo remoto. Vacío desactiva el emparejamiento.";
    };

    folders = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Nombre de la carpeta en Syncthing.";
            };
            path = lib.mkOption {
              type = lib.types.str;
              description = "Ruta absoluta o relativa al home del usuario.";
            };
            id = lib.mkOption {
              type = lib.types.str;
              description = "ID de la carpeta en Syncthing.";
            };
          };
        }
      );
      default = [ ];
      description = "Carpetas compartidas con el dispositivo remoto.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      extraOptions = [ "--allow-newer-config" ];
      settings = {
        options.urAccepted = -1;
        devices = lib.optionalAttrs (cfg.deviceId != "") {
          ${cfg.deviceName} = {
            id = cfg.deviceId;
          };
        };
        folders = lib.listToAttrs (
          map (folder: {
            name = folder.name;
            value = {
              path =
                if lib.hasPrefix "/" folder.path then
                  folder.path
                else
                  "${config.home.homeDirectory}/${folder.path}";
              id = folder.id;
              devices = lib.optional (cfg.deviceId != "") cfg.deviceName;
            };
          }) cfg.folders
        );
      };
    };
  };
}
