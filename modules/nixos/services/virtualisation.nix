{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.modulos.nixos.services.virtualisation;
in
{
  options.modulos.nixos.services.virtualisation = {
    enable = lib.mkEnableOption "virtualisation";
  };

  config = lib.mkIf cfg.enable {
    programs.virt-manager.enable = true;

    virtualisation = {
      libvirtd.enable = true;
      podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
      };
    };

    environment.systemPackages = with pkgs; [
      distrobox
    ];
    users.users.xardec.extraGroups = [
      "podman"
      "libvirtd"
    ];
    services.spice-vdagentd.enable = true;
  };
}
