{ lib, config, ... }:
let
  cfg = config.modulos.home.apps.syncthing;
in
{
  options.modulos.home.apps.syncthing = {
    enable = lib.mkEnableOption "syncthing";
  };

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      extraOptions = [ "--allow-newer-config" ];
      settings = {
        options.urAccepted = -1;
        devices = {
          "Redmi Note 10 Pro" = {
            id = "CKKQFLP-DHF2EVH-DTYRSR3-JE4EPTH-CZF2P6S-56VFBL5-55E4GYA-EF7CWQJ";
          };
        };
        folders = {
          "Kotatsu" = {
            path = "${config.home.homeDirectory}/Media/Mangas/.Kotatsu";
            id = "tovx9-9995f";
            devices = [ "Redmi Note 10 Pro" ];
          };
          "Música" = {
            path = "${config.home.homeDirectory}/Media/Música";
            id = "w9yjz-9kb76";
            devices = [ "Redmi Note 10 Pro" ];
          };
          "Capturas de pantalla" = {
            path = "${config.home.homeDirectory}/Media/Imágenes/Capturas de pantalla";
            id = "7979p-4pjv5";
            devices = [ "Redmi Note 10 Pro" ];
          };
          "ROMs" = {
            path = "${config.home.homeDirectory}/Juegos/ROMs";
            id = "qlb1e-69yh0";
            devices = [ "Redmi Note 10 Pro" ];
          };
        };
      };
    };
  };
}
