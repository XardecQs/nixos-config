{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.nixos.desktop.sway;
in
{
  options.modulos.nixos.desktop.sway = {
    enable = lib.mkEnableOption "sway";
  };

  config = lib.mkIf cfg.enable {
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      xdgOpenUsePortal = true;
    };

    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
    };

    environment.loginShellInit = ''
      if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
        exec sway
      fi
    '';
  };
}
