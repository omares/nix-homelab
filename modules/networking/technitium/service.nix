{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mares.networking.technitium;
  stateDir = "/var/lib/technitium-dns-server";
  pfxPath = "${stateDir}/cert.pfx";

  # PFX creation script
  pfxScript = pkgs.writeShellScript "create-technitium-pfx" ''
    set -euo pipefail
    ACME_DIR="$1"
    PFX_PATH="$2"

    if [ ! -f "$PFX_PATH" ] || [ "$ACME_DIR/fullchain.pem" -nt "$PFX_PATH" ]; then
      echo "Creating PFX certificate..."
      ${lib.getExe pkgs.openssl} pkcs12 -export \
        -out "$PFX_PATH" \
        -inkey "$ACME_DIR/key.pem" \
        -in "$ACME_DIR/cert.pem" \
        -certfile "$ACME_DIR/chain.pem" \
        -passout pass:
      chown nobody:nogroup "$PFX_PATH"
      chmod 640 "$PFX_PATH"
      echo "PFX certificate created at $PFX_PATH"
    else
      echo "PFX certificate already up to date"
    fi
  '';

  configEntries = ''
    # DNS Settings
    POST http://127.0.0.1:5380/api/settings/set
    [FormParams]
    token: {{token}}
    dnsServerDomain: ${cfg.domain}
    forwarders: ${lib.concatStringsSep "," cfg.forwarders}
    forwarderProtocol: Https
    dnssecValidation: true
    serveStale: true
    serveStaleTtl: 259200
    cacheMinimumRecordTtl: 10
    cacheMaximumRecordTtl: 604800
    enableBlocking: true
    blockingType: CustomAddress
    customBlockingAddresses: ${cfg.blockPageAddress}
    blockListUrls: ${lib.concatStringsSep "," cfg.blockLists}
    blockListUpdateIntervalHours: 24
    recursion: AllowOnlyForPrivateNetworks
    preferIPv6: false
    HTTP 200
    [Asserts]
    jsonpath "$.status" == "ok"

    # TLS Configuration
    POST http://127.0.0.1:5380/api/settings/set
    [FormParams]
    token: {{token}}
    enableDnsOverHttp: false
    enableDnsOverHttps: true
    enableDnsOverHttp3: true
    enableDnsOverTls: true
    enableDnsOverQuic: true
    dnsOverHttpsPort: 443
    dnsOverTlsPort: 853
    dnsOverQuicPort: 853
    dnsTlsCertificatePath: cert.pfx
    dnsTlsCertificatePassword:
    HTTP 200
    [Asserts]
    jsonpath "$.status" == "ok"

    # TSIG Key Configuration (pipe-separated: keyName|sharedSecret|algorithmName)
    POST http://127.0.0.1:5380/api/settings/set
    [FormParams]
    token: {{token}}
    tsigKeys: ${cfg.tsigKeyName}|{{tsig_key}}|hmac-sha256
    HTTP 200
    [Asserts]
    jsonpath "$.status" == "ok"

    # Install Apps
    POST http://127.0.0.1:5380/api/apps/downloadAndInstall
    [FormParams]
    token: {{token}}
    name: Advanced Blocking
    url: https://download.technitium.com/dns/apps/AdvancedBlockingApp-v9.1.zip
    HTTP *

    POST http://127.0.0.1:5380/api/apps/downloadAndInstall
    [FormParams]
    token: {{token}}
    name: Block Page
    url: https://download.technitium.com/dns/apps/BlockPageApp-v7.zip
    HTTP *

    POST http://127.0.0.1:5380/api/apps/downloadAndInstall
    [FormParams]
    token: {{token}}
    name: Query Logs (Sqlite)
    url: https://download.technitium.com/dns/apps/QueryLogsSqliteApp-v8.zip
    HTTP *

    # Create ${cfg.zone} Zone
    POST http://127.0.0.1:5380/api/zones/create
    [FormParams]
    token: {{token}}
    zone: ${cfg.zone}
    type: Primary
    HTTP *

    # DNSSEC: Sign ${cfg.zone} zone
    POST http://127.0.0.1:5380/api/zones/dnssec/sign
    [FormParams]
    token: {{token}}
    zone: ${cfg.zone}
    algorithm: ECDSA
    curve: P256
    dnsKeyTtl: 86400
    zskRolloverDays: 90
    nxProof: NSEC3
    iterations: 0
    saltLength: 0
    HTTP *

    # DNS Server A Records (dns.${cfg.zone} -> all server addresses)
    ${lib.concatMapStringsSep "\n\n" (ip: ''
      POST http://127.0.0.1:5380/api/zones/records/add
      [FormParams]
      token: {{token}}
      domain: dns.${cfg.zone}
      zone: ${cfg.zone}
      type: A
      ipAddress: ${ip}
      ttl: 300
      overwrite: true
      HTTP 200
      [Asserts]
      jsonpath "$.status" == "ok"'') cfg.serverAddresses}

    # DNS A Records
    ${lib.concatMapStringsSep "\n\n" (record: ''
      POST http://127.0.0.1:5380/api/zones/records/add
      [FormParams]
      token: {{token}}
      domain: ${record.fqdn}
      zone: ${cfg.zone}
      type: A
      ipAddress: ${record.ip}
      ttl: 3600
      overwrite: true
      HTTP 200
      [Asserts]
      jsonpath "$.status" == "ok"'') cfg.dnsRecords}

    # Wildcard *.${cfg.zone} -> proxy
    POST http://127.0.0.1:5380/api/zones/records/add
    [FormParams]
    token: {{token}}
    domain: *.${cfg.zone}
    zone: ${cfg.zone}
    type: A
    ipAddress: ${cfg.proxyHost}
    ttl: 3600
    overwrite: true
    HTTP 200
    [Asserts]
    jsonpath "$.status" == "ok"

    # Allowed Domains (bypass blocking)
    ${lib.concatMapStringsSep "\n\n" (d: ''
      POST http://127.0.0.1:5380/api/allowed/add
      [FormParams]
      token: {{token}}
      domain: ${d}
      HTTP *'') cfg.allowedDomains}

    # Conditional Forwarders
    ${lib.concatMapStringsSep "\n\n" (fwd: ''
      POST http://127.0.0.1:5380/api/zones/create
      [FormParams]
      token: {{token}}
      zone: ${fwd.zone}
      type: Forwarder
      protocol: Udp
      forwarder: ${fwd.forwarder}
      HTTP *'') cfg.conditionalForwarders}

  '';

  # First boot: login with admin/admin, change password, configure
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

    ${configEntries}
  '';

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

    ${configEntries}
  '';

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
  config = lib.mkIf cfg.enable {
    services.technitium-dns-server = {
      enable = true;
      openFirewall = true; # Opens 53, 5380, 53443
    };

    networking.firewall = {
      allowedTCPPorts = [
        443 # DoH
        853 # DoT
      ];
      allowedUDPPorts = [
        853 # DoQ
      ];
    };

    # ACME certificate for DoT/DoH/DoQ
    security.acme.certs.${cfg.domain} = { };

    # Create PFX certificate from ACME certs (Technitium requires PFX format)
    systemd.services.technitium-cert = {
      description = "Create Technitium PFX certificate from ACME";
      after = [ "acme-${cfg.domain}.service" ];
      requires = [ "acme-${cfg.domain}.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pfxScript} ${cfg.acmeDirectory} ${pfxPath}";
        ExecStartPost = "${lib.getExe' pkgs.systemd "systemctl"} try-reload-or-restart technitium-dns-server.service";
      };
    };

    # Bootstrap service - runs on boot, triggers config only if not yet configured
    systemd.services.technitium-bootstrap = {
      description = "Bootstrap Technitium DNS configuration (first boot only)";
      after = [ "technitium-dns-server.service" ];
      requires = [ "technitium-dns-server.service" ];
      wantedBy = [ "multi-user.target" ];

      # Only run if zone file doesn't exist (not yet configured)
      unitConfig = {
        ConditionPathExists = "!${stateDir}/zones/${cfg.zone}.zone";
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

    environment.systemPackages = [ pkgs.hurl ];
  };
}
