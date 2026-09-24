{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modulos.home.desktop.iconosCarpetas;

  linea = ruta: icono: ''
    dir="$HOME/${ruta}"
    if [ -d "$dir" ]; then
      ${pkgs.glib}/bin/gio set -t string "$dir" metadata::custom-icon ${lib.escapeShellArg icono} || echo "no se pudo: $dir"
    fi
  '';

  asignar = pkgs.writeShellScriptBin "iconos-carpetas" ''
    set -euo pipefail
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList linea cfg.asignaciones)}
  '';
in
{
  options.modulos.home.desktop.iconosCarpetas = {
    enable = lib.mkEnableOption "iconos personalizados de carpetas (gvfs metadata)";

    asignaciones = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Mapa ruta-relativa-al-home -> nombre de icono del tema (theme-agnostic).";
      example = {
        Documentos = "folder-documents";
        Descargas = "folder-download";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ asignar ];

    systemd.user.services.iconos-carpetas = {
      Unit = {
        Description = "Iconos personalizados de carpetas";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${asignar}/bin/iconos-carpetas";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
