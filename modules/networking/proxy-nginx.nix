{
  config,
  lib,
  mares,
  ...
}:

let
  cfg = config.mares.networking.proxy-nginx;

  proxyNodes = lib.filterAttrs (_: node: node.proxy != null) config.mares.infrastructure.nodes;

  # Generate list of ACME order-renew services for all proxy vhosts
  acmeOrderRenewServices = lib.mapAttrsToList (
    name: nodeCfg: "acme-order-renew-${nodeCfg.proxy.fqdn}.service"
  ) proxyNodes;

  mkVhost = name: nodeCfg: {
    acmeRoot = null;
    enableACME = true;
    forceSSL = nodeCfg.proxy.ssl;
    locations."/" = {
      proxyPass = "${nodeCfg.proxy.protocol}://${
        nodeCfg.dns.fqdn or nodeCfg.host
      }:${toString nodeCfg.proxy.port}";
      proxyWebsockets = nodeCfg.proxy.websockets;
      extraConfig = ''
        # required when the target is also TLS server with multiple hosts
        proxy_ssl_server_name on;

        # required when the server wants to use HTTP Authentication
        proxy_pass_header Authorization;
      ''
      + nodeCfg.proxy.extraConfig;
    };
    serverName = "${nodeCfg.proxy.fqdn}";
    serverAliases = map (
      subdomain: "${subdomain}.${toString config.mares.infrastructure.proxy.domain}"
    ) (nodeCfg.proxy.subdomains);
  };

in
{
  options.mares.networking.proxy-nginx = {
    enable = lib.mkEnableOption "Nginx proxy configuration";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall = {
      allowedTCPPorts = [
        80
        443
      ];
    };

    services.nginx = {
      enable = true;
      enableReload = true;
      proxyResolveWhileRunning = true;
      recommendedBrotliSettings = true;
      recommendedGzipSettings = true;

      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;

      resolver.addresses = [
        mares.infrastructure.nodes.dns-01.host
        mares.infrastructure.nodes.dns-02.host
      ];
      virtualHosts = lib.mapAttrs mkVhost proxyNodes;
    };

    # Ensure nginx waits for ACME order-renew services to complete.
    # This prevents a race condition where nginx starts with minica-generated
    # self-signed certs before the real Let's Encrypt certs are fetched,
    # which can cause key mismatch errors if state is partially deleted.
    systemd.services.nginx = {
      after = acmeOrderRenewServices;
      wants = acmeOrderRenewServices;
    };

    # Don't start nginx-config-reload on boot/deploy. It should only run
    # when ACME services trigger it after certificate renewals.
    # This prevents a race condition during deploy where all ACME services
    # start simultaneously and trigger nginx-config-reload, causing timeouts.
    systemd.services.nginx-config-reload.wantedBy = lib.mkForce [];
  };
}
