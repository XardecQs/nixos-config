{
  pkgs,
  ...
}:
{
  # El BIOS de la X542UA deja el micrófono interno (pin 0x13) como N/A, así que
  # el ADC termina leyendo un pin flotante y OBS solo captura ruido blanco.
  # Se aplica el mismo pin config que ALC294_FIXUP_ASUS_MIC del kernel.
  hardware.firmware = [
    (pkgs.writeTextDir "lib/firmware/alc294-x542ua.fw" ''
      [codec]
      0x10ec0294 0x10431a00 0

      [pincfg]
      0x13 0x40000000
      0x1b 0x90a70130
      0x19 0x04a11120
    '')
  ];

  boot.extraModprobeConfig = ''
    options snd-hda-intel patch=alc294-x542ua.fw
  '';

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
