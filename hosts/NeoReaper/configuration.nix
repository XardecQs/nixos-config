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
        users = {
          enable = true;
          primaryUser = "xardec";
          primaryUserPassword = "$6$6kcVeTMDK6yE6XdY$cgvhSqLBhNShREDb.cdNYV0iJS3GpqM.HTjcJKFt864nsnOviqoL6tZah/oamGZe3REqS8q1MQPcxq/76jYTW.";
        };
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
        #hyprland.enable = true;
      };
      services = {
        arduino.enable = true;
        flatpak.enable = true;
        networking.enable = true;
        printing.enable = true;
        sshd.enable = true;
        virtualisation.enable = true;
        #windows-vm.enable = true;
        #waydroid.enable = true;
      };
    };
  };
}
