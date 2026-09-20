{ lib, config, ... }:
let
  cfg = config.modulos.nixos.core.general;
in
{
  options.modulos.nixos.core.general = {
    enable = lib.mkEnableOption "general";
    stateVersion = lib.mkOption {
      type = lib.types.str;
      default = "26.05";
      description = "stateVersion del sistema (fuente única para NixOS y home-manager)";
    };
  };

  config = lib.mkIf cfg.enable {
    system.stateVersion = cfg.stateVersion;
    time.timeZone = "America/Lima";
    i18n.defaultLocale = "es_PE.UTF-8";
    console.keyMap = "la-latin1";
  };
}
