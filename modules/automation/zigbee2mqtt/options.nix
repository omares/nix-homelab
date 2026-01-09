{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.mares.automation.zigbee2mqtt = {
    enable = mkEnableOption "Zigbee2MQTT bridge";

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to open the firewall for the frontend port.";
    };

    serialPort = mkOption {
      type = types.str;
      description = "Path to USB adapter (e.g., /dev/serial/by-id/...).";
    };

    channel = mkOption {
      type = types.ints.between 11 26;
      default = 20;
      description = "Zigbee channel (11-26). Channel 20 avoids WiFi interference on channels 1 and 11.";
    };

    transmitPower = mkOption {
      type = types.int;
      default = 10;
      description = "Transmit power in dBm.";
    };

    frontend = {
      port = mkOption {
        type = types.port;
        default = 8080;
        description = "Port for the web frontend.";
      };

      bindAddress = mkOption {
        type = types.str;
        default = "0.0.0.0";
        description = "IP address to bind the frontend to.";
      };
    };

    mqtt = {
      server = mkOption {
        type = types.str;
        description = "MQTT broker URL (e.g., mqtts://mqtt-01.vm.mares.id:8883).";
      };

      user = mkOption {
        type = types.str;
        default = "zigbee2mqtt";
        description = "MQTT username.";
      };

      passwordFile = mkOption {
        type = types.path;
        description = "Path to file containing MQTT password.";
      };
    };

    networkKeyFile = mkOption {
      type = types.path;
      description = "Path to file containing network key as JSON array (e.g., [1, 2, 3, ...]).";
    };

    panIdFile = mkOption {
      type = types.path;
      description = "Path to file containing PAN ID as decimal number.";
    };

    extPanIdFile = mkOption {
      type = types.path;
      description = "Path to file containing extended PAN ID as JSON array (e.g., [221, 221, ...]).";
    };
  };
}
