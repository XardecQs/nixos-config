{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.modulos.nixos.desktop.steam;

  gamescopeScripts = pkgs.symlinkJoin {
    name = "gamescope-steamos-scripts";
    paths = [

      (pkgs.writeShellScriptBin "gamescope-session" ''
        export XKB_DEFAULT_LAYOUT=latam
        export XKB_DEFAULT_VARIANT=""
        export WLR_NO_HARDWARE_CURSORS=1
        export INTEL_DEBUG=norbc
        MANGOAPP_FLAG=""
        if command -v mangoapp &> /dev/null; then
          MANGOAPP_FLAG="--mangoapp"
        else
          printf "[%s] [Info] 'mangoapp' no disponible. Continuando sin --mangoapp.\n" "$0"
        fi
        ${pkgs.gamescope}/bin/gamescope -e \
          $MANGOAPP_FLAG \
          --force-grab-cursor \
          --expose-wayland \
          --adaptive-sync \
          --immediate-flips \
          --rt \
          -r 60 \
          -- steam -steamdeck -steamos3 -shutdown-on-exit
      '')

      (pkgs.writeShellScriptBin "jupiter-biosupdate" ''
        echo "No updates configured for this bios"
        exit 0
      '')

      (pkgs.writeShellScriptBin "steamos-update" ''
        exit 7
      '')

      (pkgs.writeShellScriptBin "steamos-select-branch" ''
        echo "Not applicable for this OS"
      '')

      (pkgs.writeShellScriptBin "steamos-session-select" ''
        steam -shutdown
      '')

    ];
  };

  polkitHelpers = pkgs.runCommand "steamos-polkit-helpers" { } ''
    mkdir -p $out/bin/steamos-polkit-helpers

    cat > $out/bin/steamos-polkit-helpers/jupiter-biosupdate << 'EOF'
    #!/bin/sh
    set -eu
    exec jupiter-biosupdate "$0"
    EOF

    cat > $out/bin/steamos-polkit-helpers/steamos-set-timezone << 'EOF'
    #!/bin/sh
    exit 0
    EOF

    cat > $out/bin/steamos-polkit-helpers/steamos-update << 'EOF'
    #!/bin/sh
    set -eu
    exec steamos-update "$0"
    EOF

    chmod 755 $out/bin/steamos-polkit-helpers/*
  '';

  steamDesktop = pkgs.writeTextFile {
    name = "steam-gamescope-session";
    text = ''
      [Desktop Entry]
      Encoding=UTF-8
      Name=Steam (Gamescope)
      Comment=Run Steam directly in Gamescope
      Exec=gamescope-session
      Type=Application
      DesktopNames=gamescope
    '';
    destination = "/share/wayland-sessions/steam.desktop";

    passthru.providedSessions = [ "steam" ];
  };

in
{
  options.modulos.nixos.desktop.steam = {
    enable = lib.mkEnableOption "steam";
  };

  config = lib.mkIf cfg.enable {

    programs = {
      steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
      };
      gamemode.enable = true;
      gamescope.enable = true;
    };

    environment.systemPackages = with pkgs; [
      mangohud
      brightnessctl
      gamescopeScripts
      polkitHelpers
    ];

    services.displayManager.sessionPackages = [ steamDesktop ];

    system.activationScripts.stealosPolkitLink = ''
      mkdir -p /usr/bin
      ln -sfn /run/current-system/sw/bin/steamos-polkit-helpers \
               /usr/bin/steamos-polkit-helpers
    '';

    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="*", RUN+="${pkgs.coreutils}/bin/chmod a+rw /sys/class/backlight/%k/brightness"
      ACTION=="change", SUBSYSTEM=="backlight", KERNEL=="*", RUN+="${pkgs.coreutils}/bin/chmod a+rw /sys/class/backlight/%k/brightness"
    '';

    environment.persistence."/persist" = lib.mkIf config.modulos.nixos.core.impermanence.enable {
      users.${config.modulos.nixos.core.users.primaryUser}.directories = [
        ".local/share/Steam"
        ".steam"
      ];
    };
  };
}
