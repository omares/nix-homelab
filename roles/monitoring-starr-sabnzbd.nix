{
  config,
  ...
}:
let
  bindAddress = config.mares.starr.sabnzbd.bindAddress;
in
{
  imports = [ ../modules/monitoring ];

  mares.monitoring.roles = [ "monitoring-starr-sabnzbd" ];

  services.prometheus.exporters.sabnzbd = {
    enable = true;
    port = 9710;
    servers = [
      {
        baseUrl = "http://${bindAddress}:8080";
        apiKeyFile = config.sops.secrets.sabnzbd-api_key.path;
      }
    ];
  };

  mares.monitoring.alloy.extraScrapeTargets = [
    {
      job = "sabnzbd";
      targets = [ "localhost:9710" ];
    }
  ];
}
