{ lib, config, ... }:
let
  cfg = config.modulos.nixos.core.impermanence;
  user = config.modulos.nixos.core.users.primaryUser;
in
{
  options.modulos.nixos.core.impermanence = {
    enable = lib.mkEnableOption "impermanence";
  };

  config = lib.mkIf cfg.enable {
    environment.persistence."/persist" = {
      hideMounts = true;
      allowTrash = true;

      directories = [
        "/var/lib/bluetooth"
      ];
      files = [
        "/etc/machine-id"
      ];
      users.${user} = {
        directories = [
          "Virtualizacion"
          "Descargas"
          "Documentos"
          "Juegos"
          "Media"
          "Proyectos"
          "Trastero"
          ".local/share/zinit"
          ".local/share/zoxide"
          ".local/state/zsh"
          ".config/btop"
          ".config/Code"
          ".config/GitHub Desktop"
          ".config/gh"
          ".local/share/nvim"
          ".vscode"
          ".local/share/applications"
          ".config/librewolf"
          ".local/state/syncthing"
          ".config/libresprite"
          ".local/share/SMB1R"
          ".local/share/ElyPrismLauncher"
          ".config/opencode"
          ".local/share/opencode"
          ".cache/opencode"
          ".local/share/TwilitRealm"
        ];
        files = [ 
        ];
      };
    };
  };
}
