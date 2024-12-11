{ config, lib, ... }:

with lib;
let
  proxyNodes = lib.filterAttrs (name: node: node.proxy != null) config.cluster.nodes;

  mkDomains =
    name: proxy: map (prefix: "${prefix}.${config.cluster.proxy.domain}") [ name ] ++ proxy.subdomains;

  mkServiceConfig =
    name: node:
    let
      proxy = node.proxy;
      domains = mkDomains name proxy;
      vhosts = builtins.listToAttrs (
        map (domain: {
          name = domain;
          value = {
            inherit (proxy) ssl extraConfig;
            enableACME = proxy.ssl;
            forceSSL = proxy.ssl;

            locations."/" = ''
              proxy_pass http://${node.host}:${toString proxy.port};
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
          };
        }) domains
      );
    in
    vhosts;
in
{
  options = {
    cluster.proxy = {
      domain = mkOption {
        type = types.str;
        description = "Base domain for all services";
      };

      acmeEmail = mkOption {
        type = types.str;
        description = "Email address for ACME certificate notifications";
      };
    };

    cluster.nodes = mkOption {
      type = types.attrsOf (
        types.submodule {
          options.proxy = mkOption {
            type = types.nullOr (
              types.submodule {
                options = {
                  port = mkOption {
                    type = types.port;
                    description = "Target port";
                  };

                  subdomains = mkOption {
                    type = types.listOf types.str;
                    default = [ ];
                    description = "Additional subdomains for this service";
                  };

                  ssl = mkOption {
                    type = types.bool;
                    default = true;
                    description = "Enable SSL for this service";
                  };

                  extraConfig = mkOption {
                    type = types.lines;
                    default = "";
                    description = "Additional nginx configuration for this virtual host";
                  };
                };
              }
            );
            default = null;
            description = "Proxy configuration for this node";
          };
        }
      );
    };
  };

  config = {
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;

      virtualHosts = lib.foldl' (acc: service: acc // (mkServiceConfig service.name service.value)) { } (
        lib.mapAttrsToList lib.nameValuePair proxyNodes
      );
    };

    # security.acme = {
    #   acceptTerms = true;
    #   defaults.email = config.cluster.proxy.acmeEmail;
    # };
  };
}
