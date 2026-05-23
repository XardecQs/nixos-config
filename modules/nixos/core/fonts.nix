{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.nixos.core.fonts;
in
{
  options.modulos.nixos.core.fonts = {
    enable = lib.mkEnableOption "fonts";
  };

  config = lib.mkIf cfg.enable {
    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
    ];
  };
}
