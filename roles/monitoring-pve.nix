{
  config,
  lib,
  ...
}:
let
  # Filter nodes that start with "pve-" and extract their host IPs
  pveNodes = lib.filterAttrs (name: _: lib.hasPrefix "pve-" name) config.mares.infrastructure.nodes;
  pveTargets = lib.mapAttrsToList (_: node: node.host) pveNodes;
in
{
  imports = [
    ../modules/monitoring
  ];

  sops-vault.items = [ "pve" ];

  # PVE exporter - monitors Proxmox VE cluster
  services.prometheus.exporters.pve = {
    enable = true;
    environmentFile = config.sops.templates."pve-exporter-env".path;
    extraFlags = [ "--collector.config" ];
  };

  # Sops template for PVE exporter credentials
  sops.templates."pve-exporter-env" = {
    content = ''
      PVE_USER=${config.sops.placeholder.pve-user}
      PVE_TOKEN_NAME=${config.sops.placeholder.pve-token_name}
      PVE_TOKEN_VALUE=${config.sops.placeholder.pve-token_secret}
      PVE_VERIFY_SSL=false
    '';
    restartUnits = [ "prometheus-pve-exporter.service" ];
  };

  # Multi-target scraping for all PVE nodes (derived from infrastructure.nodes)
  mares.monitoring.alloy.pveTargets = pveTargets;
}
