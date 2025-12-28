{
  config,
  lib,
  ...
}:
let
  cfg = config.mares.automation.mosquitto;
in
{
  config = lib.mkIf cfg.enable {
    # Open firewall for MQTT TLS port
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

    services.mosquitto = {
      enable = true;
      listeners = [
        {
          address = cfg.bindAddress;
          port = cfg.port;

          settings = {
            certfile = "${cfg.certDirectory}/cert.pem";
            cafile = "${cfg.certDirectory}/chain.pem";
            keyfile = "${cfg.certDirectory}/key.pem";
          };

          users = lib.mapAttrs (_name: userCfg: {
            passwordFile = userCfg.passwordFile;
            acl = userCfg.acl;
          }) cfg.users;
        }
      ];
    };
  };
}
