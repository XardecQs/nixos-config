{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.home.core.zsh;
in
{
  options.modulos.home.core.zsh = {
    enable = lib.mkEnableOption "configuración de Zsh (migrada desde dotfiles)";
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      PAGER = "less";
    };

    xdg.configFile."zsh/p10k.zsh".source = ./zsh/p10k.zsh;

    programs = {
      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      zoxide = {
        enable = true;
        options = [
          "--cmd"
          "cd"
        ];
      };

      fzf = {
        enable = true;
        defaultOptions = [
          "--height"
          "55%"
          "--border"
        ];
        changeDirWidgetCommand = "fd --type d";
        changeDirWidgetOptions = [ "--preview 'lsd --color=always --tree --depth 2 {}'" ];
        fileWidgetCommand = "fd --type f";
      };

      zsh = lib.mkMerge [
        {
          enable = true;

          dotDir = "${config.xdg.configHome}/zsh";

          history = {
            path = "$HOME/.local/state/zsh/history";
            size = 100000;
            save = 100000;
            extended = true;
            expireDuplicatesFirst = true;
            ignoreDups = true;
            ignoreSpace = true;
            share = true;
          };

          shellAliases = {
            ls = "lsd";
            ll = "lsd -lh";
            la = "lsd -a";
            lla = "lsd -la";
            lt = "lsd --tree";
            catt = "bat --style=plain";
            grep = "grep --color=auto";
            diff = "diff --color=auto";
            cp = "cp --reflink=auto -v";
            mv = "mv -v";
            ".." = "cd ..";
            "..." = "cd ../..";
            "...." = "cd ../../..";
            tmx = "tmux attach -t main || tmux new-session -s main";
            c = "clear";
            q = "exit";
            ":q" = "exit";
            h = "history";
            j = "jobs -l";
            vim = "nvim";
            snvim = "sudo -E nvim";
            g = "git";
            ga = "git add";
            gp = "git pull";
            gc = "git commit";
            gs = "git status";
            gl = "git log --oneline --graph";
            gd = "git diff";
            dots = "cd ~/Proyectos/GitHub/nixos-config/modules/home/core/dotfiles";
            dotsn = "cd ~/Proyectos/GitHub/nixos-config/modules/home/core/dotfiles && nvim";
            dotsc = "cd ~/Proyectos/GitHub/nixos-config/modules/home/core/dotfiles && code .";
            "nix-shell" = "nix-shell --run zsh";
          };
        }

        {
          initContent = lib.mkOrder 550 ''
            [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]] && \
              source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
          '';
        }

        {
          initContent = ''
            setopt inc_append_history

            autoload -Uz compinit colors select-word-style
            compinit -d "''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
            colors
            select-word-style bash

            zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
            zstyle ':completion:*' menu select
            zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
            zstyle ':completion:*' group-name ""
            zstyle ':completion:*:descriptions' format '%F{blue}-- %d --%f'

            zstyle ':fzf-tab:*' fzf-flags --height=55% --border
            zstyle ':fzf-tab:complete:cd:*' fzf-preview \
              'lsd --color=always --tree --depth 2 $realpath 2>/dev/null || ls --color=always $realpath'

            bindkey '^[[1;5C' forward-word
            bindkey '^[[1;5D' backward-word
            bindkey '^H' backward-kill-word
            bindkey '^[[3~' delete-char
            bindkey '^[[3;5~' kill-word
            bindkey '^[[1~' beginning-of-line
            bindkey '^[[4~' end-of-line

            (( $+commands[code] )) && alias codepwd='code "$(pwd)"'
            (( $+commands[nautilus] )) && alias napwd='nautilus "$(pwd)" 2>/dev/null & disown'
            (( $+commands[fastfetch] )) && alias cf='clear && fastfetch' && alias cff='clear && fastfetch --config ~/.config/fastfetch/13-custom.jsonc'
            (( $+commands[unimatrix] )) && alias umatrix='unimatrix -s 95 -f'

            mkcd() { mkdir -p "$1" && cd "$1"; }

            extract() {
              local file="$1"
              if [[ -z "$file" ]]; then
                echo "Uso: extract <archivo>"
                return 1
              fi
              if [[ ! -f "$file" ]]; then
                echo "Error: '$file' no es un archivo válido o no existe."
                return 1
              fi
              echo "Extrayendo '$file'..."
              case "$file" in
                *.tar.bz2|*.tbz2) tar xvjf "$file"    ;;
                *.tar.gz|*.tgz)   tar xvzf "$file"    ;;
                *.tar.xz)         tar xvf  "$file"    ;;
                *.tar)            tar xvf  "$file"    ;;
                *.bz2)            bunzip2 -v "$file"  ;;
                *.gz)             gunzip -v "$file"   ;;
                *.rar)            unrar x "$file"     ;;
                *.zip)            unzip "$file"       ;;
                *.Z)              uncompress "$file"  ;;
                *.7z)             7z x "$file"        ;;
                *.xz)             xz -dv "$file"      ;;
                *)
                  echo "Error: No se reconoce el formato de '$file'."
                  return 1
                  ;;
              esac
              if [[ $? -eq 0 ]]; then
                echo "Extracción completada con éxito."
              else
                echo "Ocurrió un error durante la extracción."
                return 1
              fi
            }

            backup() { cp -r "$1" "$1.bak"; }

            rebuild() {
              local repo="$HOME/Proyectos/GitHub/nixos-config"
              local overrides=()
              [[ -d "$HOME/Proyectos/GitHub/font-collection/.git" ]] || \
                overrides+=(--override-input font-collection github:XardecQs/font-collection)
              [[ -d "$HOME/Proyectos/GitHub/samt-nix/.git" ]] || \
                overrides+=(--override-input gta-mo github:XardecQs/samt-nix)
              if (( ''${#overrides[@]} )); then
                nh os switch "$repo" "$@" -- "''${overrides[@]}"
              else
                nh os switch "$repo" "$@"
              fi
            }

            whereisreal() {
              local target="$1"
              local binary_path
              binary_path="''${target:A}"
              if [[ ! -e "$binary_path" ]]; then
                binary_path=$(which "$target" 2>/dev/null)
              fi
              if [[ -z "$binary_path" || ! -e "$binary_path" ]]; then
                echo "Error: '$target' no es un archivo válido ni un comando en el PATH."
                return 1
              fi
              if [[ -L "$binary_path" ]]; then
                echo "Es un enlace simbólico que apunta a:"
                realpath "$binary_path"
              else
                echo "Es un archivo real (no es un enlace):"
                echo "$binary_path"
              fi
            }

            crun() {
              if [ -z "$1" ]; then
                echo "Uso: crun archivo.cpp [argumentos...]"
                return 1
              fi
              local file="$1"
              local base=$(basename "''${file%.*}")
              local exec="/tmp/crun_$base"
              g++ -std=c++20 -O2 -Wall -Wextra "$file" -o "$exec" || return 1
              "$exec" "''${@:2}"
              local exit_code=$?
              rm -f "$exec"
              return $exit_code
            }

            for config in "''${XDG_CONFIG_HOME:-$HOME/.config}/zsh/p10k.zsh"; do
              [[ -f "$config" ]] && source "$config" && break
            done
          '';

          plugins = [
            {
              name = "zsh-syntax-highlighting";
              src = pkgs.zsh-syntax-highlighting;
              file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
            }
            {
              name = "zsh-autosuggestions";
              src = pkgs.zsh-autosuggestions;
              file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
            }
            {
              name = "zsh-completions";
              src = pkgs.zsh-completions;
            }
            {
              name = "fzf-tab";
              src = pkgs.zsh-fzf-tab;
              file = "share/fzf-tab/fzf-tab.plugin.zsh";
            }
            {
              name = "nix-zsh-completions";
              src = pkgs.nix-zsh-completions;
            }
            {
              name = "powerlevel10k";
              src = pkgs.zsh-powerlevel10k;
              file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
            }
          ];
        }
      ];
    };
  };
}
