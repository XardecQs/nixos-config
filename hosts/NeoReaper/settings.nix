{
  pkgs,
  ...
}:
{
  hostname = "NeoReaper";
  users = [ "xardec" ];

  # Rutas de host que consumen los módulos de usuario.
  gwal.directorio = "/storage/lab-hdd/Fondos de pantalla";

  # Overrides de home-manager específicos de este host/usuario.
  # homeOverrides.xardec = { };

  modulos = {
    nixos = {
      persistencia = {
        enable = true;
        rollbackRoot = {
          enable = true;
          device = "/dev/mapper/DecryptedSystem";
        };
      };

      homeEstado = {
        enable = true;
        user = "xardec";
        dryRun = false;
        # La allowlist vive en users/xardec/home-allowlist.nix (la inyecta el flake).
      };

      core = {
        boot = {
          enable = true;
          kernelPackage = pkgs.linuxPackages_latest;
        };
        fonts.enable = true;
        general.enable = true;
        locate.enable = true;
        nix.enable = true;
        security.enable = true;
        users = {
          enable = true;
          admin = "xardec";
          adminDescription = "Xavier Del Piero";
        };
      };

      hardware = {
        intel-gpu.enable = true;
        energia.enable = true;
      };

      desktop = {
        display-manager.enable = true;
        pipewire.enable = true;
        steam.enable = true;
        systemPackages.enable = true;
      };

      services = {
        arduino.enable = true;
        keyd = {
          enable = true;
          mouse.enable = true;
        };
        networking.enable = true;
        printing.enable = true;
        sshd.enable = true;
        virtualisation.enable = true;
        # waydroid.enable = true;
      };
    };

    compartidos = {
      gnome.enable = true;
      flatpak.enable = true;
    };
  };
}
