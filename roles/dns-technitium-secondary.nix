{
  config,
  lib,
  name,
  nodeCfg,
  mares,
  ...
}:
let
  zone = mares.infrastructure.proxy.domain;
  domain = "dns.${zone}";

  # Find the primary node IP from technitium-primary tagged nodes
  primaryNodes = lib.filterAttrs (
    _: node: lib.elem "technitium-primary" (node.tags or [ ])
  ) mares.infrastructure.nodes;
  primaryServer = (builtins.head (lib.attrValues primaryNodes)).host;
in
{
  imports = [
    ../modules/networking/technitium
    ../modules/networking/resolved.nix
    ../modules/security/acme.nix
  ];

  sops-vault.items = [
    "atuin"
    "easydns"
    "technitium"
  ];

  mares.networking = {
    acme.enable = true;

    technitium = {
      enable = true;

      # Minimal config - everything else syncs from primary
      inherit zone domain;
      acmeDirectory = config.security.acme.certs.${domain}.directory;

      # Cluster configuration
      clusterRole = "secondary";
      clusterDomain = zone;
      nodeIpAddress = nodeCfg.host;
      nodeDomain = "${name}.${zone}";
      inherit primaryServer;
    };
  };
}
