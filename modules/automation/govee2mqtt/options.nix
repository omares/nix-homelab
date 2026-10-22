{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.mares.automation.govee2mqtt = {
    enable = mkEnableOption "govee2mqtt bridge for Govee devices (LAN API only)";

    mqtt = {
      host = mkOption {
        type = types.str;
        description = "MQTT broker hostname (e.g., mqtt-01.vm.mares.id).";
      };

      port = mkOption {
        type = types.port;
        default = 8883;
        description = "MQTT broker TLS port.";
      };

      user = mkOption {
        type = types.str;
        default = "govee2mqtt";
        description = "MQTT username.";
      };

      localPort = mkOption {
        type = types.port;
        default = 1883;
        description = "Local plaintext port of the TLS tunnel govee2mqtt connects to.";
      };
    };

    environmentFile = mkOption {
      type = types.path;
      description = "Environment file containing GOVEE_MQTT_PASSWORD.";
    };

    lanScan = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Device IPs to query directly, needed when multicast discovery does not reach the devices (e.g., across VLANs).";
    };

    httpPort = mkOption {
      type = types.port;
      default = 8056;
      description = "Port of the govee2mqtt web UI.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Open UDP 4002 for Govee LAN API responses and the web UI port.";
    };
  };
}
