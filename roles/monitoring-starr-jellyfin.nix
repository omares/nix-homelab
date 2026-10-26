{
  config,
  ...
}:
{
  imports = [ ../modules/monitoring ];

  mares.monitoring.alloy.extraScrapeTargets = [
    {
      job = "jellyfin";
      targets = [ "${config.mares.starr.jellyfin.bindAddress}:8096" ];
    }
  ];
}
