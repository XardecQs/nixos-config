{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.modulos.nixos.core.nix;
  user = config.modulos.nixos.core.users.primaryUser;
in
{
  options.modulos.nixos.core.nix = {
    enable = lib.mkEnableOption "nix";
  };

  config = lib.mkIf cfg.enable {
    nix = {
      settings = {
        trusted-users = [
          "root"
          "@wheel"
        ];
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        auto-optimise-store = true;
        warn-dirty = false;
      }
      // lib.optionalAttrs (config.networking.hostName == "PC-Hogar") {
        cores = 1;
      };
    };
    programs = {
      nix-index = {
        enable = true;
        enableZshIntegration = true;
      };
      nix-index-database.comma.enable = true;
      nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 4d --keep 3";
        flake = "/home/${user}/Proyectos/GitHub/nixos-config";
      };
      nix-ld.enable = true;
      appimage = {
        enable = true;
        binfmt = true;
      };
    };

    environment.systemPackages = with pkgs; [
      nix-output-monitor
      nixd
      nvd
      nil
      nix-ld
      comma
    ];

    environment.persistence."/persist" = lib.mkIf config.modulos.nixos.core.impermanence.enable {
      directories = [ "/var/lib/nixos" ];
      users.${user}.directories = [ ".cache/nix-index" ];
    };
  };
}
