{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.nixos.core.locate;
in
{
  options.modulos.nixos.core.locate = {
    enable = lib.mkEnableOption "locate";
  };

  config = lib.mkIf cfg.enable {
    services.locate = {
      enable = true;
      package = pkgs.plocate;
      interval = "hourly";
      prunePaths = [
        "/tmp"
        "/var/tmp"
        "/home/.cache"
      ];
    };

    environment.persistence."/persist" = lib.mkIf config.modulos.nixos.core.impermanence.enable {
      files = [ "/var/cache/locatedb" ];
    };
  };
}
