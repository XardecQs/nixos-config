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
    home = {
      core = {
        dotfiles = {
          enable = true;
          localPath = "/home/xardec/Proyectos/GitHub/dotfiles";
        };
        packages.enable = true;
      };
      desktop = {
        gnome.enable = true;
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
