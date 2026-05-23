{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  cfg = config.modulos.home.core.packages;

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
  options.modulos.home.core.packages = {
    enable = lib.mkEnableOption "packages";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [

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

      kitty
      github-desktop

      unstable.libresprite

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
      unstable.vscode
      ffmpeg-full
      opencode

      protonup-ng
      elyWrapped
      (inputs.dusk.packages.${pkgs.system}.default.overrideAttrs (old: {
        NIX_CFLAGS_COMPILE = (old.NIX_CFLAGS_COMPILE or "") + " -march=x86-64-v3 -mtune=generic";
        NIX_CXXFLAGS_COMPILE = (old.NIX_CXXFLAGS_COMPILE or "") + " -march=x86-64-v3 -mtune=generic";
      }))
      librewolf

    ];
  };
}
