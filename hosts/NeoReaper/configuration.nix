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
      arduino.enable = true;
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
      virtualisation.enable = true;
      #waydroid.enable = true;
      pipewire.enable = true;
      security.enable = true;
    };
  };

  #/--------------------/ Servicios principales /--------------------/#

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  services.kmscon = {
    enable = true;
    hwRender = true;

    fonts = [
      {
        name = "JetBrainsMono Nerd Font Mono";
        package = pkgs.nerd-fonts.jetbrains-mono;
      }
    ];

    extraConfig = ''
      font-engine=pango
      font-name=JetBrainsMono Nerd Font Mono
      font-size=11
      xkb-layout=latam

      palette=custom

      palette-black=12,12,12
      palette-red=220,60,60
      palette-green=80,220,100
      palette-yellow=230,190,70
      palette-blue=100,160,255
      palette-magenta=200,80,200
      palette-cyan=80,200,190
      palette-light-grey=180,180,180
      
      palette-dark-grey=90,90,90
      palette-light-red=255,85,85
      palette-light-green=100,255,130
      palette-light-yellow=255,235,120
      palette-light-blue=135,190,255
      palette-light-magenta=240,120,240
      palette-light-cyan=100,255,230
      palette-white=245,245,245
      
      palette-foreground=220,220,215
      palette-background=8,8,8
    '';
  };

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
      "/var/lib/libvirt"
      "/var/lib/virt-manager"
      "/var/lib/waydroid"
      "/var/lib/docker"
      "/var/lib/containerd"
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
        "Virtualizacion"
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
        ".local/share/containers"
        ".config/containers"
        ".local/share/applications"
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
        ".config/mimeapps.list"
      ];
    };
  };
}
