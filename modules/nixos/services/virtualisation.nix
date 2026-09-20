{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.modulos.nixos.services.virtualisation;
  user = config.modulos.nixos.core.users.primaryUser;

  # libvirt espera una credencial cifrada con systemd-creds, pero el sellado
  # TPM2 falla en este equipo y la clave de host no sobrevive a impermanence.
  # Generamos la clave en texto plano y virtsecretd la carga con LoadCredential.
  virtSecretInit = pkgs.writeShellScript "virt-secret-init-plaintext" ''
    umask 0077
    ${pkgs.coreutils}/bin/dd if=/dev/urandom of=/var/lib/libvirt/secrets/secrets-encryption-key bs=32 count=1 status=none
    ${pkgs.coreutils}/bin/chmod 600 /var/lib/libvirt/secrets/secrets-encryption-key
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

    # libvirt 12.2 cifra la clave de secretos con systemd-creds (TPM2), que
    # falla en este equipo y se apoya en una clave de host que impermanence
    # no puede conservar. La generamos en texto plano y hacemos que los
    # demonios la carguen con LoadCredential en lugar de LoadCredentialEncrypted.
    systemd.services = {
      virt-secret-init-encryption = {
        overrideStrategy = "asDropinIfExists";
        serviceConfig.ExecStart = lib.mkForce [
          ""
          "${virtSecretInit}"
        ];
      };
    }
    // lib.genAttrs [ "libvirtd" "virtsecretd" ] (_: {
      overrideStrategy = "asDropinIfExists";
      serviceConfig = {
        LoadCredentialEncrypted = lib.mkForce [ "" ];
        LoadCredential = [ "secrets-encryption-key:/var/lib/libvirt/secrets/secrets-encryption-key" ];
      };
    });

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
