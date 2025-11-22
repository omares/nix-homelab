{
  config,
  lib,
  mares,
  ...
}:
let
  hostname = config.networking.hostName;
  nodeHost = mares.infrastructure.nodes.${hostname}.host;
in
{
  imports = [
    ../modules/monitoring
  ];

  mares.monitoring.roles = [ "monitoring-client" ];

  mares.monitoring.alloy = {
    enable = true;
    listenAddress = nodeHost;
  };
}
