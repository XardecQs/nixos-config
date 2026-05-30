{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.nixos.services.printing;
in
{
  options.modulos.nixos.services.printing = {
    enable = lib.mkEnableOption "printing";
  };

  config = lib.mkIf cfg.enable {
    services.printing = {
      enable = true;
      drivers = [
        pkgs.epson-escpr2
        pkgs.epson-escpr
      ];
    };

    users.users.xardec = {
      extraGroups = [
        "scanner"
        "lp"
      ];
    };

    hardware.sane = {
      enable = true;
      extraBackends = [
        (pkgs.epsonscan2.override { withNonFreePlugins = true; })
      ];
    };

  };
}
