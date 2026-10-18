{ lib, config, ... }:
let
  cfg = config.modulos.home.apps.flatpak;
in
{
  options.modulos.home.apps.flatpak = {
    enable = lib.mkEnableOption "paquetes Flatpak del usuario";

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Aplicaciones Flatpak declarativas (nix-flatpak).";
    };
  };

  config = lib.mkIf cfg.enable {
    services.flatpak = {
      enable = true;
      inherit (cfg) packages;
    };
  };
}
