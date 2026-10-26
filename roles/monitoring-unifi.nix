{
  config,
  mares,
  ...
}:
let
  exporterCfg = config.services.prometheus.exporters.unpoller;
in
{
  imports = [
    ../modules/monitoring
  ];

  sops-vault.items = [ "unifi" ];

  sops.secrets.unifi-monitoring_password = {
    owner = exporterCfg.user;
    restartUnits = [ "prometheus-unpoller-exporter.service" ];
  };

  services.prometheus.exporters.unpoller = {
    enable = true;
    listenAddress = "127.0.0.1";
    log.quiet = true;
    controllers = [
      {
        # Through the proxy, which serves a valid certificate for the UDM
        inherit (mares.infrastructure.nodes.unifi.proxy) url;
        # Local admin with a View Only role for Network
        user = "monitoring";
        pass = config.sops.secrets.unifi-monitoring_password.path;
        verify_ssl = true;
        sites = "all";
        save_sites = true;
      }
    ];
  };

  mares.monitoring.alloy.extraScrapeTargets = [
    {
      job = "unpoller";
      targets = [ "localhost:${toString exporterCfg.port}" ];
    }
  ];
}
