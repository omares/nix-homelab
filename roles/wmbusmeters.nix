{
  config,
  mares,
  ...
}:
let
  mqttNode = mares.infrastructure.nodes.mqtt-01;
in
{
  imports = [ ../modules/automation/wmbusmeters ];

  sops-vault.items = [ "wmbusmeters" ];

  mares.automation.wmbusmeters = {
    enable = true;
    device = "/dev/ttyACM0:iu891a:t1";

    mqtt = {
      host = mqttNode.dns.fqdn;
      passwordFile = config.sops.secrets.wmbusmeters-mqtt_password.path;
    };

    meters = [
      {
        name = "water";
        driver = "hydrus";
        idFile = config.sops.secrets.wmbusmeters-water_id.path;
        keyFile = config.sops.secrets.wmbusmeters-water_key.path;
      }
    ];
  };
}
