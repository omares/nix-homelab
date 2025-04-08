{
  config,
  lib,
  nodeCfg,
  ...
}:
{
  imports = [
    ../modules/monitoring/prometheus.nix
  ];

  fileSystems."/var/lib/prometheus2" = {
    device = "/dev/disk/by-label/prometheus-data";
    autoResize = true;
    fsType = "ext4";
  };

  mares.monitoring.prometheus = {
    enable = true;
  };
}
