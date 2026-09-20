{
  pkgs,
  inputs,
  helpers,
  config,
  ...
}:
{
  networking.hostName = "NeoReaper";

  imports = [
    ./hardware-configuration.nix
    ./../../modules/nixos
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs helpers; };
    sharedModules = [
      ./../../modules/home
      inputs.nix-flatpak.homeManagerModules.nix-flatpak
    ];

    users.xardec = {
      home.stateVersion = config.modulos.nixos.core.general.stateVersion;

      modulos.home = {
        core = {
          dotfiles = {
            enable = true;
            nvim.enable = true;
            kitty.enable = true;
            fastfetch.enable = true;
            tmux.enable = true;
            albert.enable = true;
            code.enable = true;
            xdgUserDirs.enable = true;
          };
          packages.enable = true;
          zsh.enable = true;
        };
        desktop = {
          gwal.enable = true;
          gwal.directorio = "/storage/lab-hdd/Fondos de pantalla";
        };
        apps = {
          syncthing.enable = true;
          retroarch.enable = true;
          gta-mo.enable = true;
        };
      };
    };
  };

  modulos = {
    nixos = {
      persistencia.enable = true;

      core = {
        boot.enable = true;
        boot.kernelPackage = pkgs.linuxPackages_latest;
        fonts.enable = true;
        general.enable = true;
        locate.enable = true;
        nix = {
          enable = true;
          flakePath = "/home/xardec/Proyectos/GitHub/nixos-config";
        };
        security.enable = true;
        users = {
          enable = true;
          primaryUser = "xardec";
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
        networking.enable = true;
        printing.enable = true;
        sshd.enable = true;
        virtualisation.enable = true;
        #waydroid.enable = true;
      };
    };

    compartidos = {
      gnome.enable = true;
      flatpak.enable = true;
    };
  };
}
