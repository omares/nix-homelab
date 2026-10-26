{
  config,
  ...
}:
{
  imports = [
    ../modules/monitoring
  ];

  sops-vault.items = [ "technitium" ];

  mares.monitoring.alloy.extraScrapeTargets = [
    {
      job = "technitium";
      targets = [ "localhost:5380" ];
      metricsPath = "/api/dashboard/metrics/text";
      metricPrefix = "technitium_";
      bearerTokenFile = config.sops.secrets.technitium-monitoring_token.path;
    }
  ];
}
