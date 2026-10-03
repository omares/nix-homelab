{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mares.automation.mosquitto;
  mqttPkg = pkgs.mosquitto;
  dataDir = "/var/lib/mosquitto";

  # Hand-rolled instead of services.mosquitto: that module unconditionally
  # wires in the acl_file/password_file plugins ahead of any authPlugins.
  # Those always return a definitive allow/deny and never defer, so they
  # silently override Dynamic Security's own auth decisions before it is
  # ever consulted (https://github.com/NixOS/nixpkgs/issues/498959).
  # Writing the config ourselves lets Dynamic Security be the sole
  # authority for both login and topic access.
  mosquittoConf = pkgs.writeText "mosquitto.conf" ''
    per_listener_settings true
    persistence true
    log_dest stderr

    listener ${toString cfg.port} ${cfg.bindAddress}
    cafile ${cfg.certDirectory}/chain.pem
    certfile ${cfg.certDirectory}/cert.pem
    keyfile ${cfg.certDirectory}/key.pem
    require_certificate false

    plugin ${mqttPkg.lib}/lib/mosquitto_dynamic_security.so
    plugin_opt_config_file ${cfg.dynamicSecurity.configFile}
    auth_plugin_deny_special_chars true
  '';
in
{
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [
      cfg.port
    ];

    users.users.mosquitto = {
      description = "Mosquitto MQTT Broker Daemon owner";
      group = "mosquitto";
      uid = config.ids.uids.mosquitto;
      home = dataDir;
      createHome = true;
    };

    users.groups.mosquitto.gid = config.ids.gids.mosquitto;

    systemd.services.mosquitto = {
      description = "Mosquitto MQTT Broker Daemon";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "notify";
        NotifyAccess = "main";
        User = "mosquitto";
        Group = "mosquitto";
        RuntimeDirectory = "mosquitto";
        WorkingDirectory = dataDir;
        ExecStart = "${mqttPkg}/bin/mosquitto -c ${mosquittoConf}";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Restart = "on-failure";

        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
        ReadWritePaths = [ dataDir ];
        ReadOnlyPaths = [ cfg.certDirectory ];
      };
    };

    # Provide mosquitto_ctrl config and wrapper for Dynamic Security management
    # Hostname derived from certDirectory path (e.g., /var/lib/acme/mqtt-01.vm.mares.id -> mqtt-01.vm.mares.id)
    environment.etc."mosquitto_ctrl.conf".text = ''
      -h ${baseNameOf cfg.certDirectory}
      -p ${toString cfg.port}
      --cafile /etc/ssl/certs/ca-certificates.crt
      -u admin
    '';

    environment.systemPackages = [
      mqttPkg
      pkgs.openssl
      (pkgs.writeShellScriptBin "mctl" ''
        exec ${mqttPkg}/bin/mosquitto_ctrl -o /etc/mosquitto_ctrl.conf "$@"
      '')
    ];
  };
}
