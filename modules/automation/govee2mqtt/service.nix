{
  config,
  lib,
  ...
}:
let
  cfg = config.mares.automation.govee2mqtt;
in
{
  config = lib.mkIf cfg.enable {
    # govee2mqtt has no MQTT TLS support, tunnel it to the TLS-only broker
    services.stunnel = {
      enable = true;
      clients.govee2mqtt-mqtt = {
        accept = "127.0.0.1:${toString cfg.mqtt.localPort}";
        connect = "${cfg.mqtt.host}:${toString cfg.mqtt.port}";
        checkHost = cfg.mqtt.host;
      };
    };

    services.govee2mqtt = {
      enable = true;
      inherit (cfg) environmentFile;
    };

    systemd.services.govee2mqtt = {
      after = [ "stunnel.service" ];
      requires = [ "stunnel.service" ];
      environment = {
        GOVEE_MQTT_HOST = "127.0.0.1";
        GOVEE_MQTT_PORT = toString cfg.mqtt.localPort;
        GOVEE_MQTT_USER = cfg.mqtt.user;
      }
      // lib.optionalAttrs (cfg.lanScan != [ ]) {
        GOVEE_LAN_SCAN = lib.concatStringsSep "," cfg.lanScan;
      };
    };

    networking.firewall.allowedUDPPorts = lib.mkIf cfg.openFirewall [ 4002 ];
  };
}
