{ host, ... }:
{
  modulos.home = {
    core = {
      dotfiles = {
        enable = true;
        nvim.enable = true;
        kitty.enable = true;
        fastfetch.enable = true;
        tmux.enable = true;
        albert.enable = true;
        code.enable = true;
        xdgUserDirs.enable = true;
      };
      packages.enable = true;
      zsh.enable = true;
    };

    desktop = {
      gwal = {
        enable = true;
        directorio = host.gwal.directorio;
      };
    };

    apps = {
      syncthing.enable = true;
      retroarch.enable = true;
      gta-mo.enable = true;
      elyprismlauncher.enable = true;
    };
  };
}
