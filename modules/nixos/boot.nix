{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.modulos.sistema.boot.enable = lib.mkEnableOption "boot";

  config = lib.mkIf config.modulos.sistema.boot.enable {
    boot = {
      kernelPackages = pkgs.linuxPackages_zen;
      plymouth.enable = true;
      loader = {
        timeout = 0;
        systemd-boot = {
          enable = true;
          configurationLimit = 5;
          consoleMode = "max";
        };
        efi.canTouchEfiVariables = true;
      };
      kernel.sysctl = {
        "vm.swappiness" = 100;
        "vm.watermark_boost_factor" = 0;
        "vm.watermark_scale_factor" = 125;
        "kernel.sysrq" = 1;
      };
      kernelModules = [ "ntsync" ];
    };
    services.udev.extraRules = ''
      KERNEL=="ntsync", MODE="0660", TAG+="uaccess"
    '';
  };
}