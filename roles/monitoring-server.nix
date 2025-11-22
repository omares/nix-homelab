{
  config,
  ...
}:
{
  imports = [
    ../modules/monitoring
  ];

  sops-vault.items = [ "grafana" ];

  mares.monitoring.roles = [ "monitoring-server" ];

  fileSystems."/var/lib/prometheus2" = {
    device = "/dev/disk/by-label/prometheus-data";
    autoResize = true;
    fsType = "ext4";
  };

  # Metrics are pushed by Alloy agents on each node via remote_write
  # No direct scrape targets needed - pure push model
  mares.monitoring.prometheus.enable = true;

  mares.monitoring.loki.enable = true;

  mares.monitoring.grafana = {
    enable = true;
    adminPasswordFile = config.sops.secrets.grafana-password.path;
  };
}
