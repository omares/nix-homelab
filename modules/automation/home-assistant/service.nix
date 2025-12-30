{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mares.home-assistant;

  # Fetch the Shelly Gen2+ discovery script (pinned to 4.1.0)
  shellyDiscoveryScript = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/bieniu/ha-shellies-discovery-gen2/4.1.0/python_scripts/shellies_discovery_gen2.py";
    hash = "sha256-gUDkEFrzUp5M+wYZ4Gg43gfNJHKSNXhehov5+sOOU9c=";
  };

  pythonScriptsDir = pkgs.linkFarm "hass-python-scripts" [
    {
      name = "shellies_discovery_gen2.py";
      path = shellyDiscoveryScript;
    }
  ];

  # Automation: Listen for Shelly device announcements and create HA entities
  # Based on: https://github.com/bieniu/ha-shellies-discovery-gen2
  shellyDiscoveryAutomation = {
    id = "shellies_discovery_gen2";
    alias = "Shellies Discovery Gen2";
    mode = "queued";
    max = 999;
    triggers = [
      {
        trigger = "mqtt";
        topic = "shellies_discovery/rpc";
      }
    ];
    actions = [
      {
        action = "python_script.shellies_discovery_gen2";
        data = {
          id = "{{ trigger.payload_json.src }}";
          device_config = "{{ trigger.payload_json.result }}";
        };
      }
      {
        condition = "template";
        value_template = "{{ 'mqtt' in trigger.payload_json.result }}";
      }
      {
        action = "mqtt.publish";
        data = {
          topic = "{{ trigger.payload_json.result.mqtt.topic_prefix }}/command";
          payload = "status_update";
        };
      }
    ];
  };

  # Automation: Announce to Shelly devices to trigger discovery
  # Sends GetConfig and GetComponents to each device on HA start
  shellyAnnounceAutomation = {
    id = "shellies_announce_gen2";
    alias = "Shellies Announce Gen2";
    triggers = [
      {
        trigger = "homeassistant";
        event = "start";
      }
    ];
    variables = {
      get_config_payload = "{{ {'id': 1, 'src': 'shellies_discovery', 'method': 'Shelly.GetConfig'} | to_json }}";
      get_components_payload = "{{ {'id': 1, 'src': 'shellies_discovery', 'method': 'Shelly.GetComponents', 'params': {'include': ['config']}} | to_json }}";
      device_ids = cfg.shelly.deviceIds;
    };
    actions = [
      {
        repeat = {
          for_each = "{{ device_ids }}";
          sequence = [
            {
              action = "mqtt.publish";
              data = {
                topic = "{{ repeat.item }}/rpc";
                payload = "{{ get_config_payload }}";
              };
            }
            {
              action = "mqtt.publish";
              data = {
                topic = "{{ repeat.item }}/rpc";
                payload = "{{ get_components_payload }}";
              };
            }
          ];
        };
      }
    ];
  };
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
            };
          };

          logger.default = "info";

          prometheus = { };

          # Enable python_script integration for Shelly Gen2+ discovery
          python_script = { };

          # Shelly Gen2+ discovery automation
          automation = [
            shellyDiscoveryAutomation
          ]
          ++ lib.optionals (cfg.shelly.deviceIds != [ ]) [ shellyAnnounceAutomation ];
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

    # Extend Home Assistant's preStart to deploy python_scripts
    systemd.services.home-assistant.preStart = lib.mkAfter ''
      mkdir -p "${cfg.configDir}/python_scripts"
      ln -fns ${pythonScriptsDir}/* "${cfg.configDir}/python_scripts/"
    '';
  };
}
