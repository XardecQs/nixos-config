{ ... }:
{
  networking.hostName = "NeoReaper";

  imports = [
    ./hardware-configuration.nix
    ./../../modules/nixos
  ];

  modulos = {
    nixos = {
      core = {
        boot.enable = true;
        fonts.enable = true;
        general.enable = true;
        impermanence.enable = true;
        locate.enable = true;
        nix.enable = true;
        security.enable = true;
        users.enable = true;
      };
      hardware = {
        intel-gpu.enable = true;
        laptop.enable = true;
      };
      desktop = {
        gnome.enable = true;
        sway.enable = false;
        #kmscon.enable = true;
        pipewire.enable = true;
        steam.enable = true;
        systemPackages.enable = true;
      };
      services = {
        arduino.enable = true;
        flatpak.enable = true;
        networking.enable = true;
        printing.enable = true;
        sshd.enable = true;
        virtualisation.enable = true;
        #waydroid.enable = true;
      };
    };
  };
}
