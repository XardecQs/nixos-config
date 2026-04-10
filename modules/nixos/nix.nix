{
  lib,
  config,
  pkgs,
  ...
}:
let
  category = "sistema"; # [ sistema | home-manager ]
  moduleName = "nix";
in
{
  options.modulos.${category}.${moduleName}.enable = lib.mkEnableOption moduleName;

  config = lib.mkIf config.modulos.${category}.${moduleName}.enable {
    nixpkgs.config.allowUnfree = true;
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
        flake = "/etc/nixos";
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
  };
}
