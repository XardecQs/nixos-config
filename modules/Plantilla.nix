{
  lib,
  config,
  ...
}:
let
  # Example: cfg = config.modulos.nixos.core.plantilla;
  # Example: cfg = config.modulos.nixos.hardware.plantilla;
  # Example: cfg = config.modulos.nixos.desktop.plantilla;
  # Example: cfg = config.modulos.nixos.services.plantilla;
  # Example: cfg = config.modulos.home.core.plantilla;
  # Example: cfg = config.modulos.home.desktop.plantilla;
  # Example: cfg = config.modulos.home.apps.plantilla;
  cfg = config.modulos.nixos.core.plantilla;
in
{
  options.modulos.nixos.core.plantilla = {
    enable = lib.mkEnableOption "Habilita el módulo plantilla";
  };

  config = lib.mkIf cfg.enable {
  };
}
