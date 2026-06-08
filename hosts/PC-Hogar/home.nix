{ pkgs, primaryUser, ... }:
{
  imports = [
    ./../../modules/home
  ];

  home = {
    stateVersion = "25.11";
    username = primaryUser;
    homeDirectory = "/home/${primaryUser}";

    packages = with pkgs; [
      gcc
      git
      gnumake
      imagemagick
      nodejs
      pciutils
      python3
      pywal16
      ripgrep
      rofi
      usbutils
    ];
  };

  modulos = {
    home = {
      core = {
        dotfiles = {
          nvim.enable = true;
          zsh.enable = true;
          tmux.enable = true;
          xdgUserDirs.enable = true;
        };
        packages.enable = false;
      };
      desktop = {
        gnome.enable = false;
        spicetify.enable = false;
        obs.enable = false;
      };
      apps = {
        flatpak.enable = false;
        java.enable = false;
        syncthing.enable = false;
        lan-mouse.enable = false;
      };
    };
  };
}
