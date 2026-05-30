{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.nixos.desktop.systemPackages;
in
{
  options.modulos.nixos.desktop.systemPackages = {
    enable = lib.mkEnableOption "systemPackages";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      adw-gtk3
      neovim
      tree-sitter
      wl-clipboard
      bindfs
      btrfs-progs
      bubblewrap
      direnv
      entr
      gparted
      tree
      hwloc
      beep
    ];
  };
}
