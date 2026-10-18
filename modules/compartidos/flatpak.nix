{ lib, config, ... }:
let
  cfg = config.modulos.compartidos.flatpak;
in
{
  options.modulos.compartidos.flatpak = {
    enable = lib.mkEnableOption "flatpak";
    sistema = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Activar servicio Flatpak del sistema";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.sistema) {
    services.flatpak.enable = true;
  };
}
