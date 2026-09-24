{
  lib,
  config,
  vars,
  ...
}:
let
  cfg = config.modulos.nixos.core.general;
in
{
  options.modulos.nixos.core.general = {
    enable = lib.mkEnableOption "general";
    stateVersion = lib.mkOption {
      type = lib.types.str;
      default = vars.stateVersion;
      description = "stateVersion del sistema (fuente única: vars.nix)";
    };
  };

  config = lib.mkIf cfg.enable {
    system.stateVersion = cfg.stateVersion;
    time.timeZone = vars.timezone;
    i18n.defaultLocale = vars.locale;
    console.keyMap = "la-latin1";
  };
}
