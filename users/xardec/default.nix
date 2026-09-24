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

      iconosCarpetas = {
        enable = true;
        asignaciones = {
          "Documentos" = "folder-documents";
          "Descargas" = "folder-download";
          "Media" = "folder-multimedia";
          "Proyectos" = "folder-projects";
          "Juegos" = "folder-games";
          "Media/Imágenes" = "folder-pictures";
          "Media/Vídeos" = "folder-videos";
          "Media/Música" = "folder-music";
          "Media/Libros" = "folder-books";
          "Media/Mangas" = "folder-manga";
          "Proyectos/GitHub" = "folder-github";
          "Proyectos/Scripts" = "folder-scripts";
          "Proyectos/Local" = "folder-programer";
          "Proyectos/Scripts/rust" = "folder-rust";
          "Proyectos/Scripts/py" = "folder-python";
          "Proyectos/Scripts/MATLAB" = "folder-matlab";
          "Proyectos/Scripts/C" = "folder-c";
          "Documentos/Plantillas" = "folder-templates";
          "Juegos/Minecraft" = "folder-minecraft";
          "Virtualizacion" = "folder-virt";
          "Archivo" = "folder-archive";
        };
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
