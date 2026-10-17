{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.modulos.home.apps.artcraft;

  apps = [
    "photocraft"
    "vectorcraft"
    "filmcraft"
    "lightcraft"
    "pdfcraft"
    "effectcraft"
    "designcraft"
    "figcraft"
    "wordcraft"
    "soundcraft"
    "deckcraft"
    "cadcraft"
    "gridcraft"
  ];
in
{
  imports = [ inputs.artcraft-nix.homeManagerModules.default ];

  options.modulos.home.apps.artcraft = {
    enable = lib.mkEnableOption "las ArtCraft Craft Apps";

    apps = lib.mkOption {
      type = lib.types.listOf (lib.types.enum apps);
      default = apps;
      description = "Apps de ArtCraft instaladas para el usuario.";
      example = [
        "photocraft"
        "gridcraft"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    programs.artcraft = {
      enable = true;
      inherit (cfg) apps;
    };
  };
}
