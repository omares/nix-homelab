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
        ${lib.concatMapStringsSep ",\n      " (t: ''{"__address__" = "${t}"}'') target.targets},
      ]
      forward_to = [prometheus.remote_write.default.receiver]

      scrape_interval = "15s"
    }
  '') cfg.extraScrapeTargets;

  alloyConfig = ''
    prometheus.exporter.unix "default" {
      include_exporter_metrics = true
      disable_collectors = ["mdadm"]
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
  };

  config = lib.mkIf cfg.enable {
    services.alloy = {
      enable = true;
      extraFlags = [
        "--server.http.listen-addr=${cfg.listenAddress}:${toString cfg.metricsPort}"
        "--disable-reporting"
      ];
    };

    environment.etc."alloy/config.alloy".text = alloyConfig;

    networking.firewall.allowedTCPPorts = [ cfg.metricsPort ];
  };
}
