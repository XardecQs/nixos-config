{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modulos.nixos.homeEstado;

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
  ];
in
{
  options.modulos.nixos.homeEstado.janitor = {
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

  config = lib.mkIf (cfg.enable && cfg.janitor.enable) {
    systemd.services.home-cache-janitor = {
      description = "Limpieza de caché/estado antiguo del home";
      path = servicePath;
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        ExecStart = "${janitorScript}/bin/home-cache-janitor";
      };
    };

    systemd.timers.home-cache-janitor = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };
  };
}
