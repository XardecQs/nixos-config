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
    admin = lib.mkOption {
      type = lib.types.str;
      description = "Usuario administrador (wheel, con contraseña gestionada por age)";
    };
    adminDescription = lib.mkOption {
      type = lib.types.str;
      default = "Administrador";
      description = "Descripción (GECOS) del usuario administrador";
    };
    extraUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Usuarios adicionales sin contraseña gestionada por age";
    };
  };

  config = lib.mkIf cfg.enable {
    age.identityPaths = [
      (
        if config.modulos.nixos.homeEstado.subvolumen.enable then
          "/home/${cfg.admin}/.ssh/agenix"
        else
          "/persist/home/${cfg.admin}/.ssh/agenix"
      )
    ];

    age.secrets = {
      root-password.file = ../../../secrets/root-password.age;
      primaryUser-password.file = ../../../secrets/primaryUser-password.age;
    };

    users = {
      mutableUsers = true;
      defaultUserShell = pkgs.zsh;
      users = {
        root = {
          shell = pkgs.zsh;
          hashedPasswordFile = config.age.secrets.root-password.path;
        };
        ${cfg.admin} = {
          isNormalUser = true;
          description = cfg.adminDescription;
          extraGroups = [
            "networkmanager"
            "wheel"
          ];
          hashedPasswordFile = config.age.secrets.primaryUser-password.path;
        };
      }
      // builtins.listToAttrs (
        map (name: {
          name = name;
          value = {
            isNormalUser = true;
            extraGroups = [ "networkmanager" ];
          };
        }) cfg.extraUsers
      );
    };
    programs = {
      zsh.enable = true;
    };
  };
}
