{
  lib,
  config,
  pkgs,
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

    rollbackRoot = {
      enable = lib.mkEnableOption "rollback de @root al arrancar (impermanence)";
      device = lib.mkOption {
        type = lib.types.str;
        description = "Dispositivo btrfs con los subvolúmenes @blank/@root/old_roots";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

    preservation = {
      enable = true;
      preserveAt."/persist" = {
        commonMountOptions = [ "x-gvfs-hide" ];
        inherit (sistema) directories files;
        users.${user} = {
          inherit (usuario) directories files;
        };
      };
    };

    boot.initrd.systemd = lib.mkIf cfg.rollbackRoot.enable {
      enable = true;

      services.rollback-root = {
        description = "Rollback BTRFS root subvolume (Impermanence)";

        unitConfig.DefaultDependencies = false;

        serviceConfig = {
          Type = "oneshot";
          # StandardOutput = "journal+console";  # Descomenta para debug
          # StandardError = "journal+console";
        };

        requiredBy = [ "initrd.target" ];
        before = [
          "sysroot.mount"
          "initrd-root-fs.target"
        ];

        requires = [ "initrd-root-device.target" ];
        after = [
          "initrd-root-device.target"
          "cryptsetup.target"
          "local-fs-pre.target"
        ];

        script = ''
          mkdir -p /btrfs_tmp
          mount ${cfg.rollbackRoot.device} /btrfs_tmp

          timestamp=$(date +%Y-%m-%d_%H-%M-%S)
          mkdir -p /btrfs_tmp/old_roots

          # --- ROOT ---
          if [ -e /btrfs_tmp/@root ]; then
            echo "Moviendo @root antiguo a old_roots"
            mv /btrfs_tmp/@root "/btrfs_tmp/old_roots/@root_$timestamp"
          fi

          # Mantener solo las últimas 3 snapshots
          ls -1 /btrfs_tmp/old_roots | grep "@root_" | sort | head -n -3 | while read -r old_root; do
            echo "Eliminando snapshot antiguo: $old_root"
            btrfs subvolume delete -R "/btrfs_tmp/old_roots/$old_root" || true
          done

          # Crear nuevo @root desde @blank
          echo "Creando nuevo @root desde @blank"
          btrfs subvolume snapshot /btrfs_tmp/@blank /btrfs_tmp/@root

          find /btrfs_tmp/old_roots -mindepth 1 -type d -empty -delete 2>/dev/null || true

          umount /btrfs_tmp
        '';
      };

      # Hacer disponibles los binarios necesarios en el initrd
      extraBin = {
        "btrfs" = "${pkgs.btrfs-progs}/bin/btrfs";
        "date" = "${pkgs.coreutils}/bin/date";
        "mv" = "${pkgs.coreutils}/bin/mv";
        "ls" = "${pkgs.coreutils}/bin/ls";
        "find" = "${pkgs.findutils}/bin/find";
        "mkdir" = "${pkgs.coreutils}/bin/mkdir";
      };
    };
  };
}
