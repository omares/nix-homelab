{
  inputs,
  lib,
  cluster,
  ...
}:

let
  proxyNodes = lib.filterAttrs (_: node: node.proxy != null) cluster.nodes;

  mkVhost = name: nodeCfg: {
    enableACME = true;
    forceSSL = nodeCfg.proxy.ssl;
    acmeRoot = null;
    serverName = "${name}.${cluster.proxy.domain}";
    serverAliases = map (subdomain: "${subdomain}.${toString cluster.proxy.domain}") (
      nodeCfg.proxy.subdomains
    );
    locations."/" = {
      proxyPass = "${nodeCfg.proxy.protocol}://${nodeCfg.host}:${toString nodeCfg.proxy.port}";
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
  };

in
{
  imports = [

    inputs.sops-nix.nixosModules.sops
    inputs.nix-sops-vault.nixosModules.sops-vault
    ../modules/security/acme.nix
  ];
  config = {
    networking.firewall = {
      allowedTCPPorts = [
        80
        443
      ];
    };

    sops-vault.items = [
      "easydns"
    ];

    services.nginx = {
      enable = true;
      recommendedBrotliSettings = true;
      recommendedGzipSettings = true;

      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;

      virtualHosts = lib.mapAttrs mkVhost proxyNodes;
    };
  };
}
