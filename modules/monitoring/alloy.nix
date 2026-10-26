{
  lib,
  config,
  ...
}:
let
  cfg = config.mares.monitoring.alloy;
  serverCfg = config.mares.monitoring.server;
  hostname = config.networking.hostName;

  # Generate scrape config blocks for extra targets
  extraScrapeConfigs = lib.concatMapStringsSep "\n" (target: ''
    prometheus.scrape "${target.job}" {
      targets = [
        ${
          lib.concatMapStringsSep ",\n      " (
            t: ''{"__address__" = "${t}", "instance" = "${hostname}"}''
          ) target.targets
        },
      ]
      forward_to = [${
        if target.metricPrefix != null then
          "prometheus.relabel.${target.job}.receiver"
        else
          "prometheus.remote_write.default.receiver"
      }]
      job_name   = "${target.job}"
      metrics_path = "${target.metricsPath}"
      ${lib.optionalString (
        target.bearerTokenFile != null
      ) ''bearer_token_file = "/run/credentials/alloy.service/${target.job}-token"''}

      scrape_interval = "15s"
    }
    ${lib.optionalString (target.metricPrefix != null) ''
      prometheus.relabel "${target.job}" {
        forward_to = [prometheus.remote_write.default.receiver]

        // Keep the scrape's own up/scrape_* series unprefixed (RE2 has no negative lookahead)
        rule {
          source_labels = ["__name__"]
          regex         = "up|scrape_.+"
          target_label  = "__tmp_scrape"
          replacement   = "1"
        }

        rule {
          source_labels = ["__tmp_scrape", "__name__"]
          separator     = ";"
          regex         = ";(.+)"
          target_label  = "__name__"
          replacement   = "${target.metricPrefix}$1"
        }

        rule {
          action = "labeldrop"
          regex  = "__tmp_scrape"
        }
      }
    ''}
  '') cfg.extraScrapeTargets;

  tokenTargets = builtins.filter (t: t.bearerTokenFile != null) cfg.extraScrapeTargets;

  # Generate PVE multi-target scrape configs
  # Each PVE node gets a scrape + relabel component pair
  pveScrapeConfigs = lib.optionalString (cfg.pveTargets != [ ]) (
    lib.concatMapStringsSep "\n" (
      target:
      let
        safeName = builtins.replaceStrings [ "." ] [ "_" ] target;
        # Cluster data is identical on every node, collect it once to avoid duplicate series
        cluster = if target == builtins.head cfg.pveTargets then "1" else "0";
      in
      ''
        prometheus.scrape "pve_${safeName}" {
          targets = [{"__address__" = "localhost:9221"}]
          forward_to = [prometheus.relabel.pve_${safeName}.receiver]

          scrape_interval = "60s"
          scrape_timeout = "30s"
          metrics_path = "/pve"

          params = {
            "target" = ["${target}"],
            "cluster" = ["${cluster}"],
            "node" = ["1"],
          }
        }

        prometheus.relabel "pve_${safeName}" {
          forward_to = [prometheus.remote_write.default.receiver]

          rule {
            target_label = "instance"
            replacement = "${target}"
          }

          rule {
            target_label = "job"
            replacement = "pve"
          }
        }
      ''
    ) cfg.pveTargets
  );

  alloyConfig = ''
    prometheus.exporter.unix "default" {
      include_exporter_metrics = true
      // nfs is kept: it only succeeds on hosts with NFS mounts
      disable_collectors = ["mdadm", "bonding", "fibrechannel", "infiniband", "ipvs", "nfsd", "nvme", "tapestats", "zfs"]
      enable_collectors  = ["systemd", "tcpstat"]

      // Alloy defaults plus tmpfs/ramfs and the /nix/store bind mount
      filesystem {
        fs_types_exclude     = "^(autofs|binfmt_misc|bpf|cgroup2?|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|iso9660|mqueue|nsfs|overlay|proc|procfs|pstore|ramfs|rpc_pipefs|securityfs|selinuxfs|squashfs|sysfs|tmpfs|tracefs)$"
        mount_points_exclude = "^/(dev|proc|run/credentials/.+|sys|var/lib/docker/.+|nix/store)($|/)"
      }

      // Alloy default plus CD-ROM drives
      disk {
        device_exclude = "^(ram|loop|fd|sr|(h|s|v|xv)d[a-z]|nvme\\d+n\\d+p)\\d+$"
      }
    }

    discovery.relabel "local" {
      targets = prometheus.exporter.unix.default.targets

      rule {
        target_label = "instance"
        replacement  = "${hostname}"
      }

      rule {
        target_label = "job"
        replacement  = "node"
      }
    }

    prometheus.scrape "node" {
      targets    = discovery.relabel.local.output
      forward_to = [prometheus.remote_write.default.receiver]

      scrape_interval = "15s"
    }

    prometheus.remote_write "default" {
      endpoint {
        url = "${cfg.prometheusUrl}"
      }
    }

    loki.source.journal "default" {
      forward_to = [loki.write.default.receiver]
      labels = {
        host = "${hostname}",
        job  = "journal",
      }
      relabel_rules = loki.relabel.journal.rules
    }

    loki.relabel "journal" {
      forward_to = []

      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }

      // Extract job from systemd unit, stripping .service suffix
      rule {
        source_labels = ["__journal__systemd_unit"]
        regex         = "(.+)\\.service"
        target_label  = "job"
      }

      // Handle non-.service units (e.g., .timer, .socket, .mount) - strip suffix
      rule {
        source_labels = ["__journal__systemd_unit"]
        regex         = "(.+)\\.[^.]+"
        target_label  = "job"
      }

      // Fallback: use syslog_identifier if job is still empty
      rule {
        source_labels = ["__journal_syslog_identifier", "job"]
        regex         = "(.+);^$"
        target_label  = "job"
      }

      rule {
        source_labels = ["__journal_priority"]
        target_label  = "priority"
      }

      rule {
        source_labels = ["__journal_syslog_identifier"]
        target_label  = "syslog_identifier"
      }
    }

    loki.write "default" {
      endpoint {
        url = "${cfg.lokiUrl}"
      }
    }

    prometheus.exporter.self "alloy" { }

    prometheus.scrape "alloy" {
      targets    = prometheus.exporter.self.alloy.targets
      forward_to = [prometheus.remote_write.default.receiver]

      scrape_interval = "15s"
    }

    ${extraScrapeConfigs}

    ${pveScrapeConfigs}
  '';

  scrapeTargetSubmodule = lib.types.submodule {
    options = {
      job = lib.mkOption {
        type = lib.types.str;
        description = "Job name for the scrape target";
        example = "nginx";
      };
      targets = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "List of targets to scrape (host:port)";
        example = [ "localhost:9113" ];
      };
      metricsPath = lib.mkOption {
        type = lib.types.str;
        default = "/metrics";
        description = "HTTP path to scrape";
      };
      metricPrefix = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Prefix added to every metric name, for exporters with generic names";
        example = "technitium_";
      };
      bearerTokenFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "File with a bearer token for the scrape (loaded via systemd LoadCredential)";
      };
    };
  };
