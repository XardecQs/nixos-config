{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modulos.home.desktop.varios;

  passwordPrompt = pkgs.writeShellApplication {
    name = "varios-password";
    runtimeInputs = [ pkgs.zenity ];
    text = ''
      exec zenity --password --title="Desbloquear Varios"
    '';
  };

  variosOpen = pkgs.writeShellApplication {
    name = "varios-abrir";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gocryptfs
      pkgs.nautilus
      pkgs.util-linux
      pkgs.zenity
    ];
    text = ''
      set -euo pipefail

      MOUNT=${lib.escapeShellArg cfg.mountPoint}
      CIPHER=${lib.escapeShellArg cfg.cipherDir}
      PASSWORD=${lib.escapeShellArg "${passwordPrompt}/bin/varios-password"}

      if mountpoint -q "$MOUNT"; then
        exec nautilus --new-window "$MOUNT"
      fi

      if [ ! -d "$CIPHER" ]; then
        zenity --error \
          --title="Varios" \
          --text="No existe $CIPHER. Créalo primero con Cryptor."
        exit 1
      fi

      mkdir -p "$MOUNT"

      if [ -n "$(ls -A "$MOUNT")" ]; then
        zenity --error \
          --title="Varios" \
          --text="El punto de montaje no está vacío: $MOUNT"
        exit 1
      fi

      if ! gocryptfs -idle ${lib.escapeShellArg cfg.idle} -extpass "$PASSWORD" "$CIPHER" "$MOUNT"; then
        zenity --error \
          --title="Varios" \
          --text="No se pudo abrir Varios."
        exit 1
      fi

      exec nautilus --new-window "$MOUNT"
    '';
  };

  variosClose = pkgs.writeShellApplication {
    name = "varios-cerrar";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.util-linux
      pkgs.zenity
    ];
    text = ''
      set -euo pipefail

      MOUNT=${lib.escapeShellArg cfg.mountPoint}

      if ! mountpoint -q "$MOUNT"; then
        zenity --info --title="Varios" --text="Varios no está abierto."
        exit 0
      fi

      if command -v fusermount3 >/dev/null 2>&1; then
        fusermount3 -u "$MOUNT"
      elif command -v fusermount >/dev/null 2>&1; then
        fusermount -u "$MOUNT"
      else
        zenity --error \
          --title="Varios" \
          --text="No se encontró fusermount3 ni fusermount."
        exit 1
      fi
    '';
  };

  variosStatus = pkgs.writeShellApplication {
    name = "varios-estado";
    runtimeInputs = [ pkgs.util-linux ];
    text = ''
      set -euo pipefail

      MOUNT=${lib.escapeShellArg cfg.mountPoint}

      if mountpoint -q "$MOUNT"; then
        echo "Varios está abierto en $MOUNT"
      else
        echo "Varios está cerrado"
      fi
    '';
  };

  variosExtension = pkgs.writeText "nautilus-varios.py" ''
    import os
    import subprocess

    from gi.repository import GObject, Nautilus

    MOUNT = ${builtins.toJSON cfg.mountPoint}
    MOUNT_URI = "file://" + MOUNT
    OPEN = ${builtins.toJSON "${variosOpen}/bin/varios-abrir"}
    CLOSE = ${builtins.toJSON "${variosClose}/bin/varios-cerrar"}


    class VariosExtension(GObject.GObject, Nautilus.MenuProvider):
        def _is_mounted(self):
            return os.path.ismount(MOUNT)

        def _spawn(self, command):
            subprocess.Popen(
                [command],
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )

        def _item(self, name, label, command):
            item = Nautilus.MenuItem(name=name, label=label)
            item.connect("activate", lambda _item: self._spawn(command))
            return item

        def _menu_item(self, prefix):
            if self._is_mounted():
                return self._item(f"{prefix}::close", "Cerrar", CLOSE)
            return self._item(f"{prefix}::open", "Abrir", OPEN)

        def get_file_items(self, *args):
            files = args[-1]

            if len(files) != 1:
                return []

            if files[0].get_uri().rstrip("/") != MOUNT_URI:
                return []

            return [self._menu_item("NautilusVarios::file")]

        def get_background_items(self, *args):
            current_folder = args[-1]
            uri = current_folder.get_uri().rstrip("/")

            if uri != MOUNT_URI and not uri.startswith(MOUNT_URI + "/"):
                return []

            return [self._menu_item("NautilusVarios::background")]
  '';
in
{
  options.modulos.home.desktop.varios = {
    enable = lib.mkEnableOption "cofre cifrado Varios con gocryptfs";

    cipherDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/Documentos/.varios";
      description = "Directorio donde se guardan los datos cifrados.";
    };

    mountPoint = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/Documentos/Varios";
      description = "Directorio donde se monta el cofre.";
    };

    idle = lib.mkOption {
      type = lib.types.str;
      default = "5m";
      description = ''
        Tiempo de inactividad tras el cual gocryptfs desmonta el cofre.
        Usa el formato de gocryptfs: "5m", "10m", "1h".
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.cryptor
      pkgs.gocryptfs
      pkgs.zenity
      variosOpen
      variosClose
      variosStatus
    ];

    home.file.".local/share/nautilus-python/extensions/varios.py".source = variosExtension;
  };
}
