{ pkgs, ... }:
{
  networking.hostName = "NeoReaper";

  imports = [
    ./hardware-configuration.nix
    ./../../modules/nixos
  ];

  modulos = {
    sistema = {
      escritorio = {
        gnome.enable = true;
        sway.enable = false;
      };
      boot.enable = true;
      general.enable = true;
      intel-gpu.enable = true;
      laptop.enable = true;
      locate.enable = true;
      networking.enable = true;
      nix.enable = true;
      steam.enable = true;
      systemPackages.enable = true;
      users.enable = true;
      #virtualisation.enable = true;
      #waydroid.enable = true;
      pipewire.enable = true;
      security.enable = true;
    };
  };

  #/--------------------/ Servicios principales /--------------------/#
  services = {
    flatpak.enable = true;
    sshd.enable = true;

    xserver = {
      enable = true;
      xkb.layout = "latam";
      videoDrivers = [ "intel" ];
    };

    printing = {
      enable = true;
      drivers = [
        pkgs.epson-escpr2
        pkgs.epson-escpr
      ];
    };
  };
  hardware.sane = {
    enable = true;
    extraBackends = [
      (pkgs.epsonscan2.override { withNonFreePlugins = true; })
    ];
  };

  users.users."xardec" = {
    extraGroups = [
      "scanner"
      "lp"
    ];
  };

  environment.persistence."/persist" = {
    hideMounts = true;
    allowTrash = true;
    # --- Configuración y Estado del Sistema ---
    directories = [
      "/etc/NetworkManager/system-connections"
      "/etc/nixos"
      "/var/db/sudo"
      "/var/lib/AccountsService"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/systemd/timers"
    ];
    files = [
      "/etc/machine-id"
      "/var/cache/locatedb"
    ];
    users.xardec = {
      # --- Directorios del Usuario ---
      directories = [
        # Datos Personales y Proyectos
        "Descargas"
        "Documentos"
        "Juegos"
        "Media"
        "Proyectos"
        "Trastero"
        ".dotfiles"
        # Configuración de Entorno y Shell
        ".cache/clipboard-indicator@tudmotu.com"
        ".cache/nix-index"
        ".config/dconf"
        ".config/gtk-3.0"
        ".local/share/fonts"
        ".local/share/gvfs-metadata"
        ".local/share/keyrings"
        ".local/share/nautilus"
        ".local/share/zinit"
        ".local/share/zoxide"
        ".local/state/zsh"
        ".ssh"
        ".themes"
        # Aplicaciones de Trabajo y Herramientas
        ".config/btop"
        ".config/Code"
        ".config/GitHub Desktop"
        ".local/share/albert"
        ".local/share/nvim"
        ".vscode"
        # Navegadores y Comunicación
        ".config/gsconnect"
        ".config/librewolf"
        ".local/state/syncthing"
        # Multimedia y Diseño
        ".config/libresprite"
        ".config/retroarch"
        ".local/share/SMB1R"
        # Juegos y Runtimes
        ".local/share/ElyPrismLauncher"
        ".local/share/flatpak"
        ".local/share/Steam"
        ".steam"
        ".var"
      ];
      files = [
        ".config/background"
        ".config/mimeapps.list"
      ];
    };
  };
}
