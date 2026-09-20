{
  config,
  lib,
  ...
}:
let
  cfg = config.modulos.nixos.desktop.display-manager;
in
{
  options.modulos.nixos.desktop.display-manager = {
    enable = lib.mkEnableOption "gestión centralizada del display manager";
    backend = lib.mkOption {
      type = lib.types.enum [
        "gdm"
        "ly"
        "sddm"
        "none"
      ];
      default = "gdm";
      description = "Display manager a usar (gdm, ly, sddm, none)";
    };
    autoLogin = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Activar autologin con el usuario primario";
    };
  };

  config = lib.mkIf cfg.enable {
    services.displayManager = lib.mkMerge [
      {
        gdm.enable = cfg.backend == "gdm";
        ly.enable = cfg.backend == "ly";
        sddm.enable = cfg.backend == "sddm";
        autoLogin = lib.mkIf cfg.autoLogin {
          enable = true;
          user = config.modulos.nixos.core.users.primaryUser;
        };
      }
    ];
  };
}
