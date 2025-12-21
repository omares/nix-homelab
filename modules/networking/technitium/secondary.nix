{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mares.networking.technitium;
  stateDir = "/var/lib/technitium-dns-server";

  # First boot: login with admin/admin, change password, join cluster
  bootstrapAccountHurl = pkgs.writeText "bootstrap-account.hurl" ''
    # Login with default credentials
    POST http://127.0.0.1:5380/api/user/login
    [FormParams]
    user: admin
    pass: admin
    HTTP 200
    [Captures]
    token: jsonpath "$.token"
    [Asserts]
    jsonpath "$.status" == "ok"

    # Change password
    POST http://127.0.0.1:5380/api/user/changePassword
    [FormParams]
    token: {{token}}
    pass: admin
    newPass: {{password}}
    HTTP 200
    [Asserts]
    jsonpath "$.status" == "ok"

    # Set DNS server domain before joining cluster
    POST http://127.0.0.1:5380/api/settings/set
    [FormParams]
    token: {{token}}
    dnsServerDomain: ${cfg.nodeDomain}
    HTTP 200
    [Asserts]
    jsonpath "$.status" == "ok"

    # Join cluster (syncs everything else automatically!)
    POST http://127.0.0.1:5380/api/admin/cluster/initJoin
    [FormParams]
    token: {{token}}
    secondaryNodeIpAddresses: ${cfg.nodeIpAddress}
    primaryNodeUrl: https://${cfg.domain}:53443/
    primaryNodeIpAddress: ${cfg.primaryServer}
    ignoreCertificateErrors: true
    primaryNodeUsername: admin
    primaryNodePassword: {{password}}
    HTTP *
  '';

  # Already provisioned: login with custom password, ensure cluster join
  provisionedAccountHurl = pkgs.writeText "provisioned-account.hurl" ''
    # Login with custom password
    POST http://127.0.0.1:5380/api/user/login
    [FormParams]
    user: admin
    pass: {{password}}
    HTTP 200
    [Captures]
    token: jsonpath "$.token"
    [Asserts]
    jsonpath "$.status" == "ok"

    # Ensure cluster join (idempotent - HTTP * allows already-joined)
    POST http://127.0.0.1:5380/api/admin/cluster/initJoin
    [FormParams]
    token: {{token}}
    secondaryNodeIpAddresses: ${cfg.nodeIpAddress}
    primaryNodeUrl: https://${cfg.domain}:53443/
    primaryNodeIpAddress: ${cfg.primaryServer}
    ignoreCertificateErrors: true
    primaryNodeUsername: admin
    primaryNodePassword: {{password}}
    HTTP *
  '';

  # Wrapper script
  configScript = pkgs.writeShellScript "technitium-configure" ''
    set -euo pipefail

    SECRETS="$CREDENTIALS_DIRECTORY/hurl-secrets"

    # Wait for API
    echo "Waiting for Technitium API..."
    until ${lib.getExe pkgs.curl} -sf http://127.0.0.1:5380/api/user/login >/dev/null 2>&1; do
      sleep 2
    done
    echo "Technitium API ready"

    # Try provisioned account, if fails run bootstrap (first boot)
    if ${lib.getExe pkgs.hurl} --secrets-file "$SECRETS" ${provisionedAccountHurl}; then
      echo "Configuration applied successfully"
    else
      echo "First boot detected, running setup..."
      ${lib.getExe pkgs.hurl} --secrets-file "$SECRETS" ${bootstrapAccountHurl}
      echo "Setup completed successfully"
    fi
  '';
in
{
  config = lib.mkIf (cfg.enable && cfg.clusterRole == "secondary") {
    # Bootstrap service - runs on boot, triggers config only if not yet configured
    systemd.services.technitium-bootstrap = {
      description = "Bootstrap Technitium DNS configuration (first boot only)";
      after = [ "technitium-dns-server.service" ];
      requires = [ "technitium-dns-server.service" ];
      wantedBy = [ "multi-user.target" ];

      # Only run if cluster config doesn't exist (not yet joined)
      unitConfig = {
        ConditionPathExists = "!${stateDir}/cluster.config";
      };

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${lib.getExe' pkgs.systemd "systemctl"} start --no-block technitium-config.service";
      };
    };

    # Config service - applies Technitium configuration via Hurl
    # Triggered by bootstrap on first boot, or manually via: systemctl start technitium-config
    systemd.services.technitium-config = {
      description = "Configure Technitium DNS via Hurl";
      after = [
        "technitium-dns-server.service"
        "network-online.target"
        "acme-${cfg.domain}.service"
      ];
      requires = [ "technitium-dns-server.service" ];
      wants = [
        "network-online.target"
        "acme-${cfg.domain}.service"
      ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = configScript;
        LoadCredential = "hurl-secrets:${config.sops.secrets.technitium-hurl-secrets.path}";
      };

      restartTriggers = [
        bootstrapAccountHurl
        provisionedAccountHurl
      ];
    };
  };
}
