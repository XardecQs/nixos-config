{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.modulos.nixos.core.nix;
in
{
  options.modulos.nixos.core.nix = {
    enable = lib.mkEnableOption "nix";
    cores = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = null;
      description = "Número de cores para builds. null = auto-detectar.";
    };
    flakePath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Ruta al flake para nh. null = auto-detectar (/etc/nixos).";
    };
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
      }
      // lib.optionalAttrs (cfg.cores != null) {
        inherit (cfg) cores;
      };
    };
    programs = {
      nix-index = {
        enable = true;
        enableZshIntegration = true;
      };
      nix-index-database.comma.enable = true;
      nh =
        lib.recursiveUpdate
          {
            enable = true;
            clean.enable = true;
            clean.extraArgs = "--keep-since 4d --keep 3";
          }
          (
            lib.optionalAttrs (cfg.flakePath != null) {
              flake = "${cfg.flakePath}";
            }
          );
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
    ];
  };
}
