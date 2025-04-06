{ config, lib, mares, ... }:

let
  cfg = config.mares.networking.proxy-nginx;

  proxyNodes = lib.filterAttrs (_: node: node.proxy != null) config.mares.infrastructure.nodes;

  mkVhost = name: nodeCfg: {
    acmeRoot = null;
    enableACME = true;
    forceSSL = nodeCfg.proxy.ssl;
    locations."/" = {
      proxyPass = "${nodeCfg.proxy.protocol}://${nodeCfg.dns.fqdn or nodeCfg.host}:${toString nodeCfg.proxy.port}";
      proxyWebsockets = nodeCfg.proxy.websockets;
      extraConfig =
        ''
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
  };
}
