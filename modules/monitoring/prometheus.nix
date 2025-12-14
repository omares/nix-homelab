{
  lib,
  config,
  ...
}:
let
  cfg = config.mares.monitoring.prometheus;
in
{
  options.mares.monitoring.prometheus = {
    enable = lib.mkEnableOption "Enable prometheus";

    scrapeTargets = {
      alloy = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of Alloy agent targets (host:port)";
      };

      postgres = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of postgres-exporter targets (host:port)";
      };

      nginx = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of nginx-exporter targets (host:port)";
      };

      exportarr = {
        radarr = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "List of exportarr radarr targets (host:port)";
        };
        sonarr = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "List of exportarr sonarr targets (host:port)";
        };
        prowlarr = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "List of exportarr prowlarr targets (host:port)";
        };
        sabnzbd = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "List of exportarr sabnzbd targets (host:port)";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.prometheus = {
      enable = true;
      retentionTime = "30d";

      extraFlags = [ "--web.enable-remote-write-receiver" ];

      globalConfig = {
        scrape_interval = "15s";
        evaluation_interval = "15s";
        scrape_timeout = "10s";
      };

      scrapeConfigs = [
        {
          job_name = "prometheus";
          static_configs = [
            { targets = [ "localhost:9090" ]; }
          ];
        }
      ]
      ++ lib.optional (cfg.scrapeTargets.alloy != [ ]) {
        job_name = "alloy";
        static_configs = [
          { targets = cfg.scrapeTargets.alloy; }
        ];
      }
      ++ lib.optional (cfg.scrapeTargets.postgres != [ ]) {
        job_name = "postgres";
        static_configs = [
          { targets = cfg.scrapeTargets.postgres; }
        ];
      }
      ++ lib.optional (cfg.scrapeTargets.nginx != [ ]) {
        job_name = "nginx";
        static_configs = [
          { targets = cfg.scrapeTargets.nginx; }
        ];
      }
      ++ lib.optional (cfg.scrapeTargets.exportarr.radarr != [ ]) {
        job_name = "exportarr-radarr";
        static_configs = [
          { targets = cfg.scrapeTargets.exportarr.radarr; }
        ];
      }
      ++ lib.optional (cfg.scrapeTargets.exportarr.sonarr != [ ]) {
        job_name = "exportarr-sonarr";
        static_configs = [
          { targets = cfg.scrapeTargets.exportarr.sonarr; }
        ];
      }
      ++ lib.optional (cfg.scrapeTargets.exportarr.prowlarr != [ ]) {
        job_name = "exportarr-prowlarr";
        static_configs = [
          { targets = cfg.scrapeTargets.exportarr.prowlarr; }
        ];
      }
      ++ lib.optional (cfg.scrapeTargets.exportarr.sabnzbd != [ ]) {
        job_name = "exportarr-sabnzbd";
        static_configs = [
          { targets = cfg.scrapeTargets.exportarr.sabnzbd; }
        ];
      };
    };

    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 9090 ];
    };
  };
}
