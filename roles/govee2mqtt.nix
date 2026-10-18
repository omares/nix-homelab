{
  config,
  mares,
  ...
}:
let
  mqttNode = mares.infrastructure.nodes.mqtt-01;
in
{
  imports = [ ../modules/automation/govee2mqtt ];

  sops-vault.items = [ "gv2mqtt" ];

  sops.templates."govee2mqtt-env" = {
    content = ''
      GOVEE_MQTT_PASSWORD=${config.sops.placeholder.gv2mqtt-mqtt_password}
    '';
    restartUnits = [ "govee2mqtt.service" ];
  };

  mares.automation.govee2mqtt = {
    enable = true;
    mqtt.host = mqttNode.dns.fqdn;
    environmentFile = config.sops.templates."govee2mqtt-env".path;
    lanScan = [ "192.168.20.112" ];
  };

  systemd.services.govee2mqtt = {
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
  };
}
