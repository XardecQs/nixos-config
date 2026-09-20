{ lib, config, ... }:
let
  cfg = config.modulos.compartidos.flatpak;
  user = config.modulos.nixos.core.users.primaryUser;
in
{
  options.modulos.compartidos.flatpak = {
    enable = lib.mkEnableOption "flatpak";
    sistema = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Activar servicio Flatpak del sistema y persistencia";
    };
    usuario = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Activar paquetes Flatpak declarativos (nix-flatpak)";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf cfg.sistema {
        services.flatpak.enable = true;
      })

      (lib.mkIf cfg.usuario {
        home-manager.users.${user}.services.flatpak = {
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
            "net.retrodeck.retrodeck"
            "org.kde.krita"
            "page.codeberg.JakobDev.jdNBTExplorer"
            "ar.xjuan.Cambalache"
          ];
        };
      })
    ]
  );
}
