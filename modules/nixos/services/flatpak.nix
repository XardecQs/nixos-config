{ lib, config, ... }:
let
  cfg = config.modulos.nixos.services.flatpak;
in
{
  options.modulos.nixos.services.flatpak = {
    enable = lib.mkEnableOption "flatpak";
  };

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;

    environment.persistence."/persist" = lib.mkIf config.modulos.nixos.core.impermanence.enable {
      users.${config.modulos.nixos.core.users.primaryUser}.directories = [
        ".local/share/flatpak"
        ".var"
      ];
    };
  };
}
