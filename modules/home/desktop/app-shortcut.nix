{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.home.desktop.appShortcut;

  extensionUuid = "desktop-shortcut@xardec.local";

  extension = pkgs.runCommand "gnome-shell-extension-desktop-shortcut" { } ''
    mkdir -p $out/share/gnome-shell/extensions/${extensionUuid}
    cp -r ${./app-shortcut}/. \
      $out/share/gnome-shell/extensions/${extensionUuid}/
  '';
in
{
  options.modulos.home.desktop.appShortcut = {
    enable = lib.mkEnableOption "crear accesos directos desde la app grid";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ extension ];

    dconf.settings."org/gnome/shell".enabled-extensions = lib.mkAfter [ extensionUuid ];
  };
}
