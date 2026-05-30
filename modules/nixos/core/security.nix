{ lib, config, ... }:
let
  cfg = config.modulos.nixos.core.security;
in
{
  options.modulos.nixos.core.security = {
    enable = lib.mkEnableOption "security";
  };

  config = lib.mkIf cfg.enable {
    security = {
      rtkit.enable = true;
      polkit.enable = true;
      allowUserNamespaces = true;
      pam.services.login.enableGnomeKeyring = true;
    };

    environment.persistence."/persist" = {
      directories = [ "/var/db/sudo" ];
      users.xardec.directories = [ ".local/share/keyrings" ];
    };
  };
}
