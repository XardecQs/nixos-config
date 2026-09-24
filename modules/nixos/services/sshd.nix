{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.modulos.nixos.services.sshd;
in
{
  options.modulos.nixos.services.sshd = {
    enable = lib.mkEnableOption "sshd";
    passwordAuthentication = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Permitir autenticación por contraseña en SSH. Requiere además clave/password del usuario.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = cfg.passwordAuthentication;
        KbdInteractiveAuthentication = cfg.passwordAuthentication;
      };
    };

    environment.systemPackages = with pkgs; [
      sshfs
    ];
  };
}
