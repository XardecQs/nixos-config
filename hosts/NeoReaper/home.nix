{ primaryUser, ... }:
{
  imports = [
    ./../../modules/home
  ];

  home = {
    stateVersion = "25.11";
    username = primaryUser;
    homeDirectory = "/home/${primaryUser}";
  };

  modulos = {
    home = {
      core = {
        dotfiles = {
          localPath = "/home/${primaryUser}/Proyectos/GitHub/dotfiles";
          nvim.enable = true;
          kitty.enable = true;
          fastfetch.enable = true;
          zsh.enable = true;
          tmux.enable = true;
          alacritty.enable = true;
          waybar.enable = true;
          wal.enable = true;
          wlogout.enable = true;
          albert.enable = true;
          code.enable = true;
          xdgUserDirs.enable = true;
        };
        packages.enable = true;
      };
      desktop = {
        gnome.enable = true;
        #hyprland.enable = true;
        #spicetify.enable = true;
        #obs.enable = true;
      };
      apps = {
        flatpak.enable = true;
        syncthing.enable = true;
        #windows-vm.enable = true;
        #java.enable = true;
        #lan-mouse.enable = true;
        #retroarch.enable = true;
      };
    };
  };
}
