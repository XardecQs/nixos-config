{
  pkgs,
  inputs,
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
    extraSpecialArgs = { inherit inputs; };

    users.xardec = {
      imports = [
        ./../../modules/home
        inputs.nix-flatpak.homeManagerModules.nix-flatpak
      ];
      home.stateVersion = config.modulos.nixos.core.general.stateVersion;

      modulos.home = {
        core = {
          dotfiles = {
            enable = true;
            nvim.enable = true;
            kitty.enable = true;
            fastfetch.enable = true;
            tmux.enable = true;
            alacritty.enable = true;
            waybar.enable = true;
            wal.enable = true;
            wlogout.enable = true;
            albert.enable = true;
            code.enable = true;
            xdgUserDirs.enable = true;
          };
          packages.enable = true;
          zsh.enable = true;
        };
        desktop = {
          #obs.enable = true;
          rofi.enable = true;
          gwal.enable = true;
          gwal.directorio = "/storage/lab-hdd/Fondos de pantalla";
        };
        apps = {
          syncthing.enable = true;
          #java.enable = true;
          #lan-mouse.enable = true;
          retroarch.enable = true;
          gta-mo.enable = true;
        };
      };
    };
  };

  modulos = {
    persistencia = {
      enable = true;
      sistema.files = [
        "/etc/machine-id"
      ];
      usuarios.xardec.directories = [
        "Virtualizacion"
        "Descargas"
        "Documentos"
        "Juegos"
        "Media"
        "Proyectos"
        "Trastero"
        ".config/rofi"
        ".local/share/rofi"
        ".local/state/syncthing"
        ".config/retroarch"
        ".local/share/xemu"
        ".cache/tracker3"
        ".local/share/tracker3"
        ".local/state/wireplumber"
        ".config/gtk-4.0"
        ".local/share/gnome-shell/extensions"
        ".cache/fontconfig"
        ".local/share/fonts"
        ".config/syncthing"
        ".config/goa-1.0"
        ".cups"
        #".local/share/backgrounds"
      ];
      usuarios.xardec.files = [
        ".gitconfig"
        ".config/mimeapps.list"
      ];
    };

    nixos = {
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
