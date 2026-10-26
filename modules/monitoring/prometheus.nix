{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.mares.monitoring.prometheus;
  blackboxCfg = config.services.prometheus.exporters.blackbox;
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

    probeTargets = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            url = lib.mkOption {
              type = lib.types.str;
              description = "URL probed by the blackbox exporter";
            };
            domains = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Domains served by this URL, shown on the uptime dashboard";
            };
          };
        }
      );
      default = { };
      description = "HTTPS endpoints probed via the local blackbox exporter, keyed by service name";
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
      }
      # Multi-target pattern: the probed URL becomes ?target=, the scrape goes to the local exporter
      ++ lib.optional (cfg.probeTargets != { }) {
        job_name = "blackbox";
        scrape_interval = "1m";
        metrics_path = "/probe";
        params.module = [ "https_up" ];
        static_configs = lib.mapAttrsToList (service: probe: {
          targets = [ probe.url ];
          labels = {
            inherit service;
            domains = lib.concatStringsSep ", " probe.domains;
          };
        }) cfg.probeTargets;
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            target_label = "__param_target";
          }
          {
            source_labels = [ "__param_target" ];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = "127.0.0.1:${toString blackboxCfg.port}";
          }
        ];
      };
    };

    services.prometheus.exporters.blackbox = lib.mkIf (cfg.probeTargets != { }) {
      enable = true;
      listenAddress = "127.0.0.1";
      configFile = (pkgs.formats.yaml { }).generate "blackbox.yml" {
        modules.https_up = {
          prober = "http";
          timeout = "5s";
          http = {
            # Redirects are followed; auth-protected UIs answering 401/403 still count as up
            valid_status_codes = [
              200
              401
              403
            ];
            fail_if_not_ssl = true;
            preferred_ip_protocol = "ip4";
          };
        };
      };
    };

    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 9090 ];
    };
  };
}
