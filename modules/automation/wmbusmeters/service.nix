# MQTT publishing and Home Assistant autodiscovery adapted from wmbusmeters-ha-addon
# https://github.com/wmbusmeters/wmbusmeters-ha-addon
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mares.automation.wmbusmeters;
  wmbusmeters = pkgs.callPackage ../../../packages/wmbusmeters/package.nix { };

  # Discovery templates define Home Assistant sensor attributes for each meter driver.
  # Based on wmbusmeters-ha-addon discovery mechanism.
  discoveryTemplates = {
    hydrus = {
      total_m3 = {
        component = "sensor";
        device_class = "water";
        state_class = "total";
        unit_of_measurement = "m³";
        icon = "mdi:gauge";
        enabled_by_default = true;
        name = "total";
      };
      flow_m3h = {
        component = "sensor";
        state_class = "measurement";
        unit_of_measurement = "m³/h";
        icon = "mdi:waves-arrow-right";
        enabled_by_default = true;
        name = "flow";
      };
      flow_temperature_c = {
        component = "sensor";
        device_class = "temperature";
        state_class = "measurement";
        unit_of_measurement = "°C";
        icon = "mdi:thermometer-water";
        enabled_by_default = false;
        name = "water temperature";
      };
      external_temperature_c = {
        component = "sensor";
        device_class = "temperature";
        state_class = "measurement";
        unit_of_measurement = "°C";
        icon = "mdi:thermometer";
        enabled_by_default = false;
        name = "ambient temperature";
      };
      rssi_dbm = {
        component = "sensor";
        device_class = "signal_strength";
        state_class = "measurement";
        entity_category = "diagnostic";
        unit_of_measurement = "dBm";
        icon = "mdi:signal";
        enabled_by_default = false;
        name = "rssi";
      };
      remaining_battery_life_y = {
        component = "sensor";
        state_class = "measurement";
        entity_category = "diagnostic";
        unit_of_measurement = "years";
        icon = "mdi:battery-clock-outline";
        enabled_by_default = true;
        name = "battery life remaining";
      };
    };
  };

  mkDiscoveryPayload =
    {
      meter,
      meterId,
      attribute,
      template,
    }:
    {
      device = {
        identifiers = [ "wmbusmeters_${meterId}" ];
        manufacturer = "Diehl Metering";
        model = meter.driver;
        name = meter.name;
        hw_version = meterId;
      };
      inherit (template) enabled_by_default name icon;
      state_topic = "${cfg.mqtt.topic}/${meter.name}";
      unique_id = "wmbusmeters_${meterId}_${attribute}";
      value_template = "{{ value_json.${attribute} }}";
    }
    // lib.optionalAttrs (template ? device_class) { inherit (template) device_class; }
    // lib.optionalAttrs (template ? state_class) { inherit (template) state_class; }
    // lib.optionalAttrs (template ? unit_of_measurement) { inherit (template) unit_of_measurement; }
    // lib.optionalAttrs (template ? entity_category) { inherit (template) entity_category; }
    // lib.optionalAttrs (attribute == "total_m3") {
      json_attributes_topic = "${cfg.mqtt.topic}/${meter.name}";
    };

  mosquittoPub = lib.getExe' pkgs.mosquitto "mosquitto_pub";

  mqttArgs = lib.concatStringsSep " " (
    [
      "--host ${cfg.mqtt.host}"
      "--port ${toString cfg.mqtt.port}"
      "--username ${cfg.mqtt.user}"
    ]
    ++ lib.optional cfg.mqtt.useTls "--cafile /etc/ssl/certs/ca-certificates.crt"
  );

  mkMeterDiscoveryCommands =
    meter:
    let
      template = discoveryTemplates.${meter.driver} or { };
    in
    lib.concatMapStringsSep "\n" (attribute: ''
      echo "Publishing discovery for ${meter.name}/${attribute}..."
      publish "${cfg.discovery.prefix}/sensor/wmbusmeters/''${METER_ID_${meter.name}}_${attribute}/config" '${
        builtins.toJSON (mkDiscoveryPayload {
          inherit meter attribute;
          meterId = "\${METER_ID_${meter.name}}";
          template = template.${attribute};
        })
      }'
    '') (lib.attrNames template);

  mqttDiscoveryScript = pkgs.writeShellScript "wmbusmeters-mqtt-discovery" ''
    set -euo pipefail

    MQTT_PASSWORD=$(cat "$CREDENTIALS_DIRECTORY/mqtt_password")
    ${lib.concatMapStringsSep "\n" (meter: ''
      METER_ID_${meter.name}=$(cat "$CREDENTIALS_DIRECTORY/meter_id_${meter.name}")
    '') cfg.meters}

    publish() {
      local topic="$1"
      local payload="$2"
      ${mosquittoPub} \
        ${mqttArgs} \
        --pw "$MQTT_PASSWORD" \
        --retain \
        --topic "$topic" \
        --message "$payload"
    }

    ${lib.concatMapStringsSep "\n" mkMeterDiscoveryCommands cfg.meters}

    echo "MQTT discovery complete."
  '';

  mqttPublishScript = pkgs.writeShellScript "wmbusmeters-mqtt-publish" ''
    TOPIC="$1"
    MESSAGE="$2"
    MQTT_PASSWORD=$(cat "$CREDENTIALS_DIRECTORY/mqtt_password")

    ${mosquittoPub} \
      ${mqttArgs} \
      --pw "$MQTT_PASSWORD" \
      --retain \
      --topic "$TOPIC" \
      --message "$MESSAGE"
  '';
