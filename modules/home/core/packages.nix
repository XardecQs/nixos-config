{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.home.core.packages;
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
      unstable.fastfetch
      gdu
      yazi
      home-manager
      p7zip

      kitty
      github-desktop

      unstable.libresprite
      inkscape

      binutils
      gnumake
      cmake
      nodejs
      python3
      nixfmt
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
      dusklight
      librewolf
      cage
      onlyoffice-desktopeditors
      varia
    ];
    programs.git = {
      enable = true;
      settings = {
        user = {
          name = "XardecQs";
          email = "126134158+XardecQs@users.noreply.github.com";
        };
        url."git@github.com:".insteadOf = "https://github.com/";
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
      };
    };
  };
}
