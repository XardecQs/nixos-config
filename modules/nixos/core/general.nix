{ lib, config, ... }:
let
  cfg = config.modulos.nixos.core.general;
in
{
  options.modulos.nixos.core.general = {
    enable = lib.mkEnableOption "general";
  };

  config = lib.mkIf cfg.enable {
    system.stateVersion = "25.11";
    time.timeZone = "America/Lima";
    i18n.defaultLocale = "es_PE.UTF-8";
    console.keyMap = "la-latin1";

    environment.persistence."/persist" = lib.mkIf config.modulos.nixos.core.impermanence.enable {
      directories = [
        "/var/lib/systemd/coredump"
        "/var/lib/systemd/timers"
      ];
    };
  };
}
