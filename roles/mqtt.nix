{
  config,
  nodeCfg,
  ...
}:
let
  acmeHost = nodeCfg.dns.fqdn;
in
{
  imports = [
    ../modules/automation/mosquitto
    ../modules/security/acme.nix
  ];

  sops-vault.items = [
    "mqtt"
    "easydns"
  ];

  mares.networking.acme.enable = true;

  # Request ACME certificate for MQTT TLS
  security.acme.certs.${acmeHost} = {
    group = "mosquitto";
    reloadServices = [ "mosquitto.service" ];
  };

  # Ensure mosquitto waits for ACME certificate
  systemd.services.mosquitto = {
    after = [ "acme-${acmeHost}.service" ];
    wants = [ "acme-${acmeHost}.service" ];
  };

  mares.automation.mosquitto = {
    enable = true;
    bindAddress = nodeCfg.host;
    certDirectory = config.security.acme.certs.${acmeHost}.directory;

    users = {
      hass = {
        passwordFile = config.sops.secrets.mqtt-hass_password.path;
        acl = [ "readwrite #" ];
      };
      shelly = {
        passwordFile = config.sops.secrets.mqtt-shelly_password.path;
        acl = [
          "readwrite shellies/#"
          "readwrite shelly/#"
          "readwrite shellies_discovery/#"
        ];
      };
    };
  };
}
