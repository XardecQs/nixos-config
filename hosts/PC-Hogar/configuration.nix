{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/nixos
  ];

  networking.hostName = "PC-Hogar";

  modulos = {
    nixos = {
      core = {
        boot.enable = false;
        general.enable = true;
        locate.enable = true;
        nix.enable = true;
        security.enable = true;
        users.enable = true;
      };
      hardware = {
        intel-gpu.enable = true;
        laptop.enable = false;
      };
      desktop = {
        gnome.enable = false;
        sway.enable = false;
        pipewire.enable = true;
        steam.enable = false;
        systemPackages.enable = true;
      };
      services = {
        networking.enable = true;
        servidor.enable = true;
        virtualisation.enable = false;
        waydroid.enable = false;
      };
    };
  };

  #/--------------------/ Boot /--------------------/#

  boot = {
    kernelPackages = pkgs.linuxPackages;
    loader = {
      timeout = 0;
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
        consoleMode = "max";
      };
    };
    kernel.sysctl = {
      "vm.swappiness" = 100;
      "vm.watermark_boost_factor" = 0;
      "vm.watermark_scale_factor" = 125;
    };
    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };
  };
}
