{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.modulos.home.apps.lan-mouse;
in
{
  options.modulos.home.apps.lan-mouse = {
    enable = lib.mkEnableOption "lan-mouse";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      inputs.lan-mouse.packages.${pkgs.system}.default
    ];
  };
}
