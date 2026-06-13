{ lib, config, ... }:
let
  cfg = config.modulos.home.apps.flatpak;
in
{
  options.modulos.home.apps.flatpak = {
    enable = lib.mkEnableOption "flatpak";
  };

  config = lib.mkIf cfg.enable {
    services.flatpak = {
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
        #"org.onlyoffice.desktopeditors"
        "com.github.jeromerobert.pdfarranger"
        "io.github.Querz.mcaselector"
        "com.usebottles.bottles"
        "net.retrodeck.retrodeck"
        "org.kde.krita"
        "page.codeberg.JakobDev.jdNBTExplorer"
        #"org.gnome.Builder"
        #"re.sonny.Workbench"
        #"org.gnome.design.Contrast"
        #"org.gnome.design.IconLibrary"
        #"app.drey.Elastic"
        #"re.fossplant.songrec"
      ];
    };
  };
}
