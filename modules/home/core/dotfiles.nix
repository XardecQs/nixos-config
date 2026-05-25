{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.home.core.dotfiles;
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
  configs = {
    ".config/nvim" = "${dotfiles}/config/nvim";
    ".config/kitty" = "${dotfiles}/config/kitty";
    ".config/fastfetch" = "${dotfiles}/config/fastfetch";
    ".config/zsh" = "${dotfiles}/config/zsh";
    ".icons" = "${dotfiles}/homedots/icons";
    ".local/share/icons" = "${dotfiles}/homedots/icons";
    ".config/Code/User/settings.json" = "${dotfiles}/config/code/settings.json";
    ".config/tmux" = "${dotfiles}/config/tmux";
    ".zshrc" = "${dotfiles}/homedots/zshrc";
    ".config/alacritty" = "${dotfiles}/config/alacritty";
    ".config/sway" = "${dotfiles}/config/sway";
    ".config/waybar" = "${dotfiles}/config/waybar";
    ".config/wal" = "${dotfiles}/config/wal";
    ".config/albert" = "${dotfiles}/config/albert";
    ".local/share/albert/widgetsboxmodel" = "${dotfiles}/config/albert/widgetsboxmodel";
  };
in
{
  options.modulos.home.core.dotfiles = {
    enable = lib.mkEnableOption "dotfiles";
  };

  config = lib.mkIf cfg.enable {
    home.activation.cloneDotfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      DOTFILES_DIR="${dotfiles}"
      if [ ! -d "$DOTFILES_DIR" ]; then
        ${pkgs.git}/bin/git clone --progress --depth 1 https://github.com/XardecQs/dotfiles.git "$DOTFILES_DIR"
      fi
    '';

    home.file = builtins.mapAttrs (name: abspath: {
      source = create_symlink abspath;
      recursive = true;
    }) configs;

    xdg.userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "$HOME/Documentos/Escritorio";
      documents = "$HOME/Documentos";
      download = "$HOME/Descargas";
      music = "$HOME/Media/Música";
      pictures = "$HOME/Media/Imágenes";
      videos = "$HOME/Media/Vídeos";
      templates = "$HOME/Documentos/Plantillas";
      publicShare = "$HOME/Documentos/Público";
    };
  };
}
