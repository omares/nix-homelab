{
  lib,
  config,
  ...
}:
let
  cfg = config.mares.monitoring.server;
in
{
  options.mares.monitoring = {
    server = {
      host = lib.mkOption {
        type = lib.types.str;
        default = "10.10.22.241";
        description = "Monitoring server IP address";
      };

      prometheus = {
        port = lib.mkOption {
          type = lib.types.port;
          default = 9090;
          description = "Prometheus port";
        };

        url = lib.mkOption {
          type = lib.types.str;
          default = "http://${cfg.host}:${toString cfg.prometheus.port}/api/v1/write";
          readOnly = true;
          description = "Prometheus remote write URL";
        };
      };

      loki = {
        port = lib.mkOption {
          type = lib.types.port;
          default = 3100;
          description = "Loki port";
        };

        url = lib.mkOption {
          type = lib.types.str;
          default = "http://${cfg.host}:${toString cfg.loki.port}/loki/api/v1/push";
          readOnly = true;
          description = "Loki push URL";
        };
      };

      grafana = {
        port = lib.mkOption {
          type = lib.types.port;
          default = 3000;
          description = "Grafana port";
        };
      };
    };

    roles = lib.mkOption {
      type = lib.types.listOf (
        lib.types.enum [
          "monitoring-client"
          "monitoring-server"
          "monitoring-postgres"
          "monitoring-nginx"
          "monitoring-starr-radarr"
          "monitoring-starr-sonarr"
          "monitoring-starr-prowlarr"
          "monitoring-starr-sabnzbd"
        ]
      );
      default = [ ];
      description = "List of monitoring roles enabled on this node";
    };
  };
}
