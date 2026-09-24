{
  lib,
  config,
  pkgs,
  vars,
  ...
}:
let
  cfg = config.modulos.nixos.core.nix;

  usersCfg =
    config.modulos.nixos.core.users or {
      enable = false;
    };
  admin = if usersCfg.enable then usersCfg.admin else null;

  repoPath =
    if cfg.flakePath != null then
      cfg.flakePath
    else if admin != null then
      "${config.users.users.${admin}.home}/${vars.flakeSubpath}"
    else
      null;
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
      description = "Ruta al flake para nh. null = derivar del hogar del administrador + vars.flakeSubpath.";
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
            lib.optionalAttrs (repoPath != null) {
              flake = "${repoPath}";
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
