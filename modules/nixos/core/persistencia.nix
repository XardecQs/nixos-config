{
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.nixos.persistencia;
  user = config.modulos.nixos.core.users.primaryUser;

  sistema = {
    directories = [
      "/etc/NetworkManager/system-connections"
      "/var/db/sudo"
      "/var/lib/AccountsService"
      "/var/lib/bluetooth"
      "/var/lib/containerd"
      "/var/lib/libvirt"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/systemd/timers"
      "/var/lib/waydroid"
    ];
    files = [
      {
        file = "/etc/machine-id";
        inInitrd = true;
      }
      "/var/cache/locatedb"
    ];
  };

  usuario = {
    directories = [
      # Directorios XDG
      "Descargas"
      "Documentos"
      "Juegos"
      "Media"
      "Proyectos"
      "Trastero"
      "Virtualizacion"

      # Core / shell
      ".cache/nix-index"
      ".config/btop"
      ".config/gh"
      ".local/share/Trash"
      ".local/share/applications"
      ".local/share/zinit"
      ".local/share/zoxide"
      ".local/state/zsh"
      ".ssh"

      # Desarrollo
      ".cache/opencode"
      ".config/Code"
      ".config/GitHub Desktop"
      ".config/opencode"
      ".local/share/nvim"
      ".local/share/opencode"
      ".vscode"

      # Escritorio / GNOME
      ".cache/clipboard-indicator@tudmotu.com"
      ".cache/fontconfig"
      ".config/dconf"
      ".config/goa-1.0"
      ".config/gsconnect"
      ".config/gtk-3.0"
      ".config/gtk-4.0"
      ".cups"
      ".local/share/albert"
      ".local/share/fonts"
      ".local/share/gvfs-metadata"
      ".local/share/gnome-shell/extensions"
      ".local/share/keyrings"
      ".local/share/nautilus"
      ".local/state/wireplumber"
      ".themes"

      # Aplicaciones
      ".config/containers"
      ".config/libresprite"
      ".config/librewolf"
      ".config/retroarch"
      ".config/syncthing"
      ".local/share/containers"
      ".local/share/ElyPrismLauncher"
      ".local/share/gta-mo"
      ".local/share/flatpak"
      ".local/share/SMB1R"
      ".local/share/Steam"
      ".local/share/TwilitRealm"
      ".local/share/umu"
      ".local/share/xemu"
      ".local/state/syncthing"
      ".cache/tracker3"
      ".local/share/tracker3"
      ".steam"
      ".var"
    ];
    files = [
      ".config/gta-mo/config.user.toml"
      ".config/mimeapps.list"
      ".gitconfig"
    ];
  };
in
{
  options.modulos.nixos.persistencia = {
    enable = lib.mkEnableOption "persistencia (impermanence)";
  };

  config = lib.mkIf cfg.enable {
    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

    preservation = {
      enable = true;
      preserveAt."/persist" = {
        commonMountOptions = [ "x-gvfs-hide" ];
        directories = sistema.directories;
        files = sistema.files;
        users.${user} = {
          directories = usuario.directories;
          files = usuario.files;
        };
      };
    };
  };
}
