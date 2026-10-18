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
        code.enable = true;
        xdgUserDirs.enable = true;
      };
      packages.enable = true;
      zsh.enable = true;
    };

    desktop = {
      audio.enable = true;
      gnome.enable = true;

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
      artcraft.enable = true;
      obs.enable = true;
      flatpak = {
        enable = true;
        packages = [
          "com.github.tchx84.Flatseal"
          "org.gtk.Gtk3theme.adw-gtk3"
          "com.github.johnfactotum.Foliate"
          "app.zen_browser.zen"
          "md.obsidian.Obsidian"
          "org.gnome.NetworkDisplays"
          "io.gitlab.adhami3310.Converter"
          "fr.handbrake.ghb"
          "org.nickvision.tubeconverter"
          "org.musicbrainz.Picard"
          "org.soundconverter.SoundConverter"
          "com.github.jeromerobert.pdfarranger"
          "io.github.Querz.mcaselector"
          "com.usebottles.bottles"
          "org.kde.krita"
          "page.codeberg.JakobDev.jdNBTExplorer"
          "ar.xjuan.Cambalache"
          "io.mrarm.mcpelauncher"
        ];
      };
      syncthing = {
        enable = true;
        deviceName = "Redmi Note 10 Pro";
        deviceId = "ER73BNF-I5V5D4M-IOITMSU-4JQTRS5-PN7EIPR-3CXF2KN-FMHN3MI-6VIPAAW";
        folders = [
          {
            name = "Kotatsu";
            path = "Media/Mangas/.Kotatsu";
            id = "tovx9-9995f";
          }
          {
            name = "Música";
            path = "Media/Música";
            id = "w9yjz-9kb76";
          }
          {
            name = "Capturas de pantalla";
            path = "Media/Imágenes/Capturas de pantalla";
            id = "7979p-4pjv5";
          }
          {
            name = "ROMs";
            path = "Juegos/ROMs";
            id = "qlb1e-69yh0";
          }
        ];
      };
      retroarch.enable = true;
      gta-mo.enable = true;
      elyprismlauncher.enable = true;
      waydroid.enable = true;

      # Carpetas del host visibles dentro de Android (activar tras `waydroid init`).
      # El destino se ve como /sdcard/<nombre>. Ejemplo:
      # waydroid.carpetasCompartidas = [
      #   {
      #     origen = "/home/xardec/Descargas";
      #     destino = "/home/xardec/.local/share/waydroid/data/media/0/Descargas";
      #   }
      #   {
      #     origen = "/home/xardec/Documentos";
      #     destino = "/home/xardec/.local/share/waydroid/data/media/0/Documentos";
      #   }
      #   {
      #     origen = "/home/xardec/Media";
      #     destino = "/home/xardec/.local/share/waydroid/data/media/0/Media";
      #   }
      # ];
    };
  };
}
