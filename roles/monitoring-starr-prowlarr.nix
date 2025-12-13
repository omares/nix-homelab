{
  config,
  ...
}:
let
  bindAddress = config.mares.starr.prowlarr.bindAddress;
in
{
  imports = [ ../modules/monitoring ];

  services.prometheus.exporters.exportarr-prowlarr = {
    enable = true;
    url = "http://${bindAddress}:9696";
    port = 9709;
    apiKeyFile = config.sops.secrets.prowlarr-api_key.path;
  };

  mares.monitoring.alloy.extraScrapeTargets = [
    {
      job = "prowlarr";
      targets = [ "localhost:9709" ];
    }
  ];
}