in
{
  options.mares.monitoring.alloy = {
    enable = lib.mkEnableOption "Enable Grafana Alloy agent";

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address to listen on for metrics/health endpoint";
    };

    metricsPort = lib.mkOption {
      type = lib.types.port;
      default = 12345;
      description = "Port for Alloy metrics endpoint";
    };

    prometheusUrl = lib.mkOption {
      type = lib.types.str;
      default = serverCfg.prometheus.url;
      description = "Prometheus remote write URL";
    };

    lokiUrl = lib.mkOption {
      type = lib.types.str;
      default = serverCfg.loki.url;
      description = "Loki push URL";
    };

    extraScrapeTargets = lib.mkOption {
      type = lib.types.listOf scrapeTargetSubmodule;
      default = [ ];
      description = "Extra scrape targets for Alloy to collect from local exporters";
      example = [
        {
          job = "nginx";
          targets = [ "localhost:9113" ];
        }
      ];
    };

    pveTargets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of PVE node IPs to scrape via multi-target exporter on localhost:9221";
      example = [
        "192.168.20.21"
        "192.168.20.93"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    services.alloy = {
      enable = true;
      extraFlags = [
        "--server.http.listen-addr=${cfg.listenAddress}:${toString cfg.metricsPort}"
        "--disable-reporting"
      ];
    };

    systemd.services.alloy.serviceConfig.LoadCredential = map (
      t: "${t.job}-token:${t.bearerTokenFile}"
    ) tokenTargets;

    environment.etc."alloy/config.alloy".text = alloyConfig;

    networking.firewall.allowedTCPPorts = [ cfg.metricsPort ];
  };
}
