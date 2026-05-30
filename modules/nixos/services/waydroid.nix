{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.modulos.nixos.services.waydroid;
  user = config.modulos.nixos.core.users.primaryUser;
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
      users.${user} = {
        extraGroups = [
          "waydroid"
        ];
      };
      users."waydroid-${user}" = {
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

    environment.persistence."/persist" = lib.mkIf config.modulos.nixos.core.impermanence.enable {
      directories = [ "/var/lib/waydroid" ];
    };
  };
}
