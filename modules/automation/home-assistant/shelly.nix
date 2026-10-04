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

  discoveryVersion = "5.4.3";

  shellyDiscoveryScript = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/bieniu/ha-shellies-discovery-gen2/${discoveryVersion}/python_scripts/shellies_discovery_gen2.py";
    hash = "sha256-ksCczPxV6AVSbH4YuoX+itJcg9L2j/i7IEj58HzuuqA=";
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
    max = 50;
    triggers = [
      {
        trigger = "mqtt";
        topic = "shellies_discovery/rpc";
      }
    ];
    actions = [
      # GetComponents replies are handled by the shellies_components_gen2 script
      {
        condition = "template";
        value_template = "{{ 'components' not in (trigger.payload_json.result | default({})) }}";
      }
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

  # Script: Fetch all component pages of a device and run discovery on them
  # Mirrors upstream's shellies_components_gen2 from README.md, except for the
  # all_components workaround below. Bumping discoveryVersion fails evaluation
  # on purpose: diff the new upstream script against this one first.
  shellyComponentsScript =
    assert lib.assertMsg (discoveryVersion == "5.4.3")
      "shelly.nix: discovery script bumped to ${discoveryVersion}; re-sync shellyComponentsScript with upstream and check whether the all_components workaround is still needed";
    {
      alias = "Shellies Components Gen2";
      mode = "queued";
      max = 50;
      fields = {
        device_topic = {
          description = "MQTT topic prefix for the device, e.g. shellies/shelly-1-gen4-abc123";
          required = true;
        };
        discovery_prefix = {
          description = "MQTT discovery prefix";
          default = "homeassistant";
        };
      };
      sequence = [
        {
          variables = {
            src = "shellies_discovery/{{ device_topic.split('/') | last }}";
            response_topic = "shellies_discovery/{{ device_topic.split('/') | last }}/rpc";
            all_pages = [ ];
            offset = 0;
            total = 1;
            device_id = "{{ device_topic.split('/') | last }}";
          };
        }
        {
          repeat = {
            while = [
              {
                condition = "template";
                value_template = "{{ offset < total }}";
              }
            ];
            sequence = [
              {
                action = "mqtt.publish";
                data = {
                  topic = "{{ device_topic }}/rpc";
                  payload = "{{ {'id': 1, 'src': src, 'method': 'Shelly.GetComponents', 'params': {'include': ['config'], 'offset': offset}} | to_json }}";
                };
              }
              {
                wait_for_trigger = [
                  {
                    trigger = "mqtt";
                    topic = "{{ response_topic }}";
                  }
                ];
                timeout = "00:00:30";
              }
              {
                "if" = [
                  {
                    condition = "template";
                    value_template = "{{ wait.trigger is none }}";
                  }
                ];
                "then" = [ { stop = "Timeout waiting for Shelly.GetComponents from {{ device_topic }}"; } ];
              }
              {
                variables = {
                  page = "{{ wait.trigger.payload_json.result }}";
                  device_id = "{{ wait.trigger.payload_json.src }}";
                };
              }
              {
                variables = {
                  all_pages = "{{ all_pages + [page] }}";
                  offset = "{{ page.offset + (page.components | length) }}";
                  total = "{{ page.total }}";
                };
              }
            ];
          };
        }
        {
          action = "python_script.shellies_discovery_gen2";
          data = {
            id = "{{ device_id }}";
            device_config.components = "{{ all_pages }}";
            discovery_prefix = "{{ discovery_prefix | default('homeassistant') }}";
          };
        }
        {
          # Upstream uses `| flatten`, which also flattens the component dicts into
          # their keys, so the mqtt component is never found
          variables.all_components = "{{ all_pages | map(attribute='components') | sum(start=[]) }}";
        }
        {
          variables.mqtt_comp = "{{ all_components | selectattr('key', 'equalto', 'mqtt') | list | first | default(none) }}";
        }
        {
          condition = "template";
          value_template = "{{ mqtt_comp is not none }}";
        }
        {
          action = "mqtt.publish";
          data = {
            topic = "{{ mqtt_comp.config.topic_prefix }}/command";
            payload = "status_update";
          };
        }
      ];
    };

  # Automation: Announce to Shelly devices to trigger discovery
  # Sends GetConfig and fetches components of each device on HA start
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
      device_ids = cfg.components.shelly.deviceIds;
    };
    actions = [
      # MQTT subscriptions are not ready right at startup; replies to the first
      # device would otherwise be lost
      { delay.seconds = 15; }
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
              action = "script.shellies_components_gen2";
              data.device_topic = "{{ repeat.item }}";
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

      "automation nix" = [
        shellyDiscoveryAutomation
      ]
      ++ lib.optionals (cfg.components.shelly.deviceIds != [ ]) [ shellyAnnounceAutomation ];

      "script nix".shellies_components_gen2 = shellyComponentsScript;
    };

    # Deploy python_scripts to Home Assistant config directory
    systemd.services.home-assistant.preStart = lib.mkAfter ''
      mkdir -p "${cfg.configDir}/python_scripts"
      ln -fns ${pythonScriptsDir}/* "${cfg.configDir}/python_scripts/"
    '';
  };
}
