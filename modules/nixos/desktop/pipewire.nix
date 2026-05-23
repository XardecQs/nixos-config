{ lib, config, ... }:
let
  cfg = config.modulos.nixos.desktop.pipewire;
in
{
  options.modulos.nixos.desktop.pipewire = {
    enable = lib.mkEnableOption "pipewire";
  };

  config = lib.mkIf cfg.enable {
    services.pipewire = {
      enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
    };
  };
}
