{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.nixos.core.users;
in
{
  options.modulos.nixos.core.users = {
    enable = lib.mkEnableOption "users";
  };

  config = lib.mkIf cfg.enable {
    users = {
      mutableUsers = false;
      defaultUserShell = pkgs.zsh;
      users.root = {
        shell = pkgs.zsh;
        hashedPassword = "$6$xQm6HutX3PwIE0TQ$yTRaUx5z2K7V3Qhfqnf976QwYr5hZYR2uuJsUPkCRiCrEOkZomyUraJ5fJb1LC2j.GCvvzYpRabrVyfjkRIn/1";
      };
      users.xardec = {
        isNormalUser = true;
        description = "Xavier Del Piero";
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
        hashedPassword = "$6$6kcVeTMDK6yE6XdY$cgvhSqLBhNShREDb.cdNYV0iJS3GpqM.HTjcJKFt864nsnOviqoL6tZah/oamGZe3REqS8q1MQPcxq/76jYTW.";
      };
    };
    programs = {
      zsh.enable = true;
    };
  };
}
