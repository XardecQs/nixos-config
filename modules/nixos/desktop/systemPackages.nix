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
      bat
      btop
      fastfetch
      fzf
      gdu
      lsd
      neovim
      tree-sitter
      ripgrep
      tmux
      unzip
      wget
      wl-clipboard
      yazi
      zoxide
      bindfs
      btrfs-progs
      bubblewrap
      direnv
      entr
      fd
      gparted
      tree
      unimatrix
      hwloc
      beep
    ];
  };
}
