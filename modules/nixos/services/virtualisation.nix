{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.modulos.nixos.services.virtualisation;
  user = config.modulos.nixos.core.users.primaryUser;

  # En este equipo el sellado TPM2 de systemd-creds falla y systemd-creds
  # aborta (bug). Se cifra la clave de secretos de libvirt con la clave de host.
  virtSecretInit = pkgs.writeShellScript "virt-secret-init-encryption-host" ''
    umask 0077
    dd if=/dev/random status=none bs=32 count=1 \
      | ${config.systemd.package}/bin/systemd-creds encrypt \
          --with-key=host \
          --name=secrets-encryption-key \
          - /var/lib/libvirt/secrets/secrets-encryption-key
  '';
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

    # La unidad original de libvirt usa systemd-creds con TPM2; la reemplazamos
    # por una variante con --with-key=host para evitar el cuelgue del TPM.
    systemd.services.virt-secret-init-encryption = {
      overrideStrategy = "asDropinIfExists";
      serviceConfig.ExecStart = lib.mkForce [
        ""
        "${virtSecretInit}"
      ];
    };

    environment.systemPackages = with pkgs; [
      distrobox
    ];
    users.users.${user}.extraGroups = [
      "podman"
      "libvirtd"
    ];
    services.spice-vdagentd.enable = true;
  };
}
