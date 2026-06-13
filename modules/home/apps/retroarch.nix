{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.modulos.home.apps.retroarch;
in
{
  options.modulos.home.apps.retroarch = {
    enable = lib.mkEnableOption "retroarch";
  };

  config = lib.mkIf cfg.enable {
    programs.retroarch.enable = true;
    home.packages = with pkgs.libretro; [
      mgba
      neocd
      snes9x
      pcsx2
      dolphin
      ppsspp
      swanstation
    ];
    home.file.".config/retroarch/cores" = {
      source = "${config.home.path}/lib/retroarch/cores";
      force = true;
    };

    home.persistence."/persist".directories = [
      ".config/retroarch"
    ];
  };
}
