{ ... }:
{
  imports = [
    ./../../modules/home
  ];

  home = {
    stateVersion = "25.11";
    username = "xardec";
    homeDirectory = "/home/xardec";
  };

  modulos = {
    home-manager = {
      dotfiles.enable = true;
      flatpak.enable = true;
      gnome.enable = true;
      #java.enable = true;
      #obs.enable = true;
      packages.enable = true;
      #spicetify.enable = true;
      syncthing.enable = true;
      #lan-mouse.enable = true;
      #retroarch.enable = true;
    };
  };
}
