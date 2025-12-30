{
  config,
  ...
}:
let
  cfg = config.mares.infrastructure;
in
{

  mares.infrastructure = {
    proxy = {
      domain = "mares.id";
    };
    nodes = {
      atuin-01 = {
        tags = [ "infra" ];
        roles = [
          config.flake.nixosModules.role-atuin-server
          config.flake.nixosModules.role-atuin-client
          config.flake.nixosModules.role-monitoring-client
        ];
        host = "10.10.22.247";

        dns = {
          vlan = "vm";
        };

        proxy = {
          port = 8888;
          subdomains = [ "atuin" ];
        };
      };

      build-01 = {
        tags = [ "build" ];
        roles = [
          config.flake.nixosModules.role-proxmox-builder
          config.flake.nixosModules.role-monitoring-client
        ];
        host = "10.10.22.122";

        dns = {
          vlan = "vm";
        };
      };

      build-02 = {
        tags = [ "build" ];
        roles = [
          config.flake.nixosModules.role-proxmox-arm
          config.flake.nixosModules.role-monitoring-client
        ];
        host = "10.10.22.201";
        system = "aarch64-linux";

        dns = {
          vlan = "vm";
        };
      };

      dns-01 = {
        tags = [
          "dns"
          "infra"
        ];
        roles = [
          config.flake.nixosModules.role-dns
          config.flake.nixosModules.role-proxmox-legacy
          config.flake.nixosModules.role-atuin-client
          config.flake.nixosModules.role-monitoring-client
        ];
        host = "10.10.22.163";

        dns = {
          vlan = "vm";
        };

        proxy = {
          port = 3000;
        };
      };

      dns-02 = {
        tags = [
          "dns"
          "infra"
        ];
        roles = [
          config.flake.nixosModules.role-dns
          config.flake.nixosModules.role-proxmox-legacy
          config.flake.nixosModules.role-atuin-client
          config.flake.nixosModules.role-monitoring-client
        ];
        host = "10.10.22.112";
        system = "aarch64-linux";

        dns = {
          vlan = "vm";
        };

        proxy = {
          port = 3000;
        };
      };

      dns-03 = {
        tags = [
          "dns"
          "infra"
          "technitium"
          "technitium-primary"
        ];
        roles = [
          config.flake.nixosModules.role-dns-technitium-primary
          config.flake.nixosModules.role-atuin-client
          config.flake.nixosModules.role-monitoring-client
        ];
        host = "10.10.22.199";

        dns = {
          vlan = "vm";
        };

        proxy = {
          port = 5380;
          subdomains = [ "technitium" ];
        };
      };

      dns-04 = {
        tags = [
          "dns"
          "infra"
          "technitium"
          "technitium-secondary"
        ];
        roles = [
          config.flake.nixosModules.role-dns-technitium-secondary
          config.flake.nixosModules.role-atuin-client
          config.flake.nixosModules.role-monitoring-client
        ];
        host = "10.10.22.225";

        dns = {
          vlan = "vm";
        };
      };

      mon-01 = {
        tags = [ "infra" ];
        roles = [
          config.flake.nixosModules.role-monitoring-server
          config.flake.nixosModules.role-monitoring-pve
          config.flake.nixosModules.role-monitoring-client
          config.flake.nixosModules.role-atuin-client
        ];

        dns = {
          vlan = "vm";
        };

        host = "10.10.22.241";

        proxy = {
          port = 3000;
          subdomains = [ "grafana" ];
          websockets = true;
        };
      };

      proxy-01 = {
        tags = [ "infra" ];
        roles = [
          config.flake.nixosModules.role-proxy
          config.flake.nixosModules.role-proxmox-legacy
          config.flake.nixosModules.role-atuin-client
          config.flake.nixosModules.role-monitoring-client
          config.flake.nixosModules.role-monitoring-nginx
        ];
        host = "10.10.22.103";
      };

      db-01 = {
        tags = [ "infra" ];
        roles = [
          config.flake.nixosModules.role-postgres
          config.flake.nixosModules.role-postgres-backup
          config.flake.nixosModules.role-atuin-client
          config.flake.nixosModules.role-monitoring-client
          config.flake.nixosModules.role-monitoring-postgres
        ];

        dns = {
          vlan = "vm";
        };

        host = "10.10.22.102";
      };

      starr-sabnzbd-01 = {
        tags = [ "starr" ];
        roles = [
          config.flake.nixosModules.role-starr-sabnzbd
          config.flake.nixosModules.role-proxmox-legacy
          config.flake.nixosModules.role-atuin-client
          config.flake.nixosModules.role-monitoring-client
          config.flake.nixosModules.role-monitoring-starr-sabnzbd
        ];
        host = "10.10.22.233";

        dns = {
          vlan = "vm";
        };

        proxy = {
          port = 8080;
          subdomains = [ "sabnzbd" ];
          websockets = true;
        };
      };

      starr-prowlarr-01 = {
        tags = [ "starr" ];
        roles = [
          config.flake.nixosModules.role-starr-prowlarr
          config.flake.nixosModules.role-proxmox-legacy
          config.flake.nixosModules.role-atuin-client
          config.flake.nixosModules.role-monitoring-client
          config.flake.nixosModules.role-monitoring-starr-prowlarr
        ];
        host = "10.10.22.147";

        proxy = {
          port = 9696;
          subdomains = [ "prowlarr" ];
          websockets = true;
        };
      };

      starr-radarr-01 = {
        tags = [ "starr" ];
        roles = [
          config.flake.nixosModules.role-starr-radarr
          config.flake.nixosModules.role-proxmox-legacy
          config.flake.nixosModules.role-atuin-client
          config.flake.nixosModules.role-monitoring-client
          config.flake.nixosModules.role-monitoring-starr-radarr
        ];
        host = "10.10.22.172";

        dns = {
          vlan = "vm";
        };

        proxy = {
          port = 7878;
          subdomains = [ "radarr" ];
          websockets = true;
        };
      };

      starr-sonarr-01 = {
        tags = [ "starr" ];
        roles = [
          config.flake.nixosModules.role-starr-sonarr
          config.flake.nixosModules.role-proxmox-legacy
          config.flake.nixosModules.role-atuin-client
          config.flake.nixosModules.role-monitoring-client
          config.flake.nixosModules.role-monitoring-starr-sonarr
        ];
        host = "10.10.22.235";

        dns = {
          vlan = "vm";
        };

        proxy = {
          port = 8989;
          subdomains = [ "sonarr" ];
          websockets = true;
        };
      };

      starr-recyclarr-01 = {
        tags = [ "starr" ];
        roles = [
          config.flake.nixosModules.role-starr-recyclarr
          config.flake.nixosModules.role-proxmox-legacy
          config.flake.nixosModules.role-atuin-client
          config.flake.nixosModules.role-monitoring-client
        ];

        host = "10.10.22.115";

        dns = {
          vlan = "vm";
        };
      };

      starr-jellyfin-01 = {
        tags = [ "starr" ];
        roles = [
          config.flake.nixosModules.role-starr-jellyfin
          config.flake.nixosModules.role-proxmox-legacy
          config.flake.nixosModules.role-atuin-client
          config.flake.nixosModules.role-monitoring-client
        ];
        host = "10.10.22.211";

        dns = {
          vlan = "vm";
        };

        proxy = {
          port = 8096;
          subdomains = [ "jellyfin" ];
          websockets = true;
        };
      };

      starr-jellyseerr-01 = {
        tags = [ "starr" ];
        roles = [
          config.flake.nixosModules.role-starr-jellyseerr
          config.flake.nixosModules.role-proxmox-legacy
          config.flake.nixosModules.role-atuin-client
          config.flake.nixosModules.role-monitoring-client
        ];

        host = "10.10.22.141";

        dns = {
          vlan = "vm";
        };

        proxy = {
          port = 5055;
          subdomains = [ "jellyseerr" ];
          websockets = true;
        };
      };

      nvr-server-01 = {
        tags = [ "nvr" ];
        roles = [
          config.flake.nixosModules.role-scrypted-server
          config.flake.nixosModules.role-atuin-client
          config.flake.nixosModules.role-monitoring-client
        ];

        host = "192.168.30.229";

        dns = {
          vlan = "vm";
        };

        proxy = {
          port = 38655;
          protocol = "https";
          subdomains = [ "scrypted" ];
          websockets = true;
        };
      };

      nvr-client-01 = {
        tags = [ "nvr" ];
        roles = [
          config.flake.nixosModules.role-scrypted-client-openvino
          config.flake.nixosModules.role-atuin-client
          config.flake.nixosModules.role-monitoring-client
        ];

        host = "192.168.30.181";

        dns = {
          vlan = "vm";
        };
      };

      mqtt-01 = {
        tags = [ "automation" ];
        roles = [
          config.flake.nixosModules.role-mqtt
          config.flake.nixosModules.role-atuin-client
          config.flake.nixosModules.role-monitoring-client
        ];

        host = "10.10.22.227";

        dns = {
          vlan = "vm";
        };
      };

      hass-01 = {
        tags = [ "automation" ];
        roles = [
          config.flake.nixosModules.role-hass
          config.flake.nixosModules.role-atuin-client
          config.flake.nixosModules.role-monitoring-client
        ];

        host = "10.10.22.104";

        dns = {
          vlan = "vm";
        };

        proxy = {
          port = 8123;
          subdomains = [ "ha" ];
          websockets = true;
        };
      };

      unifi = {
        managed = false;

        host = "192.168.1.1";

        dns = {
          vlan = "default";
        };

        proxy = {
          port = 443;
          protocol = "https";
          subdomains = [ "udm" ];
          websockets = true;
        };
      };

      truenas = {
        managed = false;

        host = "10.10.22.10";

        dns = {
          vlan = "vm";
        };

        proxy = {
          port = 80;
          websockets = true;
        };
      };

      pve-01 = {
        managed = false;

        host = "192.168.20.21";

        dns = {
          vlan = "iot";
        };

        proxy = {
          port = 8006;
          subdomains = [ "pve" ];
          protocol = "https";
          websockets = true;
        };
      };

      pve-02 = {
        managed = false;

        host = "192.168.20.93";

        dns = {
          vlan = "iot";
        };

        proxy = {
          port = 8006;
          protocol = "https";
          websockets = true;
        };
      };

      pve-03 = {
        managed = false;

        host = "192.168.20.209";

        dns = {
          vlan = "iot";
        };
      };

      pbs-01 = {
        managed = false;

        host = "10.10.22.40";

        dns = {
          vlan = "vm";
        };

        proxy = {
          port = 8007;
          subdomains = [ "pbs" ];
          protocol = "https";
          websockets = true;
        };
      };
    };
  };

}
