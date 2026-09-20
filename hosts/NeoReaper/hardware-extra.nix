_:
{
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

  fileSystems."/persist".neededForBoot = true;

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 150;
  };
}
