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

    users = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            passwordFile = mkOption {
              type = types.path;
              description = "Path to file containing the user's password.";
            };
            acl = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "ACL rules for this user (e.g., 'readwrite #').";
            };
          };
        }
      );
      default = { };
      description = "MQTT users with their password files and ACL rules.";
    };
  };
}
