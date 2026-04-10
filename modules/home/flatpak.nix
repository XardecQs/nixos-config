{ lib, config, ... }:
{
  options.modulos.home-manager.flatpak.enable = lib.mkEnableOption "flatpak";

  config = lib.mkIf config.modulos.home-manager.flatpak.enable {
    services = {
      flatpak = {
        enable = true;
        packages = [
          "com.github.tchx84.Flatseal"
          "org.gtk.Gtk3theme.adw-gtk3"
          "com.github.johnfactotum.Foliate"
          "app.zen_browser.zen"
          #"md.obsidian.Obsidian"
          #"net.blockbench.Blockbench"
          "io.gitlab.adhami3310.Converter"
          "fr.handbrake.ghb"
          "org.nickvision.tubeconverter"
          "org.musicbrainz.Picard"
          "org.soundconverter.SoundConverter"
          #"org.kde.kdenlive"
          #"com.github.neithern.g4music"
          #"com.rtosta.zapzap"
          "org.onlyoffice.desktopeditors"
          "com.github.jeromerobert.pdfarranger"
          #"it.mijorus.gearlever"
          "io.github.Querz.mcaselector"
          "com.usebottles.bottles"
          #"net.lutris.Lutris"
          "net.retrodeck.retrodeck"
          "org.kde.krita"
        ];
      };
    };
  };
}
