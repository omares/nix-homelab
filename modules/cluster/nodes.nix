{
  config,
  ...
}:
{

  cluster = {
    proxy = {
      domain = "mares.id";
    };
    nodes = {
      build-01 = {
        roles = [ config.flake.nixosModules.role-proxmox-builder ];
        host = "192.168.20.92";
      };

      build-02 = {
        roles = [
          config.flake.nixosModules.role-proxmox-arm
        ];
        host = "192.168.20.46";
        system = "aarch64-linux";
      };

      dns-01 = {
        roles = [
          config.flake.nixosModules.role-dns
          config.flake.nixosModules.role-proxmox-legacy
        ];
        host = "192.168.20.29";

        proxy = {
          port = 3000;
        };
      };

      dns-02 = {
        roles = [
          config.flake.nixosModules.role-dns
          config.flake.nixosModules.role-proxmox-legacy
        ];
        host = "192.168.20.192";
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
        host = "192.168.20.44";
      };

      db-01 = {
        roles = [
          config.flake.nixosModules.role-db
          config.flake.nixosModules.role-proxmox-legacy
        ];
        host = "192.168.20.28";
      };

      starr-sabnzbd-01 = {
        roles = [
          config.flake.nixosModules.role-starr-sabnzbd
          config.flake.nixosModules.role-proxmox-legacy
        ];
        host = "192.168.20.219";

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
        host = "192.168.20.153";

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
        host = "192.168.20.58";

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
        host = "192.168.20.206";

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
        host = "192.168.20.181";
      };

      starr-jellyfin-01 = {
        roles = [
          config.flake.nixosModules.role-starr-jellyfin
          config.flake.nixosModules.role-proxmox-legacy
        ];
        host = "192.168.20.26";

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
        host = "192.168.20.147";

        proxy = {
          port = 5055;
          subdomains = [ "jellyseerr" ];
          websockets = true;
        };
      };

      cam-01 = {
        roles = [
          config.flake.nixosModules.role-scrypted-server
        ];
        host = "192.168.20.229";
      };

      cam-client-01 = {
        roles = [
          config.flake.nixosModules.role-scrypted-server
        ];
        host = "192.168.20.182";
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

        host = "192.168.20.108";

        proxy = {
          port = 80;
          websockets = true;
        };
      };

      pve-01 = {
        managed = false;

        host = "192.168.20.114";

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
