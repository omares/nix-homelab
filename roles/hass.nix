{
  config,
  mares,
  ...
}:
let
  dbNode = mares.infrastructure.nodes.db-01;
in
{
  imports = [
    ../modules/automation/home-assistant
    ../modules/backup/restic
  ];

  sops-vault.items = [
    "hass"
    "mqtt"
    "pgsql"
    "restic"
  ];

  sops.templates.hass-secrets = {
    content = ''
      # Home Assistant secrets - managed by sops-nix
      latitude: ${config.sops.placeholder."hass-latitude"}
      longitude: ${config.sops.placeholder."hass-longitude"}

      # Database connections
      recorder_db_url: "postgresql://hass:${
        config.sops.placeholder."pgsql-hass_password"
      }@${dbNode.dns.fqdn}:6432/hass"

      # MQTT
      mqtt_password: ${config.sops.placeholder."mqtt-hass_password"}
    '';
    path = "/var/lib/hass/secrets.yaml";
    owner = "hass";
    group = "hass";
    mode = "0400";
  };

  mares.home-assistant = {
    enable = true;

    components = {
      # Built-in HA components
      homekit.enable = true;
      fronius.enable = true;
      samsung-tv.enable = true;
      roborock.enable = true;

      # Custom components (nixpkgs)
      dwd-weather.enable = true;
      scene-presets.enable = true;
      waste-collection-schedule.enable = true;
      home-connect-alt.enable = false;

      # Custom components (local packages)
      meross-lan.enable = true;
      evcc.enable = true;
      syr-connect.enable = true;
      scrypted.enable = true;
      home-connect-local.enable = true;
      ostrom.enable = true;
      stiebel-eltron-isg.enable = true;

      # Lovelace modules
      apexcharts.enable = true;
      auto-entities.enable = true;
      bubble-card.enable = true;
      card-tools.enable = true;
      clock-weather-card.enable = true;
      horizon-card.enable = true;
      layout-card.enable = true;

      # External integrations
      wmbusmeters.enable = true;

      # Integrations with extra config
      influxdb.enable = true;

      shelly = {
        enable = true;
        deviceIds = [
          "shellies/carport_garden_path_light_relay"
          "shellies/guest_bathroom_shutter_cover"
          "shellies/garden_pool_circulation_pump_relay"
          "shellies/garden_pool_heating_pump_relay"
          "shellies/hallway_shutter_cover"
          "shellies/harry_light_relay"
          "shellies/kitchen_shutter_cover"
          "shellies/living_room_shutter_left_cover"
          "shellies/living_room_shutter_right_cover"
          "shellies/living_room_shutter_terrace_door_cover"
          "shellies/living_room_shutter_terrace_window_cover"
          "shellies/office_shutter_fixed_cover"
          "shellies/office_shutter_cover"
          "shellies/utility_room_shutter_cover"
        ];
      };
    };
  };

  # Shelly BLU Door/Window paired to the harry light relay. shellies-discovery-gen2
  # does not support it, so its BTHome components are mapped by hand.
  services.home-assistant.config.mqtt =
    let
      topic = id: "shellies/harry_light_relay/status/bthomesensor:${toString id}";
      device = {
        identifiers = [ "38:39:8f:9e:0b:ff" ];
        name = "Harry Door Contact";
        manufacturer = "Shelly";
        model = "BLU Door/Window";
        via_device = "30:30:f9:e6:45:b4";
      };
    in
    {
      binary_sensor = [
        {
          name = null;
          unique_id = "harry_door_contact_door";
          state_topic = topic 202;
          value_template = "{{ 'ON' if value_json.value else 'OFF' }}";
          device_class = "door";
          inherit device;
        }
      ];

      sensor = [
        {
          name = "Battery";
          unique_id = "harry_door_contact_battery";
          state_topic = topic 200;
          value_template = "{{ value_json.value }}";
          device_class = "battery";
          unit_of_measurement = "%";
          state_class = "measurement";
          entity_category = "diagnostic";
          inherit device;
        }
        {
          name = "Illuminance";
          unique_id = "harry_door_contact_illuminance";
          state_topic = topic 201;
          value_template = "{{ value_json.value }}";
          device_class = "illuminance";
          unit_of_measurement = "lx";
          state_class = "measurement";
          inherit device;
        }
        {
          name = "Rotation";
          unique_id = "harry_door_contact_rotation";
          state_topic = topic 203;
          value_template = "{{ value_json.value }}";
          unit_of_measurement = "°";
          state_class = "measurement";
          icon = "mdi:rotate-3d-variant";
          inherit device;
        }
      ];
    };

  mares.backup.restic = {
    enable = true;
    sshKeyFile = config.sops.secrets.restic-ssh_private_key.path;

    jobs.hass = {
      repoPath = "hass";
      passwordFile = config.sops.secrets.restic-hass_repo_key.path;
      paths = [
        "/var/lib/hass/.storage"
        "/var/lib/hass/automations.yaml"
      ];
      timerConfig = {
        OnCalendar = "*-*-* 03:00:00";
      };
    };
  };

  systemd.services.home-assistant = {
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
  };
}
