{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.modulos.nixos.services.waydroid;
in
{
  options.modulos.nixos.services.waydroid = {
    enable = lib.mkEnableOption "waydroid";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.waydroid.enable = true;
    environment.systemPackages = with pkgs; [
      unstable.waydroid
      unstable.waydroid-helper
    ];

    users = {
      users.xardec = {
        extraGroups = [
          "waydroid"
        ];
      };
      users.waydroid-xardec = {
        isSystemUser = true;
        uid = 10121;
        group = "waydroid";
        home = "/var/empty";
        shell = "/run/current-system/sw/bin/nologin";
      };
      users.waydroid-root = {
        isSystemUser = true;
        uid = 1023;
        group = "waydroid";
        home = "/var/empty";
        shell = "/run/current-system/sw/bin/nologin";
      };
      groups.waydroid.gid = 1023;
    };

    environment.persistence."/persist".directories = [ "/var/lib/waydroid" ];
  };
}
