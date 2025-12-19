{
  config,
  lib,
  nodeCfg,
  mares,
  ...
}:
let
  zone = mares.infrastructure.proxy.domain;
  domain = "dns.${zone}";
  dnsNodes = lib.filterAttrs (_: node: node.dns != null) mares.infrastructure.nodes;
  technitiumNodes = lib.filterAttrs (
    _: node: lib.elem "technitium" (node.tags or [ ])
  ) mares.infrastructure.nodes;
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

      inherit zone domain;
      blockPageAddress = nodeCfg.host;
      acmeDirectory = config.security.acme.certs.${domain}.directory;
      serverAddresses = lib.mapAttrsToList (_: node: node.host) technitiumNodes;
      dnsRecords = lib.mapAttrsToList (_: node: {
        fqdn = node.dns.fqdn;
        ip = node.host;
      }) dnsNodes;

      proxyHost = "10.10.22.103";
      tsigKeyName = "technitium-cluster";

      forwarders = [
        "https://zero.dns0.eu/"
        "https://dns.adguard-dns.com/dns-query"
        "https://dns.cloudflare.com/dns-query"
        "https://dns.quad9.net/dns-query"
      ];

      blockLists = [
        "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt"
        "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.txt"
      ];

      allowedDomains = [
        "controlplane.tailscale.com"
        "login.tailscale.com"
        "log.tailscale.io"
        "pkgs.tailscale.com"
      ];

      conditionalForwarders = [
        {
          zone = "20.168.192.in-addr.arpa";
          forwarder = "192.168.20.1";
        }
        {
          zone = "30.168.192.in-addr.arpa";
          forwarder = "192.168.30.1";
        }
        {
          zone = "40.168.192.in-addr.arpa";
          forwarder = "192.168.40.1";
        }
        {
          zone = "50.168.192.in-addr.arpa";
          forwarder = "192.168.50.1";
        }
        {
          zone = "22.10.10.in-addr.arpa";
          forwarder = "10.10.22.1";
        }
      ];
    };
  };
}
