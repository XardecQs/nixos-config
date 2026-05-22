{ lib, config, pkgs, ... }:

let
  category = "sistema"; # [ sistema | home-manager ]
  moduleName = "arduino";
in
{
  options.modulos.${category}.${moduleName}.enable = lib.mkEnableOption moduleName;

  config = lib.mkIf config.modulos.${category}.${moduleName}.enable {
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
          # Arduino CH340 / CH341
          SUBSYSTEM=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", GROUP="dialout", MODE="0660"
          # Otros clones comunes
          SUBSYSTEM=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7522", GROUP="dialout", MODE="0660"
          # Arduino genuinos y otros
          SUBSYSTEM=="usb", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="*", GROUP="dialout", MODE="0660"
          SUBSYSTEM=="usb", ATTRS{idVendor}=="2a03", ATTRS{idProduct}=="*", GROUP="dialout", MODE="0660"
        '';
      })
    ];
  };
}
