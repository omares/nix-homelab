# Home Assistant Core Service Configuration
#
# Contains core HA setup: http, recorder, zones, logger, prometheus.
# Component wiring is in components.nix
# Automations and scenes are in automations.nix
# Shelly discovery is in shelly.nix
# Dashboards are in dashboards.nix
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
    # mDNS for zeroconf device discovery (Shelly, HomeKit, etc.)
    networking.firewall.allowedUDPPorts = lib.mkIf cfg.openFirewall [ 5353 ];

    services.home-assistant = {
      enable = true;
      configDir = cfg.configDir;

      extraPackages = ps: [ ps.psycopg2 ];

      # Note: MQTT broker connection must be configured via UI after onboarding
      # (Settings > Devices & Services > Add Integration > MQTT)
      # YAML config for broker settings is deprecated.
      config = {
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
            entity_globs = [ "sensor.*_last_restart" ];
          };
        };

        logger.default = "info";

        prometheus = { };
      };
    };
  };
}
