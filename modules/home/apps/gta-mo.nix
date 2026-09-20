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

    persistencia = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Persistir los datos de gta-mo: base de datos de mods y ajustes de usuario.";
    };

    gameRoot = lib.mkOption {
      type = lib.types.str;
      default = "/home/xardec/Juegos/Windows/GTA_SA_Limpio";
      description = "Directorio raíz de GTA SA (game_root).";
    };

    protonPath = lib.mkOption {
      type = lib.types.str;
      default = "/home/xardec/.steam/root/compatibilitytools.d/GE-Proton11-6";
      description = "Directorio de la tool de Proton/GE (proton_path).";
    };

    disableUpscalers = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Evitar que Proton (GE/CachyOS) descargue/actualice upscalers (FSR/DLSS/XeSS/OptiScaler).";
    };
  };

  config = lib.mkIf cfg.enable {
    # El default del módulo es `true`; aquí se deja desactivado por ahora
    # (probando distintos protons). Ponlo en true cuando quieras evitar la
    # descarga de modelos/upscalers.
    modulos.home.apps.gta-mo.disableUpscalers = false;

    programs.gta-mo = {
      enable = true;
      enableGui = true;
      package = inputs.gta-mo.packages.${pkgs.stdenv.hostPlatform.system}.default;
      guiPackage = inputs.gta-mo.packages.${pkgs.stdenv.hostPlatform.system}.gta-mo-gui;
      settings = {
        game_root = cfg.gameRoot;
        proton_path = cfg.protonPath;
        proton_disable_upscalers = cfg.disableUpscalers;
      };
    };
  };
}
