{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  cfg = config.modulos.home.apps.elyprismlauncher;

  elyBase = inputs.elyprismlauncher.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
    additionalLibs = [
      pkgs.wayland
      pkgs.libxkbcommon
      pkgs.libdecor
      pkgs.libxi
      pkgs.libxrender
      pkgs.libxtst
    ];
  };

  elyWrapped = pkgs.symlinkJoin {
    name = "elyprismlauncher-wrapped";
    paths = [
      elyBase
      pkgs.temurin-bin-25
    ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/elyprismlauncher \
        --prefix XDG_DATA_DIRS : "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}" \
        --prefix XDG_DATA_DIRS : "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
    '';
  };
in
{
  options.modulos.home.apps.elyprismlauncher = {
    enable = lib.mkEnableOption "elyprismlauncher (paquete + icono de ventana)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ elyWrapped ];

    # Mutter/GNOME no soporta xdg_toplevel_icon_v1, asi que el icono en runtime
    # del juego se pierde. GNOME asocia la ventana (app_id com.mojang.minecraft)
    # a un .desktop, por eso lo creamos apuntando al icono de Papirus.
    # Nota: se usa home.file en vez de xdg.desktopEntries porque esta ultima
    # rev de home-manager lanza el removed-option de `extraConfig` al evaluar.
    home.file.".local/share/applications/com.mojang.minecraft.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Minecraft
      Comment=Minecraft (ElyPrismLauncher)
      Exec=elyprismlauncher
      Icon=com.mojang.Minecraft
      Categories=Game;
      NoDisplay=true
      StartupWMClass=com.mojang.minecraft
    '';
  };
}
