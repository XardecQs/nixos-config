{ lib, config, pkgs, ... }:
{
  options.modulos.sistema.virtualisation.enable = lib.mkEnableOption "virtualisation";

  config = lib.mkIf config.modulos.sistema.virtualisation.enable {
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