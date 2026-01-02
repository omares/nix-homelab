# Home Assistant Core Service Configuration
#
# This file contains the core HA service setup: http, recorder, zones, etc.
# Automations and scenes are in automations.nix
# Shelly discovery is in shelly.nix
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
    # mDNS for zeroconf device discovery (Shelly, etc.)
    networking.firewall.allowedUDPPorts = lib.mkIf cfg.openFirewall [ 5353 ];

    services.home-assistant = {
      enable = true;
      configDir = cfg.configDir;

      extraPackages = ps: [
        ps.psycopg2
      ];
      extraComponents = [
        "default_config"
        "isal"
        "mqtt"
        "shelly"
        "open_meteo"
        "dwd_weather_warnings"
        "mobile_app"
        "prometheus"
        "ipp"
        "google_translate"
        "hue"
        "apple_tv"
        "homekit_controller"
        "unifiprotect"
        "local_calendar"
      ]
      ++ cfg.extraComponents
      ++ lib.optionals cfg.influxdb.enable [ "influxdb" ];

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

          # Home zone with 50m radius for tighter geofencing
          zone = [
            {
              name = "Home";
              latitude = "!secret latitude";
              longitude = "!secret longitude";
              radius = 50;
              icon = "mdi:home";
            }
          ];

          # Enables zeroconf/mDNS discovery for Shelly and other devices
          default_config = { };

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
              entity_globs = [
                "sensor.*_last_restart"
              ];
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
