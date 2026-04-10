{
  pkgs,
  lib,
  config,
  ...
}:
let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
  configs = {
    # final (relativo a home) = origen (absoluto desde dotfiles) #
    ".config/nvim" = "${dotfiles}/config/nvim";
    ".config/kitty" = "${dotfiles}/config/kitty";
    ".config/fastfetch" = "${dotfiles}/config/fastfetch";
    ".config/zsh" = "${dotfiles}/config/zsh";
    #".config/user-dirs.dirs" = "${dotfiles}/config/user-dirs.dirs";
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
  options.modulos.home-manager.dotfiles.enable = lib.mkEnableOption "dotfiles";
  config = lib.mkIf config.modulos.home-manager.dotfiles.enable {
    home.activation.cloneDotfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      DOTFILES_DIR="${dotfiles}"
      if [ ! -d "$DOTFILES_DIR" ]; then
        ${pkgs.git}/bin/git clone --progress --depth 1 https://github.com/XardecQs/dotfiles.git "$DOTFILES_DIR"
      fi
    '';

    home.activation.cloneFonts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      FONTS_DIR="$HOME/.local/share/fonts"
      if [ ! -d "$FONTS_DIR" ] || [ -z "$(ls -A "$FONTS_DIR" 2>/dev/null)" ]; then
        mkdir -p "$FONTS_DIR"
        ${pkgs.git}/bin/git clone --progress --depth 1 https://github.com/XardecQs/font-collection.git "$FONTS_DIR"
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
