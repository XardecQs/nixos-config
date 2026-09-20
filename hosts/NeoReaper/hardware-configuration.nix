{
  config,
  lib,
  modulesPath,
  pkgs,
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
    neededForBoot = true;
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

  fileSystems."/storage/lab-hdd" = {
    device = "/dev/disk/by-uuid/20d10255-4d85-44d7-add6-5beeee5b9b61";
    fsType = "ext4";
    options = [
      "defaults"
      "nofail"
      "noatime"
      "errors=remount-ro"
      "x-systemd.automount"
      "x-systemd.idle-timeout=10min"
      "x-systemd.device-timeout=5s"
    ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/1c57e7d2-0869-447c-8d2f-3f6f5fc1139a"; }
  ];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 150;
  };

  boot.initrd.systemd = {
    enable = true;

    services.rollback-root = {
      description = "Rollback BTRFS root subvolume (Impermanence)";

      unitConfig.DefaultDependencies = false;

      serviceConfig = {
        Type = "oneshot";
        # StandardOutput = "journal+console";  # Descomenta para debug
        # StandardError = "journal+console";
      };

      requiredBy = [ "initrd.target" ];
      before = [
        "sysroot.mount"
        "initrd-root-fs.target"
      ];

      requires = [ "initrd-root-device.target" ];
      after = [
        "initrd-root-device.target"
        "cryptsetup.target"
        "local-fs-pre.target"
      ];

      script = ''
        mkdir -p /btrfs_tmp
        mount /dev/mapper/DecryptedSystem /btrfs_tmp

        timestamp=$(date +%Y-%m-%d_%H-%M-%S)
        mkdir -p /btrfs_tmp/old_roots

        # --- ROOT ---
        if [ -e /btrfs_tmp/@root ]; then
          echo "Moviendo @root antiguo a old_roots"
          mv /btrfs_tmp/@root "/btrfs_tmp/old_roots/@root_$timestamp"
        fi

        # Mantener solo las últimas 3 snapshots
        ls -1 /btrfs_tmp/old_roots | grep "@root_" | sort | head -n -3 | while read -r old_root; do
          echo "Eliminando snapshot antiguo: $old_root"
          btrfs subvolume delete -R "/btrfs_tmp/old_roots/$old_root" || true
        done

        # Crear nuevo @root desde @blank
        echo "Creando nuevo @root desde @blank"
        btrfs subvolume snapshot /btrfs_tmp/@blank /btrfs_tmp/@root

        find /btrfs_tmp/old_roots -mindepth 1 -type d -empty -delete 2>/dev/null || true

        umount /btrfs_tmp
      '';
    };

    # Hacer disponibles los binarios necesarios en el initrd
    extraBin = {
      "btrfs" = "${pkgs.btrfs-progs}/bin/btrfs";
      "date" = "${pkgs.coreutils}/bin/date";
      "mv" = "${pkgs.coreutils}/bin/mv";
      "ls" = "${pkgs.coreutils}/bin/ls";
      "find" = "${pkgs.findutils}/bin/find";
      "mkdir" = "${pkgs.coreutils}/bin/mkdir";
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
