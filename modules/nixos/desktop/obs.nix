{ lib, config, ... }:
let
  cfg = config.modulos.nixos.desktop.obs;
in
{
  options.modulos.nixos.desktop.obs = {
    enable = lib.mkEnableOption "soporte de sistema para OBS Studio (cámara virtual)";

    enableVirtualCamera = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Instala y configura v4l2loopback para la cámara virtual de OBS.";
    };
  };

  config = lib.mkIf cfg.enable {
    # OBS se instala desde Home Manager; aquí solo se prepara el sistema.
    programs.obs-studio = {
      enable = true;
      package = null;
      inherit (cfg) enableVirtualCamera;
    };
  };
}
