{
  config,
  ...
}:
{

  mares = {
    proxy = {
      domain = "mares.id";
    };
    nodes = {
      atuin-01 = {
        roles = [ config.flake.nixosModules.role-atuin-server ];
        host = "10.10.22.247";

        proxy = {
          port = 8888;
          subdomains = [ "atuin" ];
        };
      };

      build-01 = {
        roles = [ config.flake.nixosModules.role-proxmox-builder ];
        host = "10.10.22.122";
      };

      build-02 = {
        roles = [
          config.flake.nixosModules.role-proxmox-arm
        ];
        host = "10.10.22.201";
        system = "aarch64-linux";
      };

      dns-01 = {
        roles = [
          config.flake.nixosModules.role-dns
          config.flake.nixosModules.role-proxmox-legacy
        ];
        host = "10.10.22.163";

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
          config.flake.nixosModules.role-db
        ];
        host = "10.10.22.102";
      };

      starr-sabnzbd-01 = {
        roles = [
          config.flake.nixosModules.role-starr-sabnzbd
          config.flake.nixosModules.role-proxmox-legacy
        ];
        host = "10.10.22.233";

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
      };

      starr-jellyfin-01 = {
        roles = [
          config.flake.nixosModules.role-starr-jellyfin
          config.flake.nixosModules.role-proxmox-legacy
        ];
        host = "10.10.22.211";

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
      };

      nvr-client-02 = {
        roles = [
          config.flake.nixosModules.role-scrypted-client-tensorflow
        ];
        host = "192.168.30.211";
      };

      #
      # Unmanaged nodes
      #
      unifi = {
        managed = false;

        host = "192.168.1.1";

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

        proxy = {
          port = 80;
          websockets = true;
        };
      };

      pve-01 = {
        managed = false;

        host = "192.168.20.21";

        proxy = {
          port = 8006;
          protocol = "https";
          websockets = true;
        };
      };

      pve-02 = {
        managed = false;

        host = "192.168.20.93";

        proxy = {
          port = 8006;
          protocol = "https";
          websockets = true;
        };
      };
    };
  };
}
