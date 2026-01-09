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
      openFirewall = true;
    };

    networking.firewall = {
      allowedTCPPorts = [
        443
        853
        53443
      ];
      allowedUDPPorts = [
        853
      ];
    };

    # ACME certificate for DoT/DoH/DoQ
    security.acme.certs.${cfg.domain} = {
      reloadServices = [ "technitium-cert.service" ];
    };

    # Create PFX certificate for Technitium
    systemd.services.technitium-cert = {
      description = "Create Technitium PFX certificate from ACME";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pfxScript} ${cfg.acmeDirectory} ${pfxPath}";
      };
    };

    systemd.paths.technitium-cert-watch = {
      description = "Watch Technitium PFX certificate for changes";
      wantedBy = [ "multi-user.target" ];

      pathConfig = {
        PathChanged = pfxPath;
        Unit = "technitium-dns-server.service";
      };
    };

    environment.systemPackages = [ pkgs.hurl ];
  };
}
