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
    primaryUser = lib.mkOption {
      type = lib.types.str;
      description = "Usuario primario del sistema";
    };
  };

  config = lib.mkIf cfg.enable {
    age.identityPaths = [ "/persist/home/${cfg.primaryUser}/.ssh/agenix" ];

    age.secrets = {
      root-password.file = ../../../secrets/root-password.age;
      primaryUser-password.file = ../../../secrets/primaryUser-password.age;
    };

    users = {
      mutableUsers = true;
      defaultUserShell = pkgs.zsh;
      users.root = {
        shell = pkgs.zsh;
        hashedPasswordFile = config.age.secrets.root-password.path;
      };
      users.${cfg.primaryUser} = {
        isNormalUser = true;
        description = "Xavier Del Piero";
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
        hashedPasswordFile = config.age.secrets.primaryUser-password.path;
      };
    };
    programs = {
      zsh.enable = true;
    };
  };
}
