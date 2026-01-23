# Home Assistant Core Service Configuration
#
# This file contains the core HA service setup: http, recorder, zones, etc.
# Automations and scenes are in automations.nix
# Shelly discovery is in shelly.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mares.home-assistant;
  python = pkgs.home-assistant.python;

  merossLan = pkgs.callPackage ./meross-lan.nix { };
  haEvcc = pkgs.callPackage ./ha-evcc.nix { };
  syrConnect = pkgs.callPackage ./syr-connect.nix {
    inherit (python.pkgs) pycryptodomex;
  };
  haScrypted = pkgs.callPackage ./ha-scrypted.nix { };

  merossComponents = lib.optionals cfg.meross.enable [ merossLan ];
  scenePresetsComponents = lib.optionals cfg.scenePresets.enable [
    pkgs.home-assistant-custom-components.scene_presets
  ];
  evccComponents = lib.optionals cfg.evcc.enable [ haEvcc ];
  syrConnectComponents = lib.optionals cfg.syrConnect.enable [ syrConnect ];
  scryptedComponents = lib.optionals cfg.scrypted.enable [ haScrypted ];
in
{
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall (
      [ cfg.port ] ++ lib.optionals cfg.homekit.enable [ 21063 ]
    );
    # mDNS for zeroconf device discovery (Shelly, HomeKit, etc.)
    networking.firewall.allowedUDPPorts = lib.mkIf cfg.openFirewall [ 5353 ];

    services.home-assistant = {
      enable = true;
      configDir = cfg.configDir;
      customComponents =
        merossComponents
        ++ scenePresetsComponents
        ++ evccComponents
        ++ syrConnectComponents
        ++ scryptedComponents;

      extraPackages = ps: [
        ps.psycopg2
      ];
      extraComponents = [
        "default_config"
        "isal"
        "mqtt"
        "open_meteo"
        "dwd_weather_warnings"
        "mobile_app"
        "prometheus"
        "ipp"
        "google_translate"
        "hue"
        "apple_tv"
        "unifiprotect"
        "local_calendar"
      ]
      ++ cfg.extraComponents
      ++ lib.optionals cfg.shelly.enable [ "shelly" ]
      ++ lib.optionals cfg.influxdb.enable [ "influxdb" ]
      ++ lib.optionals cfg.homekit.enable [ "homekit" ]
      ++ lib.optionals cfg.fronius.enable [ "fronius" ]
      ++ lib.optionals cfg.samsungTv.enable [ "samsungtv" ]
      ++ lib.optionals cfg.roborock.enable [ "roborock" ];

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

        (lib.mkIf cfg.homekit.enable {
          homekit = [
            {
              name = "Mares HomeKit Bridge";
              port = 21063;
              filter = {
                include_domains = [
                  "cover"
                  "light"
                  "switch"
                ];
                exclude_domains = [
                  "automation"
                  "media_player"
                  "script"
                ];
              };
            }
          ];
        })
      ];
    };
  };
}
