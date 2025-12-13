{
  config,
  ...
}:
let
  bindAddress = config.mares.starr.radarr.bindAddress;
in
{
  imports = [ ../modules/monitoring ];

  services.prometheus.exporters.exportarr-radarr = {
    enable = true;
    url = "http://${bindAddress}:7878";
    port = 9707;
    apiKeyFile = config.sops.secrets.radarr-api_key.path;
  };

  mares.monitoring.alloy.extraScrapeTargets = [
    {
      job = "radarr";
      targets = [ "localhost:9707" ];
    }
  ];
}
