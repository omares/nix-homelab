{
  config,
  nodeCfg,
  mares,
  ...
}:
let
  dbNode = mares.infrastructure.nodes.db-01;
  monNode = mares.infrastructure.nodes.mon-01;
  proxyNode = mares.infrastructure.nodes.proxy-01;
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
    "influxdb"
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

      # InfluxDB
      influxdb_token: ${config.sops.placeholder."influxdb-hass_token"}
    '';
    path = "/var/lib/hass/secrets.yaml";
    owner = "hass";
    group = "hass";
    mode = "0400";
  };

  mares.home-assistant = {
    enable = true;
    bindAddress = nodeCfg.host;
    trustedProxies = [ proxyNode.host ];

    components = {
      # Built-in HA components
      homekit.enable = true;
      fronius.enable = true;
      samsung-tv.enable = true;
      roborock.enable = true;

      # Custom components (nixpkgs)
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

      # Lovelace modules
      apexcharts.enable = true;

      # External integrations
      wmbusmeters.enable = true;

      # Integrations with extra config
      influxdb = {
        enable = true;
        host = monNode.dns.fqdn;
      };

      shelly = {
        enable = true;
        deviceIds = [
          "shellies/carport_garden_path_light_relay"
          "shellies/guest_bathroom_shutter_cover"
          "shellies/garden_pool_circulation_pump_relay"
          "shellies/garden_pool_heating_pump_relay"
          "shellies/hallway_shutter_cover"
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

  mares.backup.restic = {
    enable = true;
    sshKeyFile = config.sops.secrets.restic-ssh_private_key.path;

    jobs.hass = {
      repoPath = "hass";
      passwordFile = config.sops.secrets.restic-hass_repo_key.path;
      paths = [ "/var/lib/hass/.storage" ];
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
