{
  pkgs,
  ...
}:
{
  hostname = "NeoReaper";
  users = [ "xardec" ];

  # Rutas de host que consumen los módulos de usuario.
  gwal.directorio = "/storage/lab-hdd/Fondos de pantalla";

  # Overrides de home-manager específicos de este host/usuario.
  homeOverrides.xardec = {
    # Tras el fixup de pines de ALC294, deja el micrófono interno con un nivel
    # razonable y sin el boost máximo que amplificaba el ruido.
    systemd.user.services.alc294-mic = {
      Unit = {
        Description = "Ajustar micrófono interno ALC294 (ASUS X542UA)";
        After = [ "wireplumber.service" ];
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        # WirePlumber mapea el volumen del source al boost/captura del codec:
        # 0.25 => boost 0 (sin amplificar el ruido) y captura ~54.
        # Se fija el source físico por nombre para que EasyEffects pueda ser el
        # source por defecto sin que este ajuste caiga en el nodo virtual.
        ExecStart = "${pkgs.writeShellScript "alc294-mic" ''
          id=$(${pkgs.wireplumber}/bin/wpctl status -n 2>/dev/null | ${pkgs.gawk}/bin/awk '
            /Sources:/ { in_sources = 1; next }
            /Filters:/ { in_sources = 0 }
            in_sources && /alsa_input\.pci-0000_00_1f\.3\.analog-stereo/ {
              match($0, /[0-9]+\./)
              print substr($0, RSTART, RLENGTH - 1)
              exit
            }
          ')
          if [ -n "$id" ]; then
            ${pkgs.wireplumber}/bin/wpctl set-mute "$id" 0 >/dev/null 2>&1 || true
            ${pkgs.wireplumber}/bin/wpctl set-volume "$id" 0.25 >/dev/null 2>&1 || true
          else
            ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0 >/dev/null 2>&1 || true
            ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 0.25 >/dev/null 2>&1 || true
          fi
        ''}";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };

  modulos = {
    nixos = {
      persistencia = {
        enable = true;
        rollbackRoot = {
          enable = true;
          device = "/dev/mapper/DecryptedSystem";
        };
      };

      homeEstado = {
        enable = true;
        user = "xardec";
        dryRun = false;
        # La allowlist vive en users/xardec/home-allowlist.nix (la inyecta el flake).
      };

      core = {
        boot = {
          enable = true;
          kernelPackage = pkgs.linuxPackages_latest;
        };
        fonts.enable = true;
        general.enable = true;
        locate.enable = true;
        nix.enable = true;
        security.enable = true;
        users = {
          enable = true;
          admin = "xardec";
          adminDescription = "Xavier Del Piero";
        };
      };

      hardware = {
        intel-gpu.enable = true;
        energia.enable = true;
      };

      desktop = {
        display-manager.enable = true;
        obs.enable = true;
        pipewire.enable = true;
        steam.enable = true;
        systemPackages.enable = true;
      };

      services = {
        arduino.enable = true;
        keyd = {
          enable = true;
          mouse.enable = true;
        };
        networking.enable = true;
        printing.enable = true;
        sshd.enable = true;
        virtualisation.enable = true;
        waydroid = {
          enable = true;
          debloat.enable = true;
        };
      };
    };

    compartidos = {
      gnome.enable = true;
      flatpak.enable = true;
    };
  };
}
