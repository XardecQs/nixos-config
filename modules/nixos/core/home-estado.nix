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
      # La cuarentena la crea root: cederla al usuario para que `home-promote`
      # pueda restaurar sin sudo.
      if [[ "$DRY" != "true" ]]; then
        chown -R ${lib.escapeShellArg cfg.user} "$QUARANTINE" 2>/dev/null || true
      fi
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

  servicePath = [
    pkgs.coreutils
    pkgs.findutils
    pkgs.util-linux
  ];
in
{
  options.modulos.nixos.homeEstado = {
    enable = lib.mkEnableOption "enforcement de allowlist del home (cuarentena)";

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
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion =
          cfg.dryRun
          || (
            cfg.allow.top != [ ] && cfg.allow.config != [ ] && cfg.allow.share != [ ] && cfg.allow.state != [ ]
          );
        message = ''
          modulos.nixos.homeEstado: con dryRun = false ninguna categoría de la
          allowlist (top/config/share/state) puede quedar vacía, o se cuarentenaría
          todo su contenido. Completa users/<usuario>/home-allowlist.nix o activa dryRun.
        '';
      }
    ];

    systemd = {
      services.home-estado = {
        description = "Enforcement de allowlist del home (cuarentena)";
        wantedBy = [ "multi-user.target" ];
        requires = [ "home.mount" ];
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

      services.home-estado-prune = {
        description = "Poda de la cuarentena del home";
        path = servicePath;
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pruneScript}/bin/home-estado-prune";
        };
      };

      timers.home-estado-prune = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };
    };

    environment.systemPackages = [
      enforceScript
      auditScript
      promoteScript
    ];
  };
}
