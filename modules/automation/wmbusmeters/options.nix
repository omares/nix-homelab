{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;

  meterType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Meter name (used in MQTT topic and Home Assistant entity).";
      };

      driver = mkOption {
        type = types.str;
        description = "Meter driver (e.g., hydrus, multical21).";
      };

      idFile = mkOption {
        type = types.path;
        description = "Path to file containing meter ID (8-digit number).";
      };

      keyFile = mkOption {
        type = types.path;
        description = "Path to file containing decryption key (or NOKEY if unencrypted).";
      };
    };
  };
in
{
  options.mares.automation.wmbusmeters = {
    enable = mkEnableOption "wmbusmeters wireless M-Bus receiver";

    device = mkOption {
      type = types.str;
      default = "auto:t1";
      description = "Device specification (e.g., /dev/ttyACM0:iu891a:t1 or auto:t1).";
    };

    mqtt = {
      host = mkOption {
        type = types.str;
        description = "MQTT broker hostname (e.g., mqtt-01.vm.mares.id).";
      };

      port = mkOption {
        type = types.port;
        default = 8883;
        description = "MQTT broker port.";
      };

      useTls = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to use TLS for MQTT connection.";
      };

      user = mkOption {
        type = types.str;
        default = "wmbusmeters";
        description = "MQTT username.";
      };

      passwordFile = mkOption {
        type = types.path;
        description = "Path to file containing MQTT password.";
      };

      topic = mkOption {
        type = types.str;
        default = "wmbusmeters";
        description = "Base MQTT topic for meter readings.";
      };
    };

    meters = mkOption {
      type = types.listOf meterType;
      default = [ ];
      description = "List of meters to monitor.";
    };

    discovery = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Home Assistant MQTT autodiscovery.";
      };

      prefix = mkOption {
        type = types.str;
        default = "homeassistant";
        description = "MQTT discovery topic prefix.";
      };
    };

    configDir = mkOption {
      type = types.str;
      default = "/var/lib/wmbusmeters";
      description = "Directory for wmbusmeters configuration and state.";
    };
  };
}
