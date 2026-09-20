{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.home.core.dotfiles;
in
{
  options.modulos.home.core.dotfiles = {
    enable = lib.mkEnableOption "dotfiles";
    nvim.enable = lib.mkEnableOption "configuración de Neovim";
    kitty.enable = lib.mkEnableOption "configuración de Kitty";
    fastfetch.enable = lib.mkEnableOption "configuración de Fastfetch";
    tmux.enable = lib.mkEnableOption "configuración de Tmux";
    alacritty.enable = lib.mkEnableOption "configuración de Alacritty";
    waybar.enable = lib.mkEnableOption "configuración de Waybar";
    wal.enable = lib.mkEnableOption "configuración de Pywal";
    wlogout.enable = lib.mkEnableOption "configuración de Wlogout";
    albert.enable = lib.mkEnableOption "configuración de Albert launcher";
    code.enable = lib.mkEnableOption "configuración de VS Code";
    xdgUserDirs.enable = lib.mkEnableOption "directorios XDG con nombres en español";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf cfg.nvim.enable {
        home.file.".config/nvim" = {
          source = ./dotfiles/config/nvim;
          recursive = true;
        };
      })
      (lib.mkIf cfg.kitty.enable {
        home.file.".config/kitty" = {
          source = ./dotfiles/config/kitty;
          recursive = true;
        };
      })
      (lib.mkIf cfg.fastfetch.enable {
        home.file.".config/fastfetch" = {
          source = ./dotfiles/config/fastfetch;
          recursive = true;
        };
      })
      (lib.mkIf cfg.tmux.enable {
        home.file.".config/tmux" = {
          source = ./dotfiles/config/tmux;
          recursive = true;
        };
      })
      (lib.mkIf cfg.alacritty.enable {
        home.file.".config/alacritty" = {
          source = ./dotfiles/config/alacritty;
          recursive = true;
        };
      })
      (lib.mkIf cfg.waybar.enable {
        home.file.".config/waybar" = {
          source = ./dotfiles/config/waybar;
          recursive = true;
        };
      })
      (lib.mkIf cfg.wal.enable {
        home.file.".config/wal" = {
          source = ./dotfiles/config/wal;
          recursive = true;
        };
      })
      (lib.mkIf cfg.wlogout.enable {
        home.file.".config/wlogout" = {
          source = ./dotfiles/config/wlogout;
          recursive = true;
        };
      })
      (lib.mkIf cfg.albert.enable {
        home.file = {
          ".config/albert" = {
            source = ./dotfiles/config/albert;
            recursive = true;
          };
          ".local/share/albert/widgetsboxmodel" = {
            source = ./dotfiles/config/albert/widgetsboxmodel;
            recursive = true;
          };
        };
      })
      (lib.mkIf cfg.code.enable {
        home.file.".config/Code/User/settings.json" = {
          source = ./dotfiles/config/code/settings.json;
        };
      })
      (lib.mkIf cfg.xdgUserDirs.enable {
        xdg.userDirs = {
          enable = true;
          createDirectories = true;
          setSessionVariables = false;
          desktop = "$HOME/Documentos/Escritorio";
          documents = "$HOME/Documentos";
          download = "$HOME/Descargas";
          music = "$HOME/Media/Música";
          pictures = "$HOME/Media/Imágenes";
          videos = "$HOME/Media/Vídeos";
          projects = "$HOME/Proyectos";
          templates = "$HOME/Documentos/Plantillas";
          publicShare = "$HOME/Documentos/Público";
        };
      })
      {
        home.packages = [
          (pkgs.writeShellScriptBin "ordenar" ''
            exec ${./dotfiles/scripts/ordenar.sh}
          '')
          (pkgs.writeShellScriptBin "desordenar" ''
            exec ${./dotfiles/scripts/desordenar.sh}
          '')
        ];
      }
    ]
  );
}
