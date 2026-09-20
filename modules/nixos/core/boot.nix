{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.nixos.core.boot;
in
{
  options.modulos.nixos.core.boot = {
    enable = lib.mkEnableOption "boot";
    kernelPackage = lib.mkOption {
      default = pkgs.linuxPackages_zen;
      description = "Paquete del kernel de Linux";
    };
    plymouth.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Pantalla de arranque gráfica (Plymouth)";
    };
    efiSysMountPoint = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Punto de montaje de la partición EFI (null = por defecto /boot)";
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      kernelPackages = cfg.kernelPackage;
      plymouth.enable = cfg.plymouth.enable;
      loader = {
        timeout = 0;
        systemd-boot = {
          enable = true;
          configurationLimit = 5;
          consoleMode = "max";
        };
        efi = {
          canTouchEfiVariables = true;
        }
        // lib.optionalAttrs (cfg.efiSysMountPoint != null) {
          inherit (cfg) efiSysMountPoint;
        };
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
