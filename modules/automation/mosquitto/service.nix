{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mares.automation.mosquitto;
  mqttPkg = config.services.mosquitto.package;
in
{
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [
      cfg.port
    ];

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
            require_certificate = false;
          };

          authPlugins = lib.mkIf cfg.dynamicSecurity.enable [
            {
              plugin = "${mqttPkg.lib}/lib/mosquitto_dynamic_security.so";
              options = {
                config_file = cfg.dynamicSecurity.configFile;
              };
            }
          ];

          # mosquitto 2.1+ always loads the acl_file/password_file plugins
          # alongside authPlugins; since we only manage users via Dynamic
          # Security, an empty acl/passwd file would otherwise veto every
          # login and publish (https://github.com/NixOS/nixpkgs/issues/498959)
          omitPasswordAuth = cfg.dynamicSecurity.enable;
          acl = lib.mkIf cfg.dynamicSecurity.enable [ "pattern readwrite #" ];
        }
      ];
    };

    # Provide mosquitto_ctrl config and wrapper for Dynamic Security management
    # Hostname derived from certDirectory path (e.g., /var/lib/acme/mqtt-01.vm.mares.id -> mqtt-01.vm.mares.id)
    environment.etc."mosquitto_ctrl.conf" = lib.mkIf cfg.dynamicSecurity.enable {
      text = ''
        -h ${builtins.baseNameOf cfg.certDirectory}
        -p ${toString cfg.port}
        --cafile /etc/ssl/certs/ca-certificates.crt
        -u admin
      '';
    };

    environment.systemPackages = lib.mkIf cfg.dynamicSecurity.enable [
      mqttPkg
      pkgs.openssl
      (pkgs.writeShellScriptBin "mctl" ''
        exec ${mqttPkg}/bin/mosquitto_ctrl -o /etc/mosquitto_ctrl.conf "$@"
      '')
    ];
  };
}
