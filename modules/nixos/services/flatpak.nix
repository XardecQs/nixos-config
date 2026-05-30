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

    environment.persistence."/persist".users.xardec.directories = [
      ".local/share/flatpak"
      ".var"
    ];
  };
}
