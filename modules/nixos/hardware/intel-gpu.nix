{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.nixos.hardware.intel-gpu;
in
{
  options.modulos.nixos.hardware.intel-gpu = {
    enable = lib.mkEnableOption "intel-gpu";
  };

  config = lib.mkIf cfg.enable {
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = [ pkgs.intel-media-driver ];
      };
      enableRedistributableFirmware = true;
    };
    services.xserver.videoDrivers = [ "intel" ];
  };
}
