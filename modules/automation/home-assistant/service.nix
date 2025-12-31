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

  # ==========================================================================
  # Routine System (see docs/prd-hass-routines.md)
  # ==========================================================================

  # Input buttons for routine events
  routineInputButtons = {
    routine_evening = {
      name = "Routine: Evening";
      icon = "mdi:weather-sunset-down";
    };
    routine_night = {
      name = "Routine: Night";
      icon = "mdi:weather-night";
    };
    routine_morning = {
      name = "Routine: Morning";
      icon = "mdi:weather-sunny";
    };
    routine_sunset = {
      name = "Routine: Sunset";
      icon = "mdi:weather-sunset";
    };
    routine_sunrise = {
      name = "Routine: Sunrise";
      icon = "mdi:weather-sunset-up";
    };
  };

  # Bridge automation: Calendar events → input_button presses
  routineCalendarBridgeAutomation = {
    id = "routine_calendar_bridge";
    alias = "Routine: Calendar Bridge";
    mode = "queued";
    triggers = [
      {
        trigger = "calendar";
        event = "start";
        entity_id = "calendar.routines";
      }
    ];
    actions = [
      {
        choose = [
          {
            conditions = "{{ trigger.calendar_event.summary == 'Evening' }}";
            sequence = [
              {
                service = "input_button.press";
                target.entity_id = "input_button.routine_evening";
              }
            ];
          }
          {
            conditions = "{{ trigger.calendar_event.summary == 'Night' }}";
            sequence = [
              {
                service = "input_button.press";
                target.entity_id = "input_button.routine_night";
              }
            ];
          }
          {
            conditions = "{{ trigger.calendar_event.summary == 'Morning' }}";
            sequence = [
              {
                service = "input_button.press";
                target.entity_id = "input_button.routine_morning";
              }
            ];
          }
        ];
      }
    ];
  };

  # Bridge automation: Sunset → input_button press
  routineSunsetBridgeAutomation = {
    id = "routine_sunset_bridge";
    alias = "Routine: Sunset Bridge";
    triggers = [
      {
        trigger = "sun";
        event = "sunset";
        offset = "00:00:00";
      }
    ];
    actions = [
      {
        service = "input_button.press";
        target.entity_id = "input_button.routine_sunset";
      }
    ];
  };

  # Bridge automation: Sunrise → input_button press
  routineSunriseBridgeAutomation = {
    id = "routine_sunrise_bridge";
    alias = "Routine: Sunrise Bridge";
    triggers = [
      {
        trigger = "sun";
        event = "sunrise";
        offset = "00:00:00";
      }
    ];
    actions = [
      {
        service = "input_button.press";
        target.entity_id = "input_button.routine_sunrise";
      }
    ];
  };

  # Device automation: Close covers on evening routine
  routineEveningCoversAutomation = {
    id = "routine_evening_covers_close";
    alias = "Routine: Evening - Close Covers";
    triggers = [
      {
        trigger = "state";
        entity_id = "input_button.routine_evening";
      }
    ];
    actions = [
      {
        service = "cover.close_cover";
        target.label_id = "routine_evening";
      }
    ];
  };

  # Device automation: Close covers on night routine
  routineNightCoversAutomation = {
    id = "routine_night_covers_close";
    alias = "Routine: Night - Close Covers";
    triggers = [
      {
        trigger = "state";
        entity_id = "input_button.routine_night";
      }
    ];
    actions = [
      {
        service = "cover.close_cover";
        target.label_id = "routine_night";
      }
    ];
  };

  # Device automation: Open covers on morning routine
  routineMorningCoversAutomation = {
    id = "routine_morning_covers_open";
    alias = "Routine: Morning - Open Covers";
    triggers = [
      {
        trigger = "state";
        entity_id = "input_button.routine_morning";
      }
    ];
    actions = [
      {
        service = "cover.open_cover";
        target.label_id = "routine_morning";
      }
    ];
  };

  # ==========================================================================
  # Shelly Discovery System
  # ==========================================================================

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

          # Enable python_script integration for Shelly Gen2+ discovery
          python_script = { };

          # Routine input buttons (see docs/prd-hass-routines.md)
          input_button = routineInputButtons;

          # Automations
          automation =
            # Shelly Gen2+ discovery
            [ shellyDiscoveryAutomation ]
            ++ lib.optionals (cfg.shelly.deviceIds != [ ]) [ shellyAnnounceAutomation ]
            # Routine system - bridge automations
            ++ [
              routineCalendarBridgeAutomation
              routineSunsetBridgeAutomation
              routineSunriseBridgeAutomation
            ]
            # Routine system - device automations
            ++ [
              routineEveningCoversAutomation
              routineNightCoversAutomation
              routineMorningCoversAutomation
            ];
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
