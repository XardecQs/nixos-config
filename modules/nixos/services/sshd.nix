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
    hostKeysPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Directorio persistente para las claves del host (null = /etc/ssh).";
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
    }
    // lib.optionalAttrs (cfg.hostKeysPath != null) {
      hostKeys = [
        {
          path = "${cfg.hostKeysPath}/ssh_host_ed25519_key";
          type = "ed25519";
        }
        {
          path = "${cfg.hostKeysPath}/ssh_host_rsa_key";
          type = "rsa";
          bits = 4096;
        }
      ];
    };

    environment.systemPackages = with pkgs; [
      sshfs
    ];
  };
}
