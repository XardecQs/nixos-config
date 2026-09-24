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
        dryRun = true;
        # Poner a true al migrar (ver scripts/migrar-home.sh y docs/persistencia.md):
        subvolumen.enable = false;

        allow = {
          top = [
            "Archivo"
            "Descargas"
            "Documentos"
            "Juegos"
            "Media"
            "Proyectos"
            ".cache"
            ".config"
            ".copilot"
            ".cups"
            ".dotnet"
            ".gitconfig"
            ".local"
            ".nix-defexpr"
            ".npm"
            ".ssh"
            ".steam"
            ".themes"
            ".true-mem"
            ".var"
            ".vscode"
            ".vscode-shared"
          ];
          config = [
            "albert"
            "btop"
            "Code"
            "containers"
            "dconf"
            "direnv"
            "environment.d"
            "evolution"
            "fastfetch"
            "fontconfig"
            "gh"
            "git"
            "GitHub Desktop"
            "gnome-initial-setup-done"
            "goa-1.0"
            "gsconnect"
            ".gsd-keyboard.settings-ported"
            "gta-mo"
            "gtk-3.0"
            "gtk-4.0"
            "ibus"
            "kitty"
            "libresprite"
            "librewolf"
            "mimeapps.list"
            "nautilus"
            "nvim"
            "opencode"
            "pulse"
            "retroarch"
            "syncthing"
            "systemd"
            "tmux"
            "user-dirs.conf"
            "user-dirs.dirs"
            "zsh"
          ];
          share = [
            "albert"
            "applications"
            "containers"
            "ElyPrismLauncher"
            "evolution"
            "flatpak"
            "fonts"
            "gnome-settings-daemon"
            "gnome-shell"
            "gta-mo"
            "gvfs-metadata"
            "icc"
            "keyrings"
            "nautilus"
            "nvim"
            "opencode"
            "opentui"
            "org.gnome.TextEditor"
            "pki"
            "recently-used.xbel"
            "SMB1R"
            "sounds"
            "Steam"
            "tracker3"
            "Trash"
            "TwilitRealm"
            "umu"
            "xemu"
            "zinit"
            "zoxide"
          ];
          state = [
            "gwal"
            "home-manager"
            ".keep"
            "lesshst"
            "nix"
            "nix-output-monitor"
            "opencode"
            "syncthing"
            "wireplumber"
            "zsh"
          ];
        };
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
