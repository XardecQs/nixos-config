{
  pkgs,
  lib,
  config,
  vars,
  host,
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
        home.file.".config/Code/User/settings.json".text =
          builtins.replaceStrings
            [
              "@FLAKE@"
              "@HOST@"
            ]
            [
              "${config.home.homeDirectory}/${vars.flakeSubpath}"
              host.hostname
            ]
            (builtins.readFile ./dotfiles/config/code/settings.json.tmpl);
      })
      (lib.mkIf cfg.xdgUserDirs.enable {
        xdg.userDirs = {
          enable = true;
          createDirectories = true;
          setSessionVariables = false;
          desktop = "$HOME/Escritorio";
          documents = "$HOME/Documentos";
          download = "$HOME/Descargas";
          music = "$HOME/Media/Música";
          pictures = "$HOME/Media/Imágenes";
          videos = "$HOME/Media/Vídeos";
          projects = "$HOME/Proyectos";
          templates = "$HOME/Documentos/Plantillas";
          publicShare = null;
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
