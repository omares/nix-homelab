{
  config,
  lib,
  ...
}:
let
  cfg = config.mares.monitoring.influxdb;
  serverCfg = config.mares.monitoring.server;
in
{
  options.mares.monitoring.influxdb = {
    enable = lib.mkEnableOption "InfluxDB 2.x time-series database";

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to open the firewall for InfluxDB.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8086;
      description = "Port for InfluxDB HTTP API.";
    };

    bindAddress = lib.mkOption {
      type = lib.types.str;
      default = serverCfg.host;
      description = "IP address to bind InfluxDB to.";
    };

    adminPasswordFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to file containing the admin password (loaded via systemd LoadCredential).";
    };

    adminTokenFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to file containing the admin API token (loaded via systemd LoadCredential).";
    };

    hassTokenFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to file containing the Home Assistant token (loaded via systemd LoadCredential).";
    };
  };

  config = lib.mkIf cfg.enable {
    services.influxdb2 = {
      enable = true;

      settings = {
        http-bind-address = "${cfg.bindAddress}:${toString cfg.port}";
      };

      provision = {
        enable = true;

        initialSetup = {
          organization = "mares";
          bucket = "home-assistant";
          username = "admin";
          passwordFile = cfg.adminPasswordFile;
          tokenFile = cfg.adminTokenFile;
          retention = 31536000; # 365 days in seconds
        };

        organizations.mares = {
          buckets.home-assistant = {
            retention = 31536000; # 365 days
          };

          auths.home-assistant = {
            description = "Home Assistant read/write token";
            tokenFile = "/run/credentials/influxdb2.service/hass-token";
            writeBuckets = [ "home-assistant" ];
            readBuckets = [ "home-assistant" ];
          };
        };
      };
    };

    systemd.services.influxdb2.serviceConfig.LoadCredential = [
      "hass-token:${cfg.hassTokenFile}"
    ];

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
