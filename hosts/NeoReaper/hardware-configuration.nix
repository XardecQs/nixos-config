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
    device = "/dev/mapper/sda2_crypt";
    fsType = "btrfs";
    options = [
      "subvol=@root"
      "noatime"
      "compress=zstd"
      "autodefrag"
      "space_cache=v2"
    ];
  };

  boot.initrd.luks.devices."sda2_crypt" = {
    device = "/dev/disk/by-uuid/08dd846c-4349-47d6-a992-cf2d8424f2ce";
    preLVM = true;
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/sda2_crypt";
    fsType = "btrfs";
    options = [
      "subvol=@nix"
      "noatime"
      "compress=zstd"
      "autodefrag"
      "space_cache=v2"
    ];
  };

  fileSystems."/persist" = {
    device = "/dev/mapper/sda2_crypt";
    fsType = "btrfs";
    options = [
      "subvol=@persist"
      "noatime"
      "compress=zstd"
      "autodefrag"
      "space_cache=v2"
    ];
    neededForBoot = true;
  };

  fileSystems."/var/log" = {
    device = "/dev/mapper/sda2_crypt";
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
    device = "/dev/disk/by-uuid/90A1-010D";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/1491cd76-ebbd-4e69-83af-08f067d12470"; }
  ];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 150;
  };

  boot.initrd.postDeviceCommands = lib.mkAfter ''
        mkdir /btrfs_tmp
        mount /dev/mapper/sda2_crypt /btrfs_tmp

        timestamp=$(date +%Y-%m-%d_%H-%M-%S)
        mkdir -p /btrfs_tmp/old_roots

        # --- ROOT ---
        if [ -e /btrfs_tmp/@root ]; then
          mv /btrfs_tmp/@root "/btrfs_tmp/old_roots/@root_$timestamp"
        fi

        ls -1 /btrfs_tmp/old_roots | grep "@root_" | sort | head -n -3 | while read -r old_root; do
          echo "Eliminando snapshot de root antiguo: $old_root"
          btrfs subvolume delete -R "/btrfs_tmp/old_roots/$old_root"
        done || true

        btrfs subvolume snapshot /btrfs_tmp/@blank /btrfs_tmp/@root

    find /btrfs_tmp/old_roots -mindepth 1 -type d -empty -delete 2>/dev/null || true

        umount /btrfs_tmp
  '';

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
