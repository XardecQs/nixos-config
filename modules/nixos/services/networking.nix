{ lib, config, ... }:
let
  cfg = config.modulos.nixos.services.networking;
in
{
  options.modulos.nixos.services.networking = {
    enable = lib.mkEnableOption "networking";
  };

  config = lib.mkIf cfg.enable {
    networking = {
      networkmanager.enable = true;
      firewall = {
        allowedTCPPorts = [ 4242 ];
        allowedUDPPorts = [ 4242 ];
      };
    };
  };
}
