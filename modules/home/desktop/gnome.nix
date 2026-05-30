{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.home.desktop.gnome;
in
{
  options.modulos.home.desktop.gnome = {
    enable = lib.mkEnableOption "gnome";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      gnomeExtensions.gsconnect
      gnomeExtensions.blur-my-shell
      gnomeExtensions.dash-to-dock
      gnomeExtensions.user-themes
      gnomeExtensions.rounded-window-corners-reborn
      gnomeExtensions.fullscreen-hot-corner
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.caffeine
      gnomeExtensions.tray-icons-reloaded
      gnomeExtensions.emoji-copy
      gnomeExtensions.logo-menu
      unstable.gnomeExtensions.maximize-window-into-new-workspace
      gnomeExtensions.night-theme-switcher
      gnomeExtensions.boost-volume

      gnome-tweaks
      gnome-extension-manager
      dconf-editor
      nautilus-python
      ffmpegthumbnailer

      adw-gtk3
      marble-shell-theme
      papirus-icon-theme
      zenity
      resources
      gthumb

      albert
    ];

    gtk = {
      enable = true;
      cursorTheme.name = "macos-tahoe-cursor";
      font.name = "SF Pro Display";
    };

    qt = {
      enable = true;
      platformTheme.name = "adwaita";
      style = {
        name = "Adwaita-dark";
        package = pkgs.adwaita-qt6;
      };
    };

    services.gnome-keyring.enable = true;

    dconf.settings = {
      "org/gnome/desktop/privacy" = {
        remember-recent-files = false;
      };

      "org/gnome/desktop/datetime" = {
        automatic-timezone = true;
      };

      "org/gnome/desktop/interface" = {
        clock-format = "12h";
        color-scheme = "prefer-dark";
        cursor-theme = "macos-tahoe-cursor";
        font-name = "SF Pro Display 11";
        gtk-theme = "adw-gtk3-dark";
        icon-theme = "definitivo";
        show-battery-percentage = true;
      };

      "org/gnome/desktop/wm/preferences" = {
        auto-raise = false;
        button-layout = "appmenu:minimize,maximize,close";
        focus-mode = "mouse";
      };

      "org/gnome/shell/extensions/dash-to-dock" = {
        apply-custom-theme = true;
        background-opacity = 0.8;
        dash-max-icon-size = 56;
        disable-overview-on-startup = true;
        dock-position = "BOTTOM";
        height-fraction = 0.9;
        hot-keys = false;
        preferred-monitor = -2;
        preferred-monitor-by-connector = "eDP-1";
        show-apps-at-top = true;
      };

      "org/gnome/shell/extensions/Logo-menu" = {
        hide-forcequit = false;
        hide-icon-shadow = false;
        hide-softwarecentre = true;
        menu-button-icon-image = 23;
        menu-button-icon-size = 18;
        menu-button-system-monitor = "resources";
        menu-button-terminal = "kitty";
        show-lockscreen = false;
        symbolic-icon = true;
        use-custom-icon = false;
      };

      "org/gnome/shell" = {
        enabled-extensions = with pkgs.gnomeExtensions; [
          dash-to-dock.extensionUuid
          show-desktop-button.extensionUuid
          user-themes.extensionUuid
          gsconnect.extensionUuid
          blur-my-shell.extensionUuid
          rounded-window-corners-reborn.extensionUuid
          clipboard-indicator.extensionUuid
          fullscreen-hot-corner.extensionUuid
          caffeine.extensionUuid
          tray-icons-reloaded.extensionUuid
          emoji-copy.extensionUuid
          logo-menu.extensionUuid
          "MaximizeWindowIntoNewWorkspace@kyleross.com"
          night-theme-switcher.extensionUuid
          boost-volume.extensionUuid
        ];
      };

      "org/gnome/shell/extensions/user-theme" = {
        name = "Marble-blue-dark";
      };

      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/"
        ];
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        name = "Open Kitty";
        command = "kitty";
        binding = "<Super>q";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        name = "Open Nautilus";
        command = "nautilus";
        binding = "<Super>e";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
        name = "Wallpaper aleatorio";
        command = "${config.home.homeDirectory}/Proyectos/Scripts/rust/gwal/target/release/gwal --random";
        binding = "<Super><Shift>w";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
        binding = "<Super>space";
        command = ''bash -c 'if pgrep -x ".albert-wrapped" >/dev/null; then albert toggle; else albert --platform xcb & while ! pgrep -x ".albert-wrapped" >/dev/null && ((c++<20)); do sleep 0.6; done; albert toggle; fi' '';
        name = "albert toggle";
      };

      "org/gnome/shell/keybindings" = {
        switch-to-application-1 = [ ];
        switch-to-application-2 = [ ];
        switch-to-application-3 = [ ];
        switch-to-application-4 = [ ];
        switch-to-application-5 = [ ];
        switch-to-application-6 = [ ];
        switch-to-application-7 = [ ];
        switch-to-application-8 = [ ];
        switch-to-application-9 = [ ];
      };

      "org/gnome/desktop/wm/keybindings" = {
        switch-input-source = [ ];
        switch-input-source-backward = [ ];
        close = [ "<Super>c" ];
        toggle-fullscreen = [ "<Super>f" ];
        switch-to-workspace-1 = [ "<Super>1" ];
        switch-to-workspace-2 = [ "<Super>2" ];
        switch-to-workspace-3 = [ "<Super>3" ];
        switch-to-workspace-4 = [ "<Super>4" ];
        switch-to-workspace-5 = [ "<Super>5" ];
        switch-to-workspace-6 = [ "<Super>6" ];
        switch-to-workspace-7 = [ "<Super>7" ];
        switch-to-workspace-8 = [ "<Super>8" ];
        switch-to-workspace-9 = [ "<Super>9" ];
        move-to-workspace-1 = [ "<Super><Shift>1" ];
        move-to-workspace-2 = [ "<Super><Shift>2" ];
        move-to-workspace-3 = [ "<Super><Shift>3" ];
        move-to-workspace-4 = [ "<Super><Shift>4" ];
        move-to-workspace-5 = [ "<Super><Shift>5" ];
        move-to-workspace-6 = [ "<Super><Shift>6" ];
        move-to-workspace-7 = [ "<Super><Shift>7" ];
        move-to-workspace-8 = [ "<Super><Shift>8" ];
        move-to-workspace-9 = [ "<Super><Shift>9" ];
      };
    };
  };
}
