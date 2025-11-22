{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.mares.monitoring.grafana;
  serverCfg = config.mares.monitoring.server;

  dashLib = import ../../lib/grafana-dashboards.nix { inherit pkgs lib; };

  dashboardConfigs = {
    node-exporter-full = {
      id = 1860;
      version = 37;
      sha256 = "0qza4j8lywrj08bqbww52dgh2p2b9rkhq5p313g72i57lrlkacfl";
      transform = dashLib.setUid "node-exporter-full";
    };

    loki-logs = {
      id = 13639;
      version = 2;
      sha256 = "101lai075g45sspbnik2drdqinzmgv1yfq6888s520q8ia959m6r";
      transform =
        dashboard:
        lib.pipe dashboard [
          (dashLib.setUid "loki-logs")
          (dashLib.replaceDatasources [
            {
              key = "DS_LOKI";
              value = "loki-main";
            }
          ])
          # Replace variables: add host, rename app to service
          (
            d:
            d
            // {
              templating = d.templating // {
                list = [
                  # Host variable (new)
                  {
                    name = "host";
                    label = "Host";
                    type = "query";
                    datasource = {
                      type = "loki";
                      uid = "loki-main";
                    };
                    query = "label_values(host)";
                    refresh = 1;
                    includeAll = true;
                    allValue = ".+";
                    multi = true;
                    sort = 1;
                  }
                  # Service variable (renamed from app)
                  {
                    name = "service";
                    label = "Service";
                    type = "query";
                    datasource = {
                      type = "loki";
                      uid = "loki-main";
                    };
                    query = "label_values(job)";
                    refresh = 1;
                    includeAll = true;
                    allValue = ".+";
                    multi = true;
                    sort = 1;
                  }
                  # Level variable (maps to syslog priority)
                  {
                    name = "level";
                    label = "Level";
                    type = "custom";
                    # Grafana custom variables use query string with "text : value" pairs
                    query = "All : .+,Critical : [0-2],Error : 3,Warning : 4,Notice : 5,Info : 6,Debug : 7";
                    options = [
                      {
                        text = "All";
                        value = ".+";
                        selected = true;
                      }
                      {
                        text = "Critical";
                        value = "[0-2]";
                        selected = false;
                      }
                      {
                        text = "Error";
                        value = "3";
                        selected = false;
                      }
                      {
                        text = "Warning";
                        value = "4";
                        selected = false;
                      }
                      {
                        text = "Notice";
                        value = "5";
                        selected = false;
                      }
                      {
                        text = "Info";
                        value = "6";
                        selected = false;
                      }
                      {
                        text = "Debug";
                        value = "7";
                        selected = false;
                      }
                    ];
                    current = {
                      text = "All";
                      value = ".+";
                      selected = true;
                    };
                    includeAll = true;
                    allValue = ".+";
                    multi = true;
                  }
                ]
                # Keep other variables that aren't 'app'
                ++ (builtins.filter (var: var.name != "app") d.templating.list);
              };
            }
          )
          # Update queries to use new variables: {host=~"$host", job=~"$service", priority=~"$level"}
          (
            d:
            d
            // {
              panels = map (
                panel:
                if panel ? targets then
                  panel
                  // {
                    targets = map (
                      target:
                      if target ? expr then
                        target
                        // {
                          expr =
                            builtins.replaceStrings
                              [ ''job="$app"'' ''{job=~"$app"}'' ]
                              [
                                ''host=~"$host", job=~"$service", priority=~"$level"''
                                ''{host=~"$host", job=~"$service", priority=~"$level"}''
                              ]
                              target.expr;
                        }
                      else
                        target
                    ) panel.targets;
                  }
                else
                  panel
              ) d.panels;
            }
          )
        ];
    };

    postgresql = {
      id = 9628;
      version = 7;
      sha256 = "0xmk68kqb9b8aspjj2f8wxv2mxiqk9k3xs0yal4szmzbv65c6k66";
      transform =
        dashboard:
        lib.pipe dashboard [
          (dashLib.setUid "postgresql")
          (dashLib.replaceDatasources [
            {
              key = "DS_PROMETHEUS";
              value = "prometheus-main";
            }
          ])
        ];
    };

    nginx = {
      id = 12708;
      version = 1;
      sha256 = "0bgpwiw733y6vw4985srdj6a4w4pbjw0fdp6ggb2zyidpicyllag";
      transform =
        dashboard:
        lib.pipe dashboard [
          (dashLib.setUid "nginx")
          (dashLib.replaceDatasources [
            {
              key = "DS_PROMETHEUS";
              value = "prometheus-main";
            }
          ])
        ];
    };

    pgbouncer = {
      id = 14022;
      version = 1;
      sha256 = "1121iijgb7l3qb6dcrwc1hai9rivm3rmi84ajczllw5lp4m68lcy";
      transform =
        dashboard:
        lib.pipe dashboard [
          (dashLib.setUid "pgbouncer")
          (dashLib.replaceDatasources [
            {
              key = "DS_PROMETHEUS";
              value = "prometheus-main";
            }
          ])
        ];
    };

    ssl-certificates = {
      # Dashboard for node-cert-exporter (SSL certificate expiry monitoring)
      # Dashboard 9999 is designed for Kubernetes, so we transform queries to work without K8s labels
      id = 9999;
      version = 1;
      sha256 = "0qfsj8zyc0nj8c4g2sx2xzw6rmvl1brlqg22n84qavyy72kjkjnv";
      transform =
        dashboard:
        lib.pipe dashboard [
          (dashLib.setUid "ssl-certificates")
          (dashLib.replaceDatasources [
            {
              key = "DS_PROMETHEUS";
              value = "prometheus-main";
            }
          ])
          # Transform queries to work without Kubernetes labels
          # Original: sum(ssl_certificate_expiry_seconds{}) by (kubernetes_pod_node_name, path)
          # New: ssl_certificate_expiry_seconds{} grouped by instance and path
          (
            d:
            d
            // {
              panels = map (
                panel:
                if panel ? targets then
                  panel
                  // {
                    targets = map (
                      target:
                      if target ? expr then
                        target
                        // {
                          expr =
                            builtins.replaceStrings
                              [
                                "sum(ssl_certificate_expiry_seconds{}) by (kubernetes_pod_node_name, path)"
                                "kubernetes_pod_node_name"
                              ]
                              [
                                "ssl_certificate_expiry_seconds{}"
                                "instance"
                              ]
                              target.expr;
                        }
                      else
                        target
                    ) panel.targets;
                  }
                else
                  panel
              ) d.panels;
            }
          )
        ];
    };

    exportarr = {
      # Unified "Media Dashboard" from exportarr GitHub repo
      # Covers: Prowlarr, Sabnzbd, Radarr, Sonarr, Lidarr, Readarr
      url = "https://raw.githubusercontent.com/onedr0p/exportarr/master/examples/grafana/dashboard2.json";
      sha256 = "0ic7lmkg94dfa8lm14n8sv54cq0r7bhdclcaynayaikw86kv1pdc";
      transform =
        dashboard:
        lib.pipe dashboard [
          (dashLib.setUid "exportarr")
          (dashLib.replaceDatasources [
            {
              key = "DS_PROMETHEUS";
              value = "prometheus-main";
            }
          ])
        ];
    };

    prometheus-stats = {
      id = 2;
      version = 2;
      sha256 = "0z3i2vli6blb3nxah27w72ml1ns1svr5hqnb6y4qlpqzzhn3inb1";
      transform =
        dashboard:
        lib.pipe dashboard [
          (dashLib.setUid "prometheus-stats")
          (dashLib.replaceDatasources [
            {
              key = "DS_PROMETHEUS";
              value = "prometheus-main";
            }
          ])
        ];
    };

  };

  mkDashboardProvider =
    name: dashCfg:
    let
      dashboardPath =
        if dashCfg ? id then
          dashLib.fetchDashboard {
            inherit name;
            inherit (dashCfg) id version sha256;
          }
        else
          dashLib.fetchDashboardFromUrl {
            inherit name;
            inherit (dashCfg) url sha256;
          };
    in
    dashLib.dashboardEntry {
      inherit name;
      path = dashboardPath;
      inherit (dashCfg) transform;
    };

  dashboardProviders = lib.mapAttrsToList mkDashboardProvider dashboardConfigs;
