{
  config,
  ...
}:
let
  bindAddress = config.mares.starr.sonarr.bindAddress;
in
{
  imports = [ ../modules/monitoring ];

  services.prometheus.exporters.exportarr-sonarr = {
    enable = true;
    url = "http://${bindAddress}:8989";
    port = 9708;
    apiKeyFile = config.sops.secrets.sonarr-api_key.path;
  };

  mares.monitoring.alloy.extraScrapeTargets = [
    {
      job = "sonarr";
      targets = [ "localhost:9708" ];
    }
  ];
}
