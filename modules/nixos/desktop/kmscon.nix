{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.nixos.desktop.kmscon;
in
{
  options.modulos.nixos.desktop.kmscon = {
    enable = lib.mkEnableOption "kmscon";
  };

  config = lib.mkIf cfg.enable {
    services.kmscon = {
      enable = true;
      hwRender = true;

      fonts = [
        {
          name = "JetBrainsMono Nerd Font Mono";
          package = pkgs.nerd-fonts.jetbrains-mono;
        }
      ];

      extraConfig = ''
        font-engine=pango
        font-name=JetBrainsMono Nerd Font Mono
        font-size=11
        xkb-layout=latam

        palette=custom

        palette-black=12,12,12
        palette-red=220,60,60
        palette-green=80,220,100
        palette-yellow=230,190,70
        palette-blue=100,160,255
        palette-magenta=200,80,200
        palette-cyan=80,200,190
        palette-light-grey=180,180,180

        palette-dark-grey=90,90,90
        palette-light-red=255,85,85
        palette-light-green=100,255,130
        palette-light-yellow=255,235,120
        palette-light-blue=135,190,255
        palette-light-magenta=240,120,240
        palette-light-cyan=100,255,230
        palette-white=245,245,245

        palette-foreground=220,220,215
        palette-background=8,8,8
      '';
    };
  };
}
