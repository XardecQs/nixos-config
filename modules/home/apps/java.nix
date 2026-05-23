{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.home.apps.java;
in
{
  options.modulos.home.apps.java = {
    enable = lib.mkEnableOption "java";
  };

  config = lib.mkIf cfg.enable {
    programs.java = {
      enable = true;
      package = pkgs.zulu25.override {
        enableJavaFX = true;
      };
    };
  };
}
