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
        roles = [ config.flake.nixosModules.role-atuin-server ];
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
        roles = [ config.flake.nixosModules.role-proxmox-builder ];
        host = "10.10.22.122";

        dns = {
          vlan = "vm";
        };
      };

      build-02 = {
        roles = [
          config.flake.nixosModules.role-proxmox-arm
        ];
        host = "10.10.22.201";
        system = "aarch64-linux";

        dns = {
          vlan = "vm";
        };
      };

      dns-01 = {
        roles = [
          config.flake.nixosModules.role-dns
          config.flake.nixosModules.role-proxmox-legacy
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
        roles = [
          config.flake.nixosModules.role-dns
          config.flake.nixosModules.role-proxmox-legacy
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

      proxy-01 = {
        roles = [
          config.flake.nixosModules.role-proxy
          config.flake.nixosModules.role-proxmox-legacy
        ];
        host = "10.10.22.103";
      };

      db-01 = {
        roles = [
          config.flake.nixosModules.role-postgres
          config.flake.nixosModules.role-postgres-backup
        ];

        dns = {
          vlan = "vm";
        };

        host = "10.10.22.102";
      };

      starr-sabnzbd-01 = {
        roles = [
          config.flake.nixosModules.role-starr-sabnzbd
          config.flake.nixosModules.role-proxmox-legacy
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
        roles = [
          config.flake.nixosModules.role-starr-prowlarr
          config.flake.nixosModules.role-proxmox-legacy
        ];
        host = "10.10.22.147";

        proxy = {
          port = 9696;
          subdomains = [ "prowlarr" ];
          websockets = true;
        };
      };

      starr-radarr-01 = {
        roles = [
          config.flake.nixosModules.role-starr-radarr
          config.flake.nixosModules.role-proxmox-legacy
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
        roles = [
          config.flake.nixosModules.role-starr-sonarr
          config.flake.nixosModules.role-proxmox-legacy
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
        roles = [
          config.flake.nixosModules.role-starr-recyclarr
          config.flake.nixosModules.role-proxmox-legacy
        ];

        host = "10.10.22.115";

        dns = {
          vlan = "vm";
        };
      };

      starr-jellyfin-01 = {
        roles = [
          config.flake.nixosModules.role-starr-jellyfin
          config.flake.nixosModules.role-proxmox-legacy
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
        roles = [
          config.flake.nixosModules.role-starr-jellyseerr
          config.flake.nixosModules.role-proxmox-legacy
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
        roles = [
          config.flake.nixosModules.role-scrypted-server
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
        roles = [
          config.flake.nixosModules.role-scrypted-client-openvino
        ];

        host = "192.168.30.181";

        dns = {
          vlan = "vm";
        };
      };

      nvr-client-02 = {
        roles = [
          config.flake.nixosModules.role-scrypted-client-tensorflow
        ];

        host = "192.168.30.211";

        dns = {
          vlan = "vm";
        };
      };

      #
      # Unmanaged nodes
      #
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
