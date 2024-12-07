{
  name,
  config,
  lib,
  ...
}:
{
  services.adguardhome = {
    enable = true;
    mutableSettings = false;
    openFirewall = true;

    host = config.deployment.targetHost;
    settings = {

      http = {
        pprof = {
          port = 6060;
          enabled = false;
        };
        address = "127.0.0.1:80";
        session_ttl = "720h";
      };
      users = [
        {
          name = "omares";
          password = "$2a$10$olJ5/MFB.HeJlhSP9GN8SO.wjpkW4.Sl7wiBpOhLPHO0Kt7YtmFTS";
        }
      ];
      auth_attempts = 5;
      block_auth_min = 15;
      http_proxy = "";
      language = "";
      theme = "auto";
      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port = 53;
        anonymize_client_ip = false;
        ratelimit = 20;
        ratelimit_subnet_len_ipv4 = 24;
        ratelimit_subnet_len_ipv6 = 56;
        ratelimit_whitelist = [ ];
        refuse_any = true;
        upstream_dns = [
          "https://zero.dns0.eu/"
          "https://dns.adguard-dns.com/dns-query"
          "https://dns.cloudflare.com/dns-query"
          "https://dns.quad9.net/dns-query"
        ];
        upstream_dns_file = "";
        bootstrap_dns = [
          "1.1.1.1"
          "1.0.0.1"
          "193.110.81.0"
          "185.253.5.0"
        ];
        fallback_dns = [ ];
        upstream_mode = "load_balance";
        fastest_timeout = "1s";
        allowed_clients = [ ];
        disallowed_clients = [ ];
        blocked_hosts = [
          "version.bind"
          "id.server"
          "hostname.bind"
        ];
        trusted_proxies = [
          "192.168.20.105/32"
          "127.0.0.0/8"
          "::1/128"
        ];
        cache_size = 4194304;
        cache_ttl_min = 0;
        cache_ttl_max = 0;
        cache_optimistic = false;
        bogus_nxdomain = [ ];
        aaaa_disabled = false;
        enable_dnssec = false;
        edns_client_subnet = {
          custom_ip = "";
          enabled = false;
          use_custom = false;
        };
        max_goroutines = 300;
        handle_ddr = true;
        ipset = [ ];
        ipset_file = "";
        bootstrap_prefer_ipv6 = false;
        upstream_timeout = "10s";
        private_networks = [ ];
        use_private_ptr_resolvers = true;
        local_ptr_upstreams = [
          "1.1.1.1:53"
          "1.0.0.1:53"
          "[/20.168.192.in-addr.arpa/]192.168.20.1"
          "[/30.168.192.in-addr.arpa/]192.168.30.1"
          "[/40.168.192.in-addr.arpa/]192.168.40.1"
          "[/50.168.192.in-addr.arpa/]192.168.50.1"
        ];
        use_dns64 = false;
        dns64_prefixes = [ ];
        serve_http3 = false;
        use_http3_upstreams = false;
        serve_plain_dns = true;
        hostsfile_enabled = true;
      };
      tls = {
        enabled = true;
        server_name = "${name}.mares.id";
        force_https = false;
        port_https = 443;
        port_dns_over_tls = 853;
        port_dns_over_quic = 853;
        port_dnscrypt = 0;
        dnscrypt_config_file = "";
        allow_unencrypted_doh = true;
        certificate_chain = "";
        private_key = "";
        certificate_path = "";
        private_key_path = "";
        strict_sni_check = false;
      };
      querylog = {
        dir_path = "";
        ignored = [ ];
        interval = "2160h";
        size_memory = 1000;
        enabled = true;
        file_enabled = true;
      };
      statistics = {
        dir_path = "";
        ignored = [ ];
        interval = "24h";
        enabled = true;
      };
      filters = [
        {
          enabled = false;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
          name = "AdGuard DNS filter";
          id = 1;
        }
        {
          enabled = false;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt";
          name = "AdAway Default Blocklist";
          id = 2;
        }
        {
          enabled = false;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_48.txt";
          name = "HaGeZi's Pro Blocklist";
          id = 1712088971;
        }
        {
          enabled = false;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_44.txt";
          name = "HaGeZi's Threat Intelligence Feeds";
          id = 1712088972;
        }
        {
          enabled = false;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_52.txt";
          name = "HaGeZi's Encrypted DNS/VPN/TOR/Proxy Bypass";
          id = 1712088973;
        }
      ];
      whitelist_filters = [ ];
      user_rules = [
        "@@||controlplane.tailscale.com^$important"
        "@@||pkgs.tailscale.com^$important"
      ];
      dhcp = {
        enabled = false;
        interface_name = "";
        local_domain_name = "lan";
        dhcpv4 = {
          gateway_ip = "";
          subnet_mask = "";
          range_start = "";
          range_end = "";
          lease_duration = 86400;
          icmp_timeout_msec = 1000;
          options = [ ];
        };
        dhcpv6 = {
          range_start = "";
          lease_duration = 86400;
          ra_slaac_only = false;
          ra_allow_slaac = false;
        };
      };
      filtering = {
        blocking_ipv4 = "";
        blocking_ipv6 = "";
        blocked_services = {
          schedule = {
            time_zone = "Local";
          };
          ids = [ ];
        };
        protection_disabled_until = null;
        safe_search = {
          enabled = false;
          bing = true;
          duckduckgo = true;
          google = true;
          pixabay = true;
          yandex = true;
          youtube = true;
        };
        blocking_mode = "default";
        parental_block_host = "family-block.dns.adguard.com";
        safebrowsing_block_host = "standard-block.dns.adguard.com";
        rewrites = [
          {
            domain = "*.mares.id";
            answer = "192.168.20.105";
          }
          {
            domain = "agh02.mares.id";
            answer = "192.168.20.87";
          }
        ];
        safebrowsing_cache_size = 1048576;
        safesearch_cache_size = 1048576;
        parental_cache_size = 1048576;
        cache_time = 30;
        filters_update_interval = 24;
        blocked_response_ttl = 10;
        filtering_enabled = true;
        parental_enabled = false;
        safebrowsing_enabled = true;
        protection_enabled = true;
      };
      clients = {
        runtime_sources = {
          whois = true;
          arp = true;
          rdns = true;
          dhcp = true;
          hosts = true;
        };
        persistent = [ ];
      };
      log = {
        file = "";
        max_backups = 0;
        max_size = 100;
        max_age = 3;
        compress = false;
        local_time = false;
        verbose = false;
      };
      os = {
        group = "";
        user = "";
        rlimit_nofile = 0;
      };
      schema_version = 28;
    };

  };
}
