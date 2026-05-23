{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.modulos.nixos.services.servidor;
in
{
  options.modulos.nixos.services.servidor = {
    enable = lib.mkEnableOption "servidor";
  };

  config = lib.mkIf cfg.enable {

    networking = {
      interfaces.enp3s0.ipv4.addresses = [
        {
          address = "192.168.1.199";
          prefixLength = 24;
        }
      ];
      defaultGateway = "192.168.1.1";
      nameservers = [
        "192.168.1.1"
        "8.8.8.8"
      ];

      firewall = {
        enable = true;
        allowedTCPPorts = [
          22
          445
          139
          5212
          8096
        ];
        allowedUDPPorts = [
          137
          138
          5353
        ];
      };
    };

    services = {
      auto-cpufreq = {
        enable = true;
        settings.charger = {
          governor = "powersave";
          turbo = "never";
        };
      };

      tlp = {
        enable = true;
        settings = {
          CPU_SCALING_GOVERNOR_ON_AC = "powersave";
          DISK_IDLE_SECS_ON_AC = 60;
          USB_AUTOSUSPEND = 1;
        };
      };

      power-profiles-daemon.enable = false;
      thermald.enable = true;
      upower.enable = true;

      btrfs.autoScrub = {
        enable = true;
        interval = "weekly";
      };
    };

    services = {
      openssh = {
        enable = true;
        settings.PermitRootLogin = "no";
      };

      avahi = {
        enable = true;
        nssmdns4 = true;
        publish = {
          enable = true;
          userServices = true;
        };
      };

      samba-wsdd.enable = true;

      samba = {
        enable = true;
        openFirewall = false;
        settings = {
          global = {
            security = "user";
            workgroup = "WORKGROUP";
            "server string" = "Servidor NixOS";
            "map to guest" = "never";
          };
          archivos = {
            path = "/srv/archivos";
            browseable = "yes";
            "read only" = "no";
            "guest ok" = "no";
            "create mask" = "0644";
            "directory mask" = "0755";
            "valid users" = "@users";
          };
        };
      };
    };

    virtualisation = {
      podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
        autoPrune.enable = true;
        autoPrune.dates = "weekly";
      };

      oci-containers.backend = "podman";
      oci-containers.containers = {
        aria2 = {
          image = "p3terx/aria2-pro:latest";
          volumes = [
            "/srv/cloudreve/uploads:/data:rw"
            "/srv/aria2/config:/config:rw"
          ];
          environment = {
            PUID = "0";
            PGID = "0";
            UMASK_SET = "022";
            RPC_SECRET = "cloudreve-aria2-secret";
          };
          extraOptions = [ "--network=host" ];
          autoStart = true;
        };

        cloudreve = {
          image = "cloudreve/cloudreve:latest";
          volumes = [
            "/srv/cloudreve/uploads:/cloudreve/uploads:rw"
            "/srv/cloudreve/data:/cloudreve/data:rw"
            "/srv/cloudreve/conf:/cloudreve/conf:rw"
          ];
          dependsOn = [ "aria2" ];
          extraOptions = [ "--network=host" ];
          autoStart = true;
        };

        jellyfin = {
          image = "jellyfin/jellyfin:latest";
          volumes = [
            "/srv/jellyfin/config:/config:rw"
            "/srv/jellyfin/cache:/cache:rw"
            "/srv/archivos:/media:ro"
          ];
          extraOptions = [
            "--network=host"
            "--device=/dev/dri/renderD128:/dev/dri/renderD128"
          ];
          autoStart = true;
        };
      };
    };

    environment.systemPackages = with pkgs; [
      htop
      powertop
      git
      vim
      pciutils
    ];

    systemd.tmpfiles.rules = [
      "d /srv/archivos 0755 root users -"
      "d /srv/config 0755 root users -"
      "d /srv/cloudreve 0755 root users -"
      "d /srv/cloudreve/uploads 0755 root users -"
      "d /srv/cloudreve/conf 0755 root users -"
      "d /srv/cloudreve/data 0755 root users -"
      "d /srv/aria2 0755 root users -"
      "d /srv/aria2/config 0755 root users -"
      "d /srv/jellyfin 0755 root users -"
      "d /srv/jellyfin/config 0755 root users -"
      "d /srv/jellyfin/cache 0755 root users -"
    ];

    security.wrappers.beep = {
      owner = "root";
      group = "wheel";
      source = "${pkgs.beep}/bin/beep";
      permissions = "u+rs,g+rs,o+rx";
    };

    systemd.services.boot-beep = {
      description = "Beep when system is ready";
      after = [
        "multi-user.target"
        "network-online.target"
        "sshd.service"
      ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        RemainAfterExit = false;
      };
      script = ''
        sleep 3
        ${pkgs.beep}/bin/beep -f 1000 -l 200 -r 3 -D 100 2>/dev/null || true
      '';
    };

    services.logind.settings = {
      Login = {
        HandlePowerKey = "poweroff";
        PowerKeyIgnoreInhibited = "yes";
      };
    };
  };
}
