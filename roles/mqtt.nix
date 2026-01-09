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
    "easydns"
  ];

  mares.networking.acme.enable = true;

  # Request ACME certificate for MQTT TLS
  security.acme.certs.${acmeHost} = {
    group = "mosquitto";
    reloadServices = [ "mosquitto.service" ];
    keyType = "rsa4096";
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

    dynamicSecurity.enable = true;
  };

}
