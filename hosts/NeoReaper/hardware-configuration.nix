# Base de hardware/almacenamiento (estilo nixos-generate-config).
# Lo generado por el sistema va aquí; los añadidos manuales, en hardware-extra.nix.
# Excepción: los montajes de almacenamiento base (incluido /home -> @home) se
# mantienen aquí para tenerlos todos juntos.
{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ "i915" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/mapper/DecryptedSystem";
    fsType = "btrfs";
    options = [
      "subvol=@root"
      "noatime"
      "compress=zstd"
      "autodefrag"
      "space_cache=v2"
    ];
  };

  boot.initrd.luks.devices."DecryptedSystem" = {
    device = "/dev/disk/by-uuid/16026e48-592c-4490-ae4f-4ec4b112ec78";
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/DecryptedSystem";
    fsType = "btrfs";
    options = [
      "subvol=@nix"
      "noatime"
      "compress=zstd"
      "autodefrag"
      "space_cache=v2"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/mapper/DecryptedSystem";
    fsType = "btrfs";
    options = [
      "subvol=@home"
      "noatime"
      "compress=zstd"
      "space_cache=v2"
    ];
    neededForBoot = true; # agenix: ~/.ssh/agenix
  };

  fileSystems."/persist" = {
    device = "/dev/mapper/DecryptedSystem";
    fsType = "btrfs";
    options = [
      "subvol=@persist"
      "noatime"
      "compress=zstd"
      "autodefrag"
      "space_cache=v2"
    ];
  };

  fileSystems."/var/log" = {
    device = "/dev/mapper/DecryptedSystem";
    fsType = "btrfs";
    options = [
      "subvol=@log"
      "noatime"
      "compress=zstd"
      "autodefrag"
      "space_cache=v2"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/3738-0F14";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/1c57e7d2-0869-447c-8d2f-3f6f5fc1139a"; }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
