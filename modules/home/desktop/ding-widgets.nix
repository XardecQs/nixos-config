{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modulos.home.desktop.dingWidgets;

  upstreamRev = "ae806aac6463de619fd15332da2e4c975229aecd";
  upstreamHash = "sha256-wbzDJ+n3T1eG483Ww2UY1zm4yJoVt2wpnPB3LGaJed8=";

  upstreamSrc = pkgs.fetchzip {
    url = "https://gitlab.com/smedius/desktop-icons-ng/-/archive/${upstreamRev}/desktop-icons-ng-${upstreamRev}.tar.gz";
    hash = upstreamHash;
  };

  upstreamWidgets =
    pkgs.runCommand "ding-widgets-upstream-${upstreamRev}"
      {
        meta = {
          description = "Widgets por defecto de Gtk4 Desktop Icons NG";
          license = lib.licenses.gpl3Plus;
        };
      }
      ''
        mkdir -p $out/share/com.desktop.ding/widgets
        cp -r ${upstreamSrc}/widgets/. $out/share/com.desktop.ding/widgets/
      '';

  mkWidget =
    {
      name,
      src,
      manifest,
      files ? { },
    }:
    pkgs.runCommand "ding-widget-${name}" { } ''
      mkdir -p $out/share/com.desktop.ding/widgets/${name}
      cp -r ${src}/. $out/share/com.desktop.ding/widgets/${name}/
      cp ${pkgs.writeText "widget.json" (builtins.toJSON manifest)} \
        $out/share/com.desktop.ding/widgets/${name}/widget.json
      ${lib.concatStrings (
        lib.mapAttrsToList (filename: source: ''
          install -Dm644 ${source} \
            $out/share/com.desktop.ding/widgets/${name}/${filename}
        '') files
      )}
      chmod -R u+w $out
      if [ -f $out/share/com.desktop.ding/widgets/${name}/backend.py ]; then
        chmod +x $out/share/com.desktop.ding/widgets/${name}/backend.py
      fi
    '';

  actionsJson = pkgs.writeText "command-deck-actions.json" (
    builtins.toJSON (lib.mapAttrsToList (id: action: action // { inherit id; }) cfg.commandDeck.actions)
  );

  cavaWidget = mkWidget {
    name = "cava";
    src = ./ding-widgets/cava;
    manifest = {
      id = "cava.horizontal";
      name = "Cava Spectrum";
      description = "Espectro de audio del sistema con cava";
      kind = "html";
      defaultWidth = 480;
      defaultHeight = 160;
      pinnable = true;
      defaultConfig = {
        barColor = "#31e6ff";
        barColor2 = "#8a5cff";
        bgAlpha = 0.18;
        showPeaks = true;
      };
      backend = {
        command = "${pkgs.python3}/bin/python3";
        args = [ "backend.py" ];
        env = {
          CAVA_BIN = "${pkgs.cava}/bin/cava";
        };
      };
    };
  };

  nowPlayingWidget = mkWidget {
    name = "now-playing-cava";
    src = ./ding-widgets/now-playing-cava;
    manifest = {
      id = "now-playing.cava";
      name = "Now Playing + Cava";
      description = "Reproductor MPRIS con espectro de audio integrado";
      kind = "html";
      defaultWidth = 480;
      defaultHeight = 200;
      pinnable = true;
      defaultConfig = {
        accent = "#31e6ff";
        showSpectrum = true;
      };
      backend = {
        command = "${pkgs.python3}/bin/python3";
        args = [ "backend.py" ];
        env = {
          CAVA_BIN = "${pkgs.cava}/bin/cava";
          PLAYERCTL_BIN = "${pkgs.playerctl}/bin/playerctl";
        };
      };
    };
  };

  commandDeckWidget = mkWidget {
    name = "command-deck";
    src = ./ding-widgets/command-deck;
    manifest = {
      id = "command.deck";
      name = "Command Deck";
      description = "Acciones declaradas del sistema y del usuario";
      kind = "html";
      defaultWidth = 380;
      defaultHeight = 280;
      pinnable = true;
      prefs = "prefs.html";
      defaultConfig = {
        enabledActions = [
          "rebuild"
          "gwal-random"
          "ordenar"
          "home-audit"
        ];
      };
      backend = {
        command = "${pkgs.python3}/bin/python3";
        args = [ "backend.py" ];
        env = {
          NOTIFY_SEND = "${pkgs.libnotify}/bin/notify-send";
        };
      };
    };
    files = {
      "actions.json" = actionsJson;
    };
  };

  stateFile = "${config.xdg.dataHome}/com.desktop.ding/widgets.json";
  declaredFile = pkgs.writeText "ding-widgets-declared.json" (builtins.toJSON cfg.instances);

  mergeScript = pkgs.writeTextFile {
    name = "ding-widgets-merge";
    executable = true;
    text = ''
      #!${pkgs.python3}/bin/python3
      import argparse
      import json
      import os
      import shutil
      import sys

      def load_json(path, fallback):
          try:
              with open(path, "r", encoding="utf-8") as handle:
                  return json.load(handle)
          except FileNotFoundError:
              return fallback
          except Exception as error:
              print(f"ding-widgets: ignorando {path}: {error}", file=sys.stderr)
              return fallback

      def main():
          parser = argparse.ArgumentParser()
          parser.add_argument("--mode", choices=["seed", "merge", "force"], required=True)
          parser.add_argument("--state", required=True)
          parser.add_argument("--declared", required=True)
          args = parser.parse_args()

          declared = load_json(args.declared, [])
          if not isinstance(declared, list):
              print("ding-widgets: la lista declarada no es valida", file=sys.stderr)
              return 1

          exists = os.path.exists(args.state)
          if args.mode == "seed" and exists:
              return 0

          state = load_json(args.state, {"version": 3, "instances": []})
          if not isinstance(state, dict):
              state = {"version": 3, "instances": []}

          existing = state.get("instances", [])
          if not isinstance(existing, list):
              existing = []

          if args.mode == "force":
              instances = declared
          elif args.mode == "seed":
              instances = declared
          else:
              kept = [
                  item
                  for item in existing
                  if isinstance(item, dict)
                  and not str(item.get("instanceId", "")).startswith("decl-")
              ]
              instances = kept + declared

          parent = os.path.dirname(args.state)
          if parent:
              os.makedirs(parent, exist_ok=True)

          if exists:
              try:
                  shutil.copy2(args.state, args.state + ".bak")
              except OSError:
                  pass

          temporary = args.state + ".tmp"
          with open(temporary, "w", encoding="utf-8") as handle:
              json.dump({"version": 3, "instances": instances}, handle, ensure_ascii=False, indent=2)
              handle.write("\n")
          os.chmod(temporary, 0o600)
          os.replace(temporary, args.state)
          print(f"ding-widgets: {len(instances)} instancia(s) en {args.state}")

      if __name__ == "__main__":
          raise SystemExit(main())
    '';
  };
in
{
  options.modulos.home.desktop.dingWidgets = {
    enable = lib.mkEnableOption "widgets declarativos de Gtk4 Desktop Icons NG";

    showDesktopWidgets = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Activar la capa de widgets de DING.";
    };

    stateMode = lib.mkOption {
      type = lib.types.enum [
        "seed"
        "merge"
        "force"
      ];
      default = "merge";
      description = ''
        Cómo gestionar widgets.json:
        - seed: solo crear si no existe.
        - merge: reemplazar las instancias decl-* y conservar el resto.
        - force: dejar únicamente las instancias declaradas.
      '';
    };

    instances = lib.mkOption {
      type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
      default = [ ];
      description = "Instancias declaradas de widgets (usar IDs estables decl-*).";
    };

    upstream.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Instalar el set de widgets upstream de DING.";
    };

    widgets = {
      cava.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Instalar el widget Cava Spectrum.";
      };
      nowPlaying.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Instalar el widget Now Playing + Cava.";
      };
      commandDeck.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Instalar el widget Command Deck.";
      };
    };

    commandDeck.actions = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            label = lib.mkOption {
              type = lib.types.str;
              description = "Texto visible del botón.";
            };
            description = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "Descripción mostrada en preferencias.";
            };
            glyph = lib.mkOption {
              type = lib.types.str;
              default = "•";
              description = "Símbolo o emoji del botón.";
            };
            command = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "Comando y argumentos. No se ejecuta mediante shell.";
            };
            mode = lib.mkOption {
              type = lib.types.enum [
                "background"
                "terminal"
              ];
              default = "background";
              description = "Ejecutar en segundo plano o abrir una terminal.";
            };
            confirm = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Pedir confirmación antes de ejecutar.";
            };
            notify = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enviar notificación al terminar.";
            };
            showOutput = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Mostrar stdout/stderr en el widget.";
            };
          };
        }
      );
      default = {
        rebuild = {
          label = "Rebuild";
          description = "Reconstruir y activar NixOS (abre una terminal).";
          glyph = "⟳";
          command = [
            "${pkgs.kitty}/bin/kitty"
            "--"
            "${pkgs.zsh}/bin/zsh"
            "-ic"
            "rebuild"
          ];
          mode = "terminal";
          confirm = true;
        };
        gwal-random = {
          label = "Wallpaper aleatorio";
          description = "Elegir un fondo de pantalla aleatorio con gwal.";
          glyph = "✦";
          command = [
            "${config.home.profileDirectory}/bin/gwal"
            "--random"
          ];
        };
        gwal-pick = {
          label = "Elegir wallpaper";
          description = "Abrir el selector de gwal.";
          glyph = "▣";
          command = [
            "${config.home.profileDirectory}/bin/gwal"
            "--pick"
          ];
        };
        gwal-clear = {
          label = "Reset wallpapers";
          description = "Reiniciar el historial de gwal.";
          glyph = "↺";
          command = [
            "${config.home.profileDirectory}/bin/gwal"
            "--clear"
          ];
        };
        ordenar = {
          label = "Ordenar Descargas";
          description = "Clasificar Descargas por extensión.";
          glyph = "⇣";
          command = [ "${config.home.profileDirectory}/bin/ordenar" ];
          confirm = true;
        };
        desordenar = {
          label = "Desordenar Descargas";
          description = "Revertir la clasificación de Descargas.";
          glyph = "⇡";
          command = [ "${config.home.profileDirectory}/bin/desordenar" ];
          confirm = true;
        };
        home-audit = {
          label = "Auditar home";
          description = "Mostrar qué entradas cuarentenaría el enforcement.";
          glyph = "⌂";
          command = [ "home-audit" ];
          showOutput = true;
        };
      };
      description = "Catálogo de acciones del Command Deck.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Paquetes adicionales que instalan widgets.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.python3
      pkgs.cava
      pkgs.playerctl
      pkgs.libnotify
    ]
    ++ lib.optional cfg.upstream.enable upstreamWidgets
    ++ lib.optional cfg.widgets.cava.enable cavaWidget
    ++ lib.optional cfg.widgets.nowPlaying.enable nowPlayingWidget
    ++ lib.optional cfg.widgets.commandDeck.enable commandDeckWidget
    ++ cfg.extraPackages;

    dconf.settings."org/gnome/shell/extensions/gtk4-ding" = {
      show-desktop-widgets = cfg.showDesktopWidgets;
    };

    home.activation.dingWidgets = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${mergeScript} \
        --mode ${cfg.stateMode} \
        --state ${lib.escapeShellArg stateFile} \
        --declared ${declaredFile}
    '';
  };
}
