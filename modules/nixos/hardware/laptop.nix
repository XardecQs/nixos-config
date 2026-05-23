{ lib, config, ... }:
let
  cfg = config.modulos.nixos.hardware.laptop;
in
{
  options.modulos.nixos.hardware.laptop = {
    enable = lib.mkEnableOption "laptop";
  };

  config = lib.mkIf cfg.enable {
    services = {
      auto-cpufreq = {
        enable = true;
        settings = {
          battery = {
            governor = "powersave";
            turbo = "never";
          };
          charger = {
            governor = "performance";
            turbo = "auto";
          };
        };
      };

      tlp = {
        enable = true;
        settings = {
          CPU_SCALING_GOVERNOR_ON_AC = "";
          CPU_SCALING_GOVERNOR_ON_BAT = "";
          CPU_ENERGY_PERF_POLICY_ON_AC = "";
          CPU_ENERGY_PERF_POLICY_ON_BAT = "";
          CPU_BOOST_ON_AC = "";
          CPU_BOOST_ON_BAT = "";

          USB_AUTOSUSPEND = 1;
          WIFI_PWR_ON_AC = "off";
          WIFI_PWR_ON_BAT = "on";
          INTEL_GPU_MIN_FREQ_ON_BAT = 300;
        };
      };

      power-profiles-daemon.enable = false;
      thermald.enable = true;
      upower.enable = true;
    };
  };
}
