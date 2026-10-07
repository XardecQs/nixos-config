{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.modulos.home.apps.gta-mo;
in
{
  imports = [ inputs.gta-mo.homeManagerModules.default ];

  options.modulos.home.apps.gta-mo = {
    enable = lib.mkEnableOption "gta-mo";

    gameRoot = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/Juegos/Windows/GTA_SA_Limpio";
      description = "Directorio raíz de GTA SA (game_root).";
    };

    protonPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.steam/root/compatibilitytools.d/GE-Proton11-6";
      description = "Directorio de la tool de Proton/GE (proton_path).";
    };

    disableUpscalers = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Evitar que Proton (GE/CachyOS) descargue/actualice upscalers (FSR/DLSS/XeSS/OptiScaler).";
    };

    preload = lib.mkOption {
      type = lib.types.enum [ "off" "prefix" "full" ];
      default = "prefix";
      description = ''
        Precarga en caché de página antes de lanzar: "off", "prefix" (por
        defecto) o "full" (también el juego base y todos los mods; avisa y pide
        confirmación en terminal interactiva).
      '';
    };

    timings = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Imprimir tiempos por fase durante el arranque.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.gta-mo = {
      enable = true;
      enableGui = true;
      package = inputs.gta-mo.packages.${pkgs.stdenv.hostPlatform.system}.default;
      guiPackage = inputs.gta-mo.packages.${pkgs.stdenv.hostPlatform.system}.gta-mo-gui;
      settings = {
        game_root = cfg.gameRoot;
        proton_path = cfg.protonPath;
        proton_disable_upscalers = cfg.disableUpscalers;
        proton_use_wined3d = false;
        auto_discover = true;
        preload = cfg.preload;
        timings = cfg.timings;
        proton_log = false;
        prefix_ram = true;
        prefix_ram_proton = true;
        preload_proton = false;
        preload_steamrt = false;
      };
      gameDesktopEntry = {
        enable = true;
        icon = "gta-san-andreas";
        wmClass = "steam_app_gtasa";
      };
    };
  };
}
