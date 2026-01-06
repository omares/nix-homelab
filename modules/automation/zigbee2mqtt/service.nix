{
  config,
  lib,
  utils,
  ...
}:
let
  cfg = config.mares.automation.zigbee2mqtt;
  upstream = config.services.zigbee2mqtt;
  configPath = "${upstream.dataDir}/configuration.yaml";
  credentialsDir = "/run/credentials/zigbee2mqtt.service";

  settings = {
    permit_join = false;

    serial = {
      port = cfg.serialPort;
      adapter = "ember";
      rtscts = false;
      baudrate = 115200;
    };

    mqtt = {
      server = cfg.mqtt.server;
      user = cfg.mqtt.user;
      password._secret = "${credentialsDir}/mqtt_password";
      base_topic = "zigbee2mqtt";
      version = 5;
      ca = "/etc/ssl/certs/ca-certificates.crt";
    };

    frontend = {
      enabled = true;
      port = cfg.frontend.port;
      host = cfg.frontend.bindAddress;
      package = "zigbee2mqtt-windfront";
    };

    advanced = {
      channel = cfg.channel;
      transmit_power = cfg.transmitPower;
      network_key = {
        _secret = "${credentialsDir}/network_key";
        quote = false;
      };
      pan_id = {
        _secret = "${credentialsDir}/pan_id";
        quote = false;
      };
      ext_pan_id = {
        _secret = "${credentialsDir}/ext_pan_id";
        quote = false;
      };
      last_seen = "ISO_8601";
      log_level = "warn";
    };

    homeassistant = {
      enabled = true;
      discovery_topic = "homeassistant";
      status_topic = "homeassistant/status";
    };

    availability = {
      enabled = true;
      active = {
        timeout = 10;
      };
      passive = {
        timeout = 1500;
      };
    };

    device_options = {
      retain = true;
      qos = 1;
    };
  };
in
{
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.frontend.port ];

    services.zigbee2mqtt = {
      enable = true;
      inherit settings;
    };

    systemd.services.zigbee2mqtt = {
      serviceConfig.LoadCredential = [
        "mqtt_password:${cfg.mqtt.passwordFile}"
        "network_key:${cfg.networkKeyFile}"
        "pan_id:${cfg.panIdFile}"
        "ext_pan_id:${cfg.extPanIdFile}"
      ];

      preStart = lib.mkForce (utils.genJqSecretsReplacementSnippet settings configPath);
    };
  };
}
