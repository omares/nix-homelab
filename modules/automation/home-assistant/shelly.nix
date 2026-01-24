# Shelly Gen2+ Discovery System
#
# Uses the ha-shellies-discovery-gen2 python script to create HA entities
# from Shelly devices via MQTT.
#
# Based on: https://github.com/bieniu/ha-shellies-discovery-gen2
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
      device_ids = cfg.components.shelly.deviceIds;
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
  config = lib.mkIf (cfg.enable && cfg.components.shelly.enable) {
    services.home-assistant.config = {
      # Enable python_script integration for Shelly Gen2+ discovery
      python_script = { };

      automation = [
        shellyDiscoveryAutomation
      ]
      ++ lib.optionals (cfg.components.shelly.deviceIds != [ ]) [ shellyAnnounceAutomation ];
    };

    # Deploy python_scripts to Home Assistant config directory
    systemd.services.home-assistant.preStart = lib.mkAfter ''
      mkdir -p "${cfg.configDir}/python_scripts"
      ln -fns ${pythonScriptsDir}/* "${cfg.configDir}/python_scripts/"
    '';
  };
}
