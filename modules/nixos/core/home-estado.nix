{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modulos.nixos.homeEstado;

  quarantinePath = "${cfg.home}/${cfg.quarantine}";

  mkAllowArray = name: values: "${name}=( ${lib.concatMapStringsSep " " lib.escapeShellArg values} )";

  commonLib = ''
    in_allow() {
      local needle="$1"; shift
      local x
      for x in "$@"; do
        [[ "$x" == "$needle" ]] && return 0
      done
      return 1
    }

    enforce_dir() {
      local base="$1"; shift
      [[ -d "$base" ]] || return 0
      local entry name rel
      while IFS= read -r -d "" entry; do
        name="$(basename "$entry")"
        [[ "$name" == "." || "$name" == ".." ]] && continue
        # Los symlinks los gestiona home-manager: no se tocan.
        [[ -L "$entry" ]] && continue
        # No cuarentenar la propia cuarentena.
        [[ "$entry" == "$QUARANTINE" || "$entry" == "$QUARANTINE"/* ]] && continue
        # No mover puntos de montaje.
        mountpoint -q "$entry" && continue
        in_allow "$name" "$@" && continue
        rel="''${entry#"$HOME_DIR"/}"
        if [[ "$DRY" == "true" ]]; then
          printf '[dry-run] cuarentenaria: %s\n' "$rel"
        else
          mkdir -p "$QUARANTINE/$STAMP/$(dirname "$rel")"
          mv -- "$entry" "$QUARANTINE/$STAMP/$rel"
          # La cuarentena la crea root: cederla al usuario para que `home-promote`
          # pueda restaurar sin sudo.
          chown -R ${cfg.user} "$QUARANTINE" 2>/dev/null || true
          printf 'cuarentenado: %s\n' "$rel"
        fi
      done < <(find "$base" -mindepth 1 -maxdepth 1 -print0)
    }
  '';

  mkEnforce =
    {
      name,
      dry,
    }:
    pkgs.writeShellScriptBin name ''
      set -euo pipefail
      HOME_DIR=${lib.escapeShellArg cfg.home}
      QUARANTINE=${lib.escapeShellArg quarantinePath}
      DRY=${lib.escapeShellArg (lib.boolToString dry)}
      STAMP="$(date +%Y-%m-%d_%H-%M-%S)"
      ${mkAllowArray "allow_top" cfg.allow.top}
      ${mkAllowArray "allow_config" cfg.allow.config}
      ${mkAllowArray "allow_share" cfg.allow.share}
      ${mkAllowArray "allow_state" cfg.allow.state}
      ${commonLib}
      enforce_dir "$HOME_DIR" "''${allow_top[@]}"
      enforce_dir "$HOME_DIR/.config" "''${allow_config[@]}"
      enforce_dir "$HOME_DIR/.local/share" "''${allow_share[@]}"
      enforce_dir "$HOME_DIR/.local/state" "''${allow_state[@]}"
    '';

  enforceScript = mkEnforce {
    name = "home-enforce";
    dry = cfg.dryRun;
  };
  auditScript = mkEnforce {
    name = "home-audit";
    dry = true;
  };

  promoteScript = pkgs.writeShellScriptBin "home-promote" ''
    set -euo pipefail
    Q=${lib.escapeShellArg quarantinePath}
    if [[ $# -eq 0 ]]; then
      echo "Uso: home-promote <ruta-dentro-de-cuarentena> [destino]"
      echo "Cuarentena reciente:"
      ls -1 "$Q" 2>/dev/null || true
      exit 0
    fi
    src="$Q/$1"
    [[ -e "$src" ]] || { echo "No existe: $src" >&2; exit 1; }
    rel="''${1#*/}"
    dest="''${2:-$HOME/$rel}"
    mkdir -p "$(dirname "$dest")"
    mv -- "$src" "$dest"
    echo "Restaurado: $dest"
  '';

  pruneScript = pkgs.writeShellScriptBin "home-estado-prune" ''
    set -euo pipefail
    Q=${lib.escapeShellArg quarantinePath}
    [[ -d "$Q" ]] || exit 0
    find "$Q" -mindepth 1 -maxdepth 1 -mtime +${toString cfg.retentionDays} -exec rm -rf -- {} +
  '';

  janitorScript = pkgs.writeShellScriptBin "home-cache-janitor" ''
    set -euo pipefail
    AGE=${toString cfg.janitor.ageDays}
    HOME_DIR=${lib.escapeShellArg cfg.home}
    excludes=( ${lib.concatMapStringsSep " " lib.escapeShellArg cfg.janitor.exclude} )
    exargs=()
    for e in "''${excludes[@]}"; do
      exargs+=( -not -path "*/$e/*" )
    done
    for base in ${lib.concatMapStringsSep " " lib.escapeShellArg cfg.janitor.paths}; do
      d="$HOME_DIR/$base"
      [[ -d "$d" ]] || continue
      find "$d" -xdev -type f -mtime +"$AGE" "''${exargs[@]}" -delete 2>/dev/null || true
    done
  '';

  servicePath = [
    pkgs.coreutils
    pkgs.findutils
    pkgs.util-linux
  ];
in
{
  options.modulos.nixos.homeEstado = {
    enable = lib.mkEnableOption "enforcement de allowlist del home (cuarentena)";

    subvolumen = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Montar /home desde el subvolumen @home (migración). Hasta activarlo, el home sigue siendo el de preservation.";
      };
      device = lib.mkOption {
        type = lib.types.str;
        default = "/dev/mapper/DecryptedSystem";
        description = "Dispositivo btrfs que contiene @home";
      };
      name = lib.mkOption {
        type = lib.types.str;
        default = "@home";
        description = "Nombre del subvolumen para /home";
      };
    };

    user = lib.mkOption {
      type = lib.types.str;
      description = "Usuario dueño del home";
    };

    home = lib.mkOption {
      type = lib.types.str;
      default = "/home/${cfg.user}";
      description = "Ruta del home a gestionar";
    };

    allow = {
      top = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Entradas permitidas en el nivel superior del home";
      };
      config = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Entradas permitidas en ~/.config";
      };
      share = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Entradas permitidas en ~/.local/share";
      };
      state = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Entradas permitidas en ~/.local/state";
      };
    };

    quarantine = lib.mkOption {
      type = lib.types.str;
      default = ".quarantine";
      description = "Directorio (relativo al home) para lo no permitido";
    };

    retentionDays = lib.mkOption {
      type = lib.types.ints.positive;
      default = 30;
      description = "Días que se conserva lo cuarentenado";
    };

    dryRun = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Si true, no mueve nada: solo reporta";
    };

    janitor = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Limpieza por antigüedad de caché/estado";
      };
      ageDays = lib.mkOption {
        type = lib.types.ints.positive;
        default = 30;
        description = "Antigüedad (días) para borrar en los paths del janitor";
      };
      paths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          ".cache"
          ".local/state"
        ];
        description = "Subrutas del home a limpiar por antigüedad";
      };
      exclude = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "zsh"
          "wireplumber"
          "syncthing"
          "nix"
          "home-manager"
        ];
        description = "Nombres de subdirectorio excluidos del janitor";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    fileSystems."/home" = lib.mkIf cfg.subvolumen.enable {
      device = cfg.subvolumen.device;
      fsType = "btrfs";
      options = [
        "subvol=${cfg.subvolumen.name}"
        "noatime"
        "compress=zstd"
        "space_cache=v2"
      ];
      neededForBoot = true;
    };

    systemd.services.home-estado = {
      description = "Enforcement de allowlist del home (cuarentena)";
      wantedBy = [ "multi-user.target" ];
      after = [
        "local-fs.target"
        "home.mount"
      ];
      before = [ "display-manager.service" ];
      path = servicePath;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${enforceScript}/bin/home-enforce";
      };
    };

    systemd.services.home-estado-prune = {
      description = "Poda de la cuarentena del home";
      path = servicePath;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pruneScript}/bin/home-estado-prune";
      };
    };

    systemd.timers.home-estado-prune = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };

    systemd.services.home-cache-janitor = lib.mkIf cfg.janitor.enable {
      description = "Limpieza de caché/estado antiguo del home";
      path = servicePath;
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        ExecStart = "${janitorScript}/bin/home-cache-janitor";
      };
    };

    systemd.timers.home-cache-janitor = lib.mkIf cfg.janitor.enable {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };

    environment.systemPackages = [
      enforceScript
      auditScript
      promoteScript
    ];
  };
}