in
{
  config = lib.mkIf cfg.enable {
    users.users.wmbusmeters = {
      isSystemUser = true;
      group = "wmbusmeters";
      extraGroups = [ "dialout" ];
      description = "wmbusmeters service user";
    };

    users.groups.wmbusmeters = { };

    sops.templates = {
      "wmbusmeters.conf" = {
        content = ''
          loglevel=normal
          device=${cfg.device}
          logtelegrams=false
          format=json
          shell=${mqttPublishScript} "${cfg.mqtt.topic}/$METER_NAME" "$METER_JSON"
        '';
        path = "${cfg.configDir}/etc/wmbusmeters.conf";
        owner = "wmbusmeters";
        group = "wmbusmeters";
      };
    }
    // lib.listToAttrs (
      map (meter: {
        name = "wmbusmeters-${meter.name}";
        value = {
          content = ''
            name=${meter.name}
            driver=${meter.driver}
            id=${config.sops.placeholder."wmbusmeters-${meter.name}_id"}
            key=${config.sops.placeholder."wmbusmeters-${meter.name}_key"}
          '';
          path = "${cfg.configDir}/etc/wmbusmeters.d/${meter.name}";
          owner = "wmbusmeters";
          group = "wmbusmeters";
        };
      }) cfg.meters
    );

    systemd.services.wmbusmeters = {
      description = "wmbusmeters wireless M-Bus receiver";
      after = [
        "network-online.target"
        "sops-nix.service"
      ];
      wants = [
        "network-online.target"
        "sops-nix.service"
      ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStartPre = lib.mkIf cfg.discovery.enable "${mqttDiscoveryScript}";
        ExecStart = "${lib.getExe wmbusmeters} --useconfig=${cfg.configDir}";
        Restart = "always";
        RestartSec = "10";

        User = "wmbusmeters";
        Group = "wmbusmeters";

        StateDirectory = "wmbusmeters";
        StateDirectoryMode = "0750";

        LoadCredential = [
          "mqtt_password:${cfg.mqtt.passwordFile}"
        ]
        ++ (map (meter: "meter_id_${meter.name}:${meter.idFile}") cfg.meters);

        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;

        PrivateDevices = false;
        DeviceAllow = [
          "/dev/ttyUSB0 rw"
          "/dev/ttyUSB1 rw"
          "/dev/ttyACM0 rw"
          "/dev/ttyACM1 rw"
        ];
      };
    };
  };
}
