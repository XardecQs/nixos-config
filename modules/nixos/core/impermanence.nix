{ lib, config, ... }:
let
  cfg = config.modulos.nixos.core.impermanence;
in
{
  options.modulos.nixos.core.impermanence = {
    enable = lib.mkEnableOption "impermanence";
  };

  config = lib.mkIf cfg.enable {
    environment.persistence."/persist" = {
      hideMounts = true;
      allowTrash = true;

      directories = [
        "/etc/NetworkManager/system-connections"
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
        directories = [
          "Descargas"
          "Virtualizacion"
          "Documentos"
          "Juegos"
          "Media"
          "Proyectos"
          "Trastero"
          ".cache/clipboard-indicator@tudmotu.com"
          ".cache/nix-index"
          ".config/dconf"
          ".config/gtk-3.0"
          ".local/share/gvfs-metadata"
          ".local/share/keyrings"
          ".local/share/nautilus"
          ".local/share/zinit"
          ".local/share/zoxide"
          ".local/state/zsh"
          ".ssh"
          ".themes"
          ".config/btop"
          ".config/Code"
          ".config/GitHub Desktop"
          ".local/share/albert"
          ".local/share/nvim"
          ".vscode"
          ".local/share/containers"
          ".config/containers"
          ".local/share/applications"
          ".config/gsconnect"
          ".config/librewolf"
          ".local/state/syncthing"
          ".config/libresprite"
          ".config/retroarch"
          ".local/share/SMB1R"
          ".local/share/ElyPrismLauncher"
          ".local/share/flatpak"
          ".local/share/Steam"
          ".steam"
          ".var"
          ".config/opencode"
          ".local/share/opencode"
          ".cache/opencode"
        ];
        files = [
        ];
      };
    };
  };
}
