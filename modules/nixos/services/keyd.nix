{
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.nixos.services.keyd;
in
{
  options.modulos.nixos.services.keyd = {
    enable = lib.mkEnableOption "keyd (remapeo de teclado y mouse)";
    mouse.enable = lib.mkEnableOption "remapeo del mouse USB OPTICAL MOUSE (experimental)";
  };

  config = lib.mkIf cfg.enable {
    services.keyd = {
      enable = true;

      keyboards = {
        hv-kb220bt = {
          ids = [ "04e8:7021" ];

          settings = {
            main = {
              # --- Capa Fn desactivada (solo codigos unicos) ---
              homepage = "noop"; # Fn+Esc
              back = "noop"; # Fn+F1
              mail = "noop"; # Fn+F2
              config = "noop"; # Fn+F4
              search = "noop"; # Fn+F5
              playpause = "noop"; # Fn+F8
              nextsong = "noop"; # Fn+F9
              mute = "noop"; # Fn+F10
              volumedown = "noop"; # Fn+F11
              volumeup = "noop"; # Fn+F12
              brightnessdown = "noop"; # Fn+algo (iOS/Android)
              brightnessup = "noop"; # Fn+algo (iOS/Android)

              # Fn+flechas (Home/PgUp/PgDn/End)
              home = "noop";
              pageup = "noop";
              pagedown = "noop";
              end = "noop";

              # CapsLock: tocar = CapsLock, mantener = capa "extras" (emula Alt)
              capslock = "overload(extras, capslock)";
            };

            # Capa "extras" (mantener CapsLock). ":A" = emula Alt por defecto.
            "extras:A" = {
              # Fila numerica -> F1..F12 (revive F3 y F7)
              "1" = "f1";
              "2" = "f2";
              "3" = "f3";
              "4" = "f4";
              "5" = "f5";
              "6" = "f6";
              "7" = "f7";
              "8" = "f8";
              "9" = "f9";
              "0" = "f10";
              minus = "f11";
              equal = "f12";

              # Flechas -> navegacion
              left = "home";
              right = "end";
              up = "pageup";
              down = "pagedown";

              # Teclas ausentes
              i = "insert";
              p = "print";
              m = "menu";
              s = "pause";
              c = "compose";

              # --- Emoji / simbolos (macros Ctrl+Shift+U, layout-independientes) ---
              e = "macro(C-semicolon)"; # selector de emoji (GNOME Ctrl+;)

              # Flechas estilo Vim
              h = "macro(C-S-u 2 1 9 0 enter)"; # <-
              j = "macro(C-S-u 2 1 9 3 enter)"; # v
              k = "macro(C-S-u 2 1 9 1 enter)"; # ^
              l = "macro(C-S-u 2 1 9 2 enter)"; # ->

              # Moneda / matematicos
              leftbrace = "macro(C-S-u 2 0 a c enter)"; # euro
              rightbrace = "macro(C-S-u 0 0 b 0 enter)"; # grado
              backslash = "macro(C-S-u 0 0 b 1 enter)"; # +/-
              semicolon = "macro(C-S-u 0 0 d 7 enter)"; # x
              apostrophe = "macro(C-S-u 0 0 f 7 enter)"; # /
              comma = "macro(C-S-u 0 0 b d enter)"; # 1/2
              dot = "macro(C-S-u 0 0 b c enter)"; # 1/4
              slash = "macro(C-S-u 0 0 b e enter)"; # 3/4

              # Tipograficos
              grave = "macro(C-S-u 2 0 2 6 enter)"; # ...
              q = "macro(C-S-u 2 0 2 2 enter)"; # bullet
              w = "macro(C-S-u 2 0 1 4 enter)"; # em dash
              r = "macro(C-S-u 2 7 1 3 enter)"; # check
              t = "macro(C-S-u 2 7 1 7 enter)"; # cross
            };
          };
        };
      }
      // lib.optionalAttrs cfg.mouse.enable {
        mouse = {
          ids = [ "m:4e53:5407" ]; # m: = solo raton, no su interfaz "teclado"
          settings.main = {
            # Botones laterales (BTN_SIDE/BTN_EXTRA -> mouse1/mouse2)
            mouse1 = "volumedown";
            mouse2 = "volumeup";
          };
        };
      };
    };
  };
}
