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
        roles = [ config.flake.nixosModules.role-builder ];
        host = "192.168.20.224";
      };

      build-02 = {
        roles = [ config.flake.nixosModules.role-builder ];
        host = "192.168.20.46";
        system = "aarch64-linux";
      };

      dns-01 = {
        roles = [ config.flake.nixosModules.role-dns ];
        host = "192.168.20.29";

        proxy = {
          port = 3000;
        };
      };

      dns-02 = {
        roles = [ config.flake.nixosModules.role-dns ];
        host = "192.168.20.192";
        system = "aarch64-linux";

        proxy = {
          port = 3000;
        };
      };

      proxy-01 = {
        roles = [ config.flake.nixosModules.role-proxy ];
        host = "192.168.20.44";
      };

      db-01 = {
        roles = [ config.flake.nixosModules.role-db ];
        host = "192.168.20.28";
      };

      starr-sabnzbd-01 = {
        roles = [ config.flake.nixosModules.role-starr-sabnzbd ];
        host = "192.168.20.219";

        proxy = {
          port = 8080;
          subdomains = [ "sabnzbd" ];
        };
      };

      starr-prowlarr-01 = {
        roles = [ config.flake.nixosModules.role-starr-prowlarr ];
        host = "192.168.20.153";

        proxy = {
          port = 9696;
          subdomains = [ "prowlarr" ];
        };
      };

      starr-radarr-01 = {
        roles = [ config.flake.nixosModules.role-starr-radarr ];
        host = "192.168.20.58";

        proxy = {
          port = 7878;
          subdomains = [ "radarr" ];
        };
      };

      starr-sonarr-01 = {
        roles = [ config.flake.nixosModules.role-starr-sonarr ];
        host = "192.168.20.206";

        proxy = {
          port = 8989;
          subdomains = [ "sonarr" ];
        };
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
