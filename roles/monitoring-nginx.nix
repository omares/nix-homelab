{
  config,
  lib,
  ...
}:
{
  imports = [
    ../modules/monitoring
  ];

  mares.monitoring.roles = [ "monitoring-nginx" ];

  # Enable nginx status page for the exporter to scrape
  services.nginx.statusPage = true;

  # nginx exporter - exposes nginx stub_status as Prometheus metrics
  services.prometheus.exporters.nginx.enable = true;

  # node-cert exporter - monitors ACME certificate expiry
  services.prometheus.exporters.node-cert = {
    enable = true;
    paths = [ "/var/lib/acme" ];
  };

  # Alloy scrapes these exporters locally and pushes to Prometheus
  mares.monitoring.alloy.extraScrapeTargets = [
    {
      job = "nginx";
      targets = [ "localhost:9113" ];
    }
    {
      job = "node_cert";
      targets = [ "localhost:9141" ];
    }
  ];
}
