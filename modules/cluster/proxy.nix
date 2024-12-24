{ config, lib, ... }:

let
  proxyNodes = lib.filterAttrs (_: node: node.proxy != null) config.cluster.nodes;

  mkVhost = name: nodeCfg: {
    enableACME = true;
    forceSSL = nodeCfg.proxy.ssl;
    acmeRoot = null;
    serverName = "${name}.${config.cluster.proxy.domain}";
    serverAliases = map (subdomain: "${subdomain}.${toString config.cluster.proxy.domain}") (
      nodeCfg.proxy.subdomains
    );
    locations."/" = {
      proxyPass = "http://${nodeCfg.host}:${nodeCfg.proxy.port}";
      extraConfig =
        ''
          # required when the target is also TLS server with multiple hosts
          proxy_ssl_server_name on;

          # required when the server wants to use HTTP Authentication
          proxy_pass_header Authorization;
        ''
        + nodeCfg.proxy.extraConfig;
    };
  };

in
{
  config = {
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;

      virtualHosts = lib.mapAttrs mkVhost proxyNodes;
    };
  };
}
