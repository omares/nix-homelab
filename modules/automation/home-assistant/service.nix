{
  config,
  lib,
  ...
}:
let
  cfg = config.mares.home-assistant;
in
{
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

    services.home-assistant = {
      enable = true;
      configDir = cfg.configDir;

      extraPackages = ps: [
        ps.psycopg2
      ];

      extraComponents =
        [
          "default_config"
          "isal"
          "open_meteo"
          "dwd_weather_warnings"
          "mobile_app"
          "prometheus"
        ]
        ++ cfg.extraComponents
        ++ lib.optionals cfg.influxdb.enable [ "influxdb" ]
        ++ lib.optionals cfg.mqtt.enable [ "mqtt" ];

      # Note: MQTT broker connection must be configured via UI after onboarding
      # (Settings > Devices & Services > Add Integration > MQTT)
      # YAML config for broker settings is deprecated.
      config = lib.mkMerge [
        {
          homeassistant = {
            name = "Home";
            time_zone = "Europe/Berlin";
            unit_system = "metric";
            temperature_unit = "C";
            latitude = "!secret latitude";
            longitude = "!secret longitude";
            country = "DE";
          };

          http = {
            server_host = cfg.bindAddress;
            server_port = cfg.port;
            use_x_forwarded_for = cfg.trustedProxies != [ ];
            trusted_proxies = cfg.trustedProxies;
          };

          recorder = {
            db_url = "!secret recorder_db_url";
            purge_keep_days = cfg.recorder.purgeKeepDays;
            commit_interval = cfg.recorder.commitInterval;
            exclude = {
              domains = cfg.recorder.excludeDomains;
            };
          };

          logger.default = "info";

          prometheus = { };
        }

        (lib.mkIf cfg.influxdb.enable {
          influxdb = {
            api_version = 2;
            ssl = false;
            host = cfg.influxdb.host;
            port = cfg.influxdb.port;
            organization = cfg.influxdb.organization;
            bucket = cfg.influxdb.bucket;
            token = "!secret influxdb_token";
            max_retries = cfg.influxdb.maxRetries;
            include.entity_globs = [ "sensor.*" ];
          };
        })
      ];
    };

  };
}
