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
in
{
  config = lib.mkIf cfg.enable {
    services.technitium-dns-server = {
      enable = true;
      openFirewall = true; # Opens 53, 5380, 53443
    };

    # Ensure technitium-dns-server starts after cert.pfx is created
    systemd.services.technitium-dns-server = {
      after = [ "technitium-cert.service" ];
      wants = [ "technitium-cert.service" ];
    };

    networking.firewall = {
      allowedTCPPorts = [
        443 # DoH
        853 # DoT
        53443 # Cluster communication
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

    environment.systemPackages = [ pkgs.hurl ];
  };
}
