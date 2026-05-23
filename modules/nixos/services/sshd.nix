{ lib, config, ... }:
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
  };
}