in
{
  options.mares.monitoring.grafana = {
    enable = lib.mkEnableOption "Enable Grafana";

    domain = lib.mkOption {
      type = lib.types.str;
      default = "grafana.mares.id";
      description = "Domain for Grafana";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Port for Grafana";
    };

    adminPasswordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to file containing admin password (for sops-nix integration)";
    };
  };

  config = lib.mkIf cfg.enable {
    services.grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "0.0.0.0";
          http_port = cfg.port;
          domain = cfg.domain;
          root_url = "https://${cfg.domain}";
        };

        security = {
          admin_user = "admin";
          admin_password = lib.mkIf (
            cfg.adminPasswordFile == null
          ) "$__file{/var/lib/grafana/admin-password}";
          admin_password_file = lib.mkIf (cfg.adminPasswordFile != null) cfg.adminPasswordFile;
        };

        analytics.reporting_enabled = false;
        analytics.check_for_updates = false;
      };

      provision = {
        enable = true;

        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            uid = "prometheus-main";
            access = "proxy";
            url = "http://localhost:${toString serverCfg.prometheus.port}";
            isDefault = true;
          }
          {
            name = "Loki";
            type = "loki";
            uid = "loki-main";
            access = "proxy";
            url = "http://localhost:${toString serverCfg.loki.port}";
          }
        ];

        dashboards.settings.providers = dashboardProviders;
      };
    };

    systemd.tmpfiles.rules = lib.optional (
      cfg.adminPasswordFile == null
    ) "f /var/lib/grafana/admin-password 0600 grafana grafana - admin";

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
