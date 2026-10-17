{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.home.apps.obs;
in
{
  options.modulos.home.apps.obs = {
    enable = lib.mkEnableOption "OBS Studio";

    # El plugin de atajos globales de Wayland aún no está en nixpkgs-stable
    # (26.05), así que OBS y sus plugins salen de unstable.
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.unstable.obs-studio;
      description = "Paquete de OBS Studio a usar.";
    };

    plugins = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ pkgs.unstable.obs-studio-plugins.obs-wayland-hotkeys ];
      description = "Plugins de OBS Studio a instalar.";
      example = lib.literalExpression "[ pkgs.unstable.obs-studio-plugins.obs-backgroundremoval ]";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.obs-studio = {
      enable = true;
      inherit (cfg) package plugins;
    };
  };
}
