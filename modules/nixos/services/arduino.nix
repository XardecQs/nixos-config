{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.modulos.nixos.services.arduino;
in
{
  options.modulos.nixos.services.arduino = {
    enable = lib.mkEnableOption "arduino";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      arduino
      arduino-cli
      usbutils
    ];

    users.users.xardec.extraGroups = [ "dialout" ];

    services.udev.packages = [
      (pkgs.writeTextFile {
        name = "arduino-udev-rules";
        destination = "/etc/udev/rules.d/99-arduino.rules";
        text = ''
          SUBSYSTEM=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", GROUP="dialout", MODE="0660"
          SUBSYSTEM=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7522", GROUP="dialout", MODE="0660"
          SUBSYSTEM=="usb", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="*", GROUP="dialout", MODE="0660"
          SUBSYSTEM=="usb", ATTRS{idVendor}=="2a03", ATTRS{idProduct}=="*", GROUP="dialout", MODE="0660"
        '';
      })
    ];
  };
}
