{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.modulos.nixos.services.waydroid;

  paquetesDebloat = [
    "com.android.bips"
    "com.android.bookmarkprovider"
    "com.android.calculator2"
    "com.android.cameraextensions"
    "com.android.deskclock"
    "com.android.dreams.basic"
    "com.android.dreams.phototable"
    "com.android.dynsystem"
    "com.android.egg"
    "com.android.emergency"
    "com.android.gallery3d"
    "com.android.htmlviewer"
    "com.android.managedprovisioning"
    "com.android.mms.service"
    "com.android.nfc"
    "com.android.phone"
    "com.android.printspooler"
    "com.android.se"
    "com.android.simappdialog"
    "com.android.systemui.plugin.globalactions.wallet"
    "com.android.wallpaper.livepicker"
    "com.android.wallpaperbackup"
    "com.google.android.apps.googlecamera.fishfood"
    "com.google.android.apps.messaging"
    "com.google.android.apps.restore"
    "com.google.android.contacts"
    "com.google.android.feedback"
    "com.google.android.gms.location.history"
    "com.google.android.googlequicksearchbox"
    "com.google.android.onetimeinitializer"
    "com.google.android.partnersetup"
    "com.google.android.printservice.recommendation"
    "com.google.android.projection.gearhead"
    "com.google.android.syncadapters.calendar"
    "com.google.android.tts"
    "com.stevesoltys.seedvault"
    "org.calyxos.backup.contacts"
    "org.lineageos.aperture"
    "org.lineageos.backgrounds"
    "org.lineageos.eleven"
    "org.lineageos.etar"
    "org.lineageos.jelly"
    "org.lineageos.recorder"
    "org.lineageos.waydroidupdater"
  ];

  debloatScript = pkgs.writeShellApplication {
    name = "waydroid-debloat";
    runtimeInputs = [
      pkgs.coreutils
      cfg.package
    ];
    text = ''
      set -euo pipefail

      paquetes=(
      ${lib.concatMapStringsSep "\n" (p: "  " + lib.escapeShellArg p) cfg.debloat.paquetes}
      )

      mode="disable"
      case "''${1:-}" in
        "" | --disable | disable) mode="disable" ;;
        --restore | restore | enable) mode="enable" ;;
        --list | list) mode="list" ;;
        -h | --help | help)
          echo "Uso: waydroid-debloat [--restore | --list]"
          exit 0
          ;;
        *)
          echo "Opción no reconocida: $1" >&2
          echo "Uso: waydroid-debloat [--restore | --list]" >&2
          exit 2
          ;;
      esac

      if [ "$mode" = "list" ]; then
        printf '%s\n' "''${paquetes[@]}"
        exit 0
      fi

      if [ "$(id -u)" -ne 0 ]; then
        if [ "$mode" = "disable" ]; then
          echo "Se necesita root; ejecuta: sudo waydroid-debloat" >&2
        else
          echo "Se necesita root; ejecuta: sudo waydroid-debloat --restore" >&2
        fi
        exit 1
      fi

      if ! waydroid status >/dev/null 2>&1; then
        echo "Waydroid no está en ejecución; inicia la sesión con 'waydroid session start'." >&2
        exit 1
      fi

      case "$mode" in
        disable) pm=(disable-user --user 0) ;;
        enable) pm=(enable --user 0) ;;
      esac

      fallos=0
      for pkg in "''${paquetes[@]}"; do
        if waydroid shell -- pm "''${pm[@]}" "$pkg" >/dev/null 2>&1; then
          echo "ok   $mode $pkg"
        else
          echo "warn no se pudo $mode $pkg" >&2
          fallos=$((fallos + 1))
        fi
      done

      echo "Hecho: $(( ''${#paquetes[@]} - fallos ))/''${#paquetes[@]} paquetes (fallos: $fallos)"
    '';
  };
in
{
  options.modulos.nixos.services.waydroid = {
    enable = lib.mkEnableOption "waydroid";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.waydroid-nftables;
      description = "Paquete de Waydroid (por defecto la variante nftables).";
    };

    debloat = {
      enable = lib.mkEnableOption "debloat de waydroid (deshabilitar apps GApps/Lineage/AOSP)";

      paquetes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = paquetesDebloat;
        description = ''
          IDs de paquete de Android a deshabilitar con `pm disable-user`.
          Reversible con `waydroid-debloat --restore`.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.waydroid = {
      enable = true;
      package = cfg.package;
    };

    environment.systemPackages = [
      pkgs.waydroid-helper
    ]
    ++ lib.optional cfg.debloat.enable debloatScript;

    # El helper necesita su unidad systemd y su servicio D-Bus para montar
    # carpetas compartidas (bindfs). El monitor de usuario vive en
    # modules/home/apps/waydroid.nix.
    systemd.packages = [ pkgs.waydroid-helper ];
    services.dbus.packages = [ pkgs.waydroid-helper ];
    systemd.services.waydroid-mount.wantedBy = [ "multi-user.target" ];
  };
}
