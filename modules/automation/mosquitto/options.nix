{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.mares.automation.mosquitto = {
    enable = mkEnableOption "Mosquitto MQTT broker";

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to open the firewall for the MQTT port.";
    };

    port = mkOption {
      type = types.port;
      default = 8883;
      description = "Port for TLS-encrypted MQTT connections.";
    };

    bindAddress = mkOption {
      type = types.str;
      description = "IP address to bind the MQTT listener to.";
    };

    certDirectory = mkOption {
      type = types.str;
      description = "Path to ACME certificate directory containing cert.pem, chain.pem, key.pem.";
    };

    dynamicSecurity = {
      enable = mkEnableOption "Mosquitto Dynamic Security plugin for flexible authentication";

      configFile = mkOption {
        type = types.str;
        default = "/var/lib/mosquitto/dynamic-security.json";
        description = "Path to the Dynamic Security JSON config file.";
      };
    };

  };
}
