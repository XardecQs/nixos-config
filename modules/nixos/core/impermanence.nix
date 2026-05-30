{ lib, config, ... }:
let
  cfg = config.modulos.nixos.core.impermanence;
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
      users.xardec = {
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
          ".local/share/nvim"
          ".vscode"
          ".local/share/applications"
          ".config/librewolf"
          ".local/state/syncthing"
          ".config/libresprite"
          ".config/retroarch"
          ".local/share/SMB1R"
          ".local/share/ElyPrismLauncher"
          ".config/opencode"
          ".local/share/opencode"
          ".cache/opencode"
        ];
        files = [ ];
      };
    };
  };
}
