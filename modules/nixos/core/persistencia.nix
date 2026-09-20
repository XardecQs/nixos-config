{ lib, config, ... }:
let
  cfg = config.modulos.persistencia;
  user = config.modulos.nixos.core.users.primaryUser;

  mkFileEntry =
    f:
    if f == "/etc/machine-id" then
      {
        file = f;
        inInitrd = true;
      }
    else
      f;
in
{
  options.modulos.persistencia = {
    enable = lib.mkEnableOption "persistencia";

    sistema = {
      directories = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };

      files = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
    };

    usuarios = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            directories = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
            files = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
          };
        }
      );
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

    modulos.persistencia = {
      sistema = {
        directories = [ "/var/lib/bluetooth" ];
        files = [ "/etc/machine-id" ];
      };

      usuarios.${user} = {
        directories = [
          ".local/share/zinit"
          ".local/share/zoxide"
          ".local/state/zsh"
          ".local/share/Trash"
          ".config/btop"
          ".config/Code"
          ".config/GitHub Desktop"
          ".config/gh"
          ".local/share/nvim"
          ".vscode"
          ".local/share/applications"
          ".config/librewolf"
          ".config/libresprite"
          ".local/share/SMB1R"
          ".local/share/ElyPrismLauncher"
          ".config/opencode"
          ".local/share/opencode"
          ".cache/opencode"
          ".local/share/TwilitRealm"
        ];
      };
    };

    preservation = {
      enable = true;
      preserveAt."/persist" = {
        commonMountOptions = [ "x-gvfs-hide" ];
        directories = cfg.sistema.directories;
        files = map mkFileEntry cfg.sistema.files;
        users = lib.mapAttrs (_: uCfg: {
          directories = uCfg.directories;
          files = uCfg.files;
        }) cfg.usuarios;
      };
    };
  };
}
