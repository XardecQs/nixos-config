{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

let
  elyWrapped = pkgs.symlinkJoin {
    name = "elyprismlauncher-wrapped";
    paths = [ inputs.elyprismlauncher.packages.${pkgs.system}.default ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/elyprismlauncher \
        --prefix XDG_DATA_DIRS : "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}" \
        --prefix XDG_DATA_DIRS : "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
    '';
  };
in
{
  options.modulos.home-manager.packages.enable = lib.mkEnableOption "packages";

  config = lib.mkIf config.modulos.home-manager.packages.enable {
    home.packages = with pkgs; [

      # CLI & Utilidades
      git
      gh
      wget
      bat
      btop
      fzf
      fd
      unzip
      unimatrix
      tmux
      jp2a
      libicns
      zoxide
      lsd
      fastfetch
      gdu
      yazi
      home-manager
      p7zip

      # Aplicaciones de escritorio
      kitty
      github-desktop

      # Multimedia
      #inkscape
      #unstable.audacity
      unstable.libresprite
      #blender
      #losslesscut-bin
      #cava
      #youtube-music
      #easyeffects

      # Desarrollo
      binutils
      gnumake
      cmake
      nodejs
      python3
      nixfmt-rfc-style
      texliveFull
      cargo
      rust-analyzer
      rustfmt
      clippy
      pkg-config
      openssl
      gcc
      rustc
      glibc.static
      upx
      #arduino
      #arduino-cli
      unstable.vscode
      #unstable.godot
      ffmpeg-full

      # Sistema y virtualización
      #podman
      #distrobox
      #virt-manager
      #virt-viewer
      #spice
      #spice-gtk
      #spice-protocol
      #virtio-win
      #win-spice
      #freerdp
      #qemu
      #libvirt
      #swtpm
      #realcugan-ncnn-vulkan
      #realesrgan-ncnn-vulkan
      #android-tools
      #alsa-utils
      #desktop-file-utils
      #appimage-run
      #hardinfo2
      #gamemode
      #mangohud

      # Gaming
      #wineWowPackages.stableFull
      #winetricks
      protonup-ng
      elyWrapped
      (inputs.dusk.packages.${pkgs.system}.default.overrideAttrs (old: {
        NIX_CFLAGS_COMPILE = (old.NIX_CFLAGS_COMPILE or "") + " -march=x86-64-v3 -mtune=generic";
        NIX_CXXFLAGS_COMPILE = (old.NIX_CXXFLAGS_COMPILE or "") + " -march=x86-64-v3 -mtune=generic";
      }))
      librewolf

      # Comunicación y misc
      #qbittorrent
      #peazip

      #hydralauncher

    ];
  };
}
