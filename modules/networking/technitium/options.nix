{
  lib,
  ...
}:
{
  options.mares.networking.technitium = {
    enable = lib.mkEnableOption "Technitium DNS Server";

    proxyHost = lib.mkOption {
      type = lib.types.str;
      example = "10.10.22.103";
      description = "IP address of the proxy server for wildcard DNS";
    };

    forwarders = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Upstream DNS forwarders (DoH URLs)";
    };

    blockLists = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Block list URLs";
    };

    allowedDomains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Domains to add to the Allowed zone (bypass blocking)";
    };

    conditionalForwarders = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            zone = lib.mkOption {
              type = lib.types.str;
              description = "Zone name (e.g., 20.168.192.in-addr.arpa)";
            };
            forwarder = lib.mkOption {
              type = lib.types.str;
              description = "Forwarder IP address";
            };
          };
        }
      );
      default = [ ];
      description = "Conditional forwarders for reverse DNS zones";
    };

    tsigKeyName = lib.mkOption {
      type = lib.types.str;
      example = "technitium-cluster";
      description = "Name for the TSIG key used for zone transfers and cluster communication";
    };

    zone = lib.mkOption {
      type = lib.types.str;
      example = "mares.id";
      description = "Primary DNS zone managed by this server";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      example = "dns.mares.id";
      description = "DNS server's own hostname (for TLS cert)";
    };

    blockPageAddress = lib.mkOption {
      type = lib.types.str;
      example = "10.10.22.199";
      description = "IP address for block page responses";
    };

    acmeDirectory = lib.mkOption {
      type = lib.types.str;
      example = "/var/lib/acme/dns.mares.id";
      description = "Directory containing ACME certificates";
    };

    serverAddresses = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      example = [ "10.10.22.199" ];
      description = "IP addresses of DNS servers (for dns.\${zone} A records)";
    };

    dnsRecords = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            fqdn = lib.mkOption {
              type = lib.types.str;
              description = "Fully qualified domain name";
            };
            ip = lib.mkOption {
              type = lib.types.str;
              description = "IP address";
            };
          };
        }
      );
      default = [ ];
      description = "A records to create in the zone (always overwrites)";
    };

  };
}
