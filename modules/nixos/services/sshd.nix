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
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings.PermitRootLogin = "no";
    };

    environment.systemPackages = with pkgs; [
      sshfs
    ];

    environment.persistence."/persist" = lib.mkIf config.modulos.nixos.core.impermanence.enable {
      users.${config.modulos.nixos.core.users.primaryUser}.directories = [ ".ssh" ];
    };
  };
}
