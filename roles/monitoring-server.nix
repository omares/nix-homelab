{
  config,
  lib,
  ...
}:
let
  cfg = config.mares.infrastructure;
in
{
  imports = [
    ../modules/monitoring
  ];

  sops-vault.items = [
    "grafana"
    "influxdb"
  ];

  fileSystems."/var/lib/prometheus2" = {
    device = "/dev/disk/by-label/prometheus-data";
    autoResize = true;
    fsType = "ext4";
  };

  fileSystems."/var/lib/influxdb2" = {
    device = "/dev/disk/by-label/influxdb-data";
    autoResize = true;
    fsType = "ext4";
  };

  mares.monitoring.prometheus = {
    enable = true;
    probeTargets = lib.mapAttrs (_: node: {
      inherit (node.proxy) url;
      domains = [ node.proxy.fqdn ] ++ map (sub: "${sub}.${cfg.proxy.domain}") node.proxy.subdomains;
    }) (lib.filterAttrs (_: node: node.proxy != null) cfg.nodes);
  };

  mares.monitoring.loki.enable = true;

  sops.secrets.influxdb-admin_password.owner = "influxdb2";
  sops.secrets.influxdb-admin_token.owner = "influxdb2";

  mares.monitoring.influxdb = {
    enable = true;
    adminPasswordFile = config.sops.secrets.influxdb-admin_password.path;
    adminTokenFile = config.sops.secrets.influxdb-admin_token.path;
    hassTokenFile = config.sops.secrets.influxdb-hass_token.path;
  };

  mares.monitoring.grafana = {
    enable = true;
    adminPasswordFile = config.sops.secrets.grafana-password.path;
    secretKeyFile = config.sops.secrets.grafana-secret_key.path;
    influxdbTokenFile = config.sops.secrets.influxdb-hass_token.path;
  };
}
