{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.modulos.home.apps.horizon;
in
{
  imports = [ inputs.horizon-nix.homeManagerModules.default ];

  options.modulos.home.apps.horizon = {
    enable = lib.mkEnableOption "el launcher de Horizon (Minecraft: Java Edition en Rust)";
  };

  config = lib.mkIf cfg.enable {
    programs.horizon.enable = true;
  };
}
