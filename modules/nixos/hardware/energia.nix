{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.modulos.nixos.hardware.energia;
in
{
  options.modulos.nixos.hardware.energia = {
    enable = lib.mkEnableOption "gestión de energía";
    autoCpufreq = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Activar auto-cpufreq para gestión de frecuencia del CPU";
      };
      gobernadorCargador = lib.mkOption {
        type = lib.types.str;
        default = "performance";
        description = "Gobernador del CPU con cargador conectado";
      };
      gobernadorBateria = lib.mkOption {
        type = lib.types.str;
        default = "powersave";
        description = "Gobernador del CPU con batería";
      };
      turboCargador = lib.mkOption {
        type = lib.types.str;
        default = "auto";
        description = "Turbo boost con cargador conectado (auto/always/never)";
      };
      turboBateria = lib.mkOption {
        type = lib.types.str;
        default = "never";
        description = "Turbo boost con batería (auto/always/never)";
      };
    };
    termald = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Activar thermald para gestión térmica";
      };
    };
    upower = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Activar upower para monitoreo de batería";
      };
    };
    wifiPowersave = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Activar ahorro de energía en WiFi";
    };
    usbAutosuspend = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Desactivar la suspensión automática de USB HID";
    };
    powertop = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Activar los tunings automáticos de powertop";
    };
    descargarWifiSuspend = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Descargar ath10k_pci antes de suspender para evitar cuelgues por enlace PCIe degradado";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      auto-cpufreq = lib.mkIf cfg.autoCpufreq.enable {
        enable = true;
        settings = {
          battery = {
            governor = cfg.autoCpufreq.gobernadorBateria;
            turbo = cfg.autoCpufreq.turboBateria;
          };
          charger = {
            governor = cfg.autoCpufreq.gobernadorCargador;
            turbo = cfg.autoCpufreq.turboCargador;
          };
        };
      };
      thermald.enable = cfg.termald.enable;
      upower.enable = cfg.upower.enable;
      power-profiles-daemon.enable = false;
      udev.extraRules = lib.mkIf cfg.usbAutosuspend ''
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idClass}=="03", ATTR{power/autosuspend}="-1", ATTR{power/control}="on"
      '';
    };

    powerManagement = {
      powertop.enable = cfg.powertop;
      # La QCA9377 (ath10k) cuelga el equipo al suspender por un enlace PCIe
      # degradado. Se descarga el driver antes de dormir y se recarga al despertar.
      powerDownCommands = lib.mkIf cfg.descargarWifiSuspend ''
        ${pkgs.kmod}/bin/modprobe -r ath10k_pci || true
      '';
      resumeCommands = lib.mkIf cfg.descargarWifiSuspend ''
        ${pkgs.kmod}/bin/modprobe ath10k_pci || true
      '';
    };

    networking.networkmanager.wifi.powersave = cfg.wifiPowersave;
  };
}
