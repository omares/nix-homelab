{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.mares.monitoring.grafana;
  serverCfg = config.mares.monitoring.server;
  influxdbCfg = config.mares.monitoring.influxdb;

  dashLib = import ../../lib/grafana-dashboards.nix { inherit pkgs lib; };

  unpollerDashboard = uid: id: version: sha256: {
    inherit id version sha256;
    transform =
      dashboard:
      lib.pipe dashboard [
        (dashLib.setUid uid)
        (dashLib.replaceDatasources [
          {
            key = "DS_PROMETHEUS";
            value = "prometheus-main";
          }
        ])
      ];
  };

  dashboardConfigs = {
    node-exporter-full = {
      id = 1860;
      version = 37;
      sha256 = "0qza4j8lywrj08bqbww52dgh2p2b9rkhq5p313g72i57lrlkacfl";
      transform =
        dashboard:
        let
          # Panels without data on Proxmox VMs or with upstream bugs:
          # Hardware Misc row, guest CPU, cpufreq, interrupts detail, process_* panels,
          # NIC speed (virtio reports -1), IP forwarding (irate on a gauge)
          dropIds = [
            304
            319
            321
            259
            308
            64
            149
            280
            81
          ];
          # node_network_up has no operstate label
          fixExpr =
            builtins.replaceStrings
              [ ''node_network_up{operstate="up",'' ]
              [ ''node_network_info{operstate="up",'' ];
          fixPanel =
            panel:
            panel
            // lib.optionalAttrs (panel ? targets) {
              targets = map (t: t // lib.optionalAttrs (t ? expr) { expr = fixExpr t.expr; }) panel.targets;
            }
            // lib.optionalAttrs (panel ? panels) { panels = cleanPanels panel.panels; };
          cleanPanels = panels: map fixPanel (builtins.filter (p: !(builtins.elem p.id dropIds)) panels);
        in
        lib.pipe dashboard [
          (dashLib.setUid "node-exporter-full")
          (d: d // { panels = cleanPanels d.panels; })
        ];
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
                    current = {
                      text = "All";
                      value = "$__all";
                    };
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
                    query = ''label_values({host=~"$host"}, job)'';
                    refresh = 1;
                    includeAll = true;
                    allValue = ".+";
                    multi = true;
                    sort = 1;
                    current = {
                      text = "All";
                      value = "$__all";
                    };
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
                    # Single-select so Grafana passes the regex values unescaped
                    includeAll = false;
                    multi = false;
                  }
                ]
                # Keep other variables that aren't 'app'
                ++ (builtins.filter (var: var.name != "app") d.templating.list);
              };
            }
          )
          (
            d:
            let
              datasource = {
                type = "loki";
                uid = "loki-main";
              };
              selector = ''{host=~"$host", job=~"$service", priority=~"$level"} |~ "(?i)$search"'';
              levels = [
                {
                  priority = "0";
                  name = "emergency";
                  color = "dark-red";
                }
                {
                  priority = "1";
                  name = "alert";
                  color = "dark-red";
                }
                {
                  priority = "2";
                  name = "critical";
                  color = "dark-red";
                }
                {
                  priority = "3";
                  name = "error";
                  color = "red";
                }
                {
                  priority = "4";
                  name = "warning";
                  color = "orange";
                }
                {
                  priority = "5";
                  name = "notice";
                  color = "yellow";
                }
                {
                  priority = "6";
                  name = "info";
                  color = "green";
                }
                {
                  priority = "7";
                  name = "debug";
                  color = "blue";
                }
              ];
            in
            d
            // {
              panels = [
                {
                  id = 6;
                  title = "Log volume by level";
                  type = "timeseries";
                  inherit datasource;
                  gridPos = {
                    h = 7;
                    w = 16;
                    x = 0;
                    y = 0;
                  };
                  targets = [
                    {
                      refId = "A";
                      inherit datasource;
                      expr = "sum by (priority) (count_over_time(${selector} [$__auto]))";
                      legendFormat = "{{priority}}";
                    }
                  ];
                  fieldConfig = {
                    defaults.custom = {
                      drawStyle = "bars";
                      fillOpacity = 80;
                      lineWidth = 0;
                      stacking.mode = "normal";
                    };
                    overrides = map (l: {
                      matcher = {
                        id = "byName";
                        options = l.priority;
                      };
                      properties = [
                        {
                          id = "displayName";
                          value = l.name;
                        }
                        {
                          id = "color";
                          value = {
                            mode = "fixed";
                            fixedColor = l.color;
                          };
                        }
                      ];
                    }) levels;
                  };
                  options = {
                    legend = {
                      displayMode = "list";
                      placement = "right";
                    };
                    tooltip.mode = "multi";
                  };
                }
                {
                  id = 7;
                  title = "Errors by host / service";
                  type = "bargauge";
                  inherit datasource;
                  gridPos = {
                    h = 7;
                    w = 8;
                    x = 16;
                    y = 0;
                  };
                  targets = [
                    {
                      refId = "A";
                      inherit datasource;
                      queryType = "instant";
                      expr = ''topk(10, sum by (host, job) (count_over_time({host=~"$host", job=~"$service", priority=~"[0-3]"} |~ "(?i)$search" [$__range])))'';
                      legendFormat = "{{host}} / {{job}}";
                    }
                  ];
                  fieldConfig.defaults = {
                    color.mode = "fixed";
                    color.fixedColor = "red";
                  };
                  options = {
                    orientation = "horizontal";
                    displayMode = "basic";
                    reduceOptions.calcs = [ "lastNotNull" ];
                  };
                }
                {
                  id = 2;
                  title = "Logs";
                  type = "logs";
                  inherit datasource;
                  gridPos = {
                    h = 24;
                    w = 24;
                    x = 0;
                    y = 7;
                  };
                  targets = [
                    {
                      refId = "A";
                      inherit datasource;
                      expr = "${selector} | logfmt | drop __error__, __error_details__";
                    }
                  ];
                  options = {
                    showTime = true;
                    showLabels = false;
                    wrapLogMessage = true;
                    enableLogDetails = true;
                    sortOrder = "Descending";
                  };
                }
              ];
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
        let
          # pgbouncer_exporter renamed the stats counters (stats_totals_*) and reserve_pool_size;
          # also fix rate() on gauges, `=` on the multi-value $db and the bytes*8
          fixExpr =
            builtins.replaceStrings
              [
                "pgbouncer_stats_queries_pooled_total"
                "pgbouncer_stats_queries_duration_seconds_total"
                "pgbouncer_stats_server_in_transaction_seconds"
                "pgbouncer_stats_sql_transactions_pooled_total"
                "pgbouncer_stats_received_bytes_total"
                "pgbouncer_stats_sent_bytes_total"
                ''sum (rate(pgbouncer_databases_reserve_pool_size{database=~"$db"}[30m]))''
                ''sum ( rate(pgbouncer_pools_client_maxwait_seconds{database=~"$db"}[30m]) )''
                ''database="$db"''
                "[30m])*8"
              ]
              [
                "pgbouncer_stats_totals_queries_pooled_total"
                "pgbouncer_stats_totals_queries_duration_seconds_total"
                "pgbouncer_stats_totals_server_in_transaction_seconds_total"
                "pgbouncer_stats_totals_sql_transactions_pooled_total"
                "pgbouncer_stats_totals_received_bytes_total"
                "pgbouncer_stats_totals_sent_bytes_total"
                ''sum (pgbouncer_databases_reserve_pool{database=~"$db"})''
                ''max ( pgbouncer_pools_client_maxwait_seconds{database=~"$db"} )''
                ''database=~"$db"''
                "[30m])"
              ];
          fixLegend =
            builtins.replaceStrings
              [
                "Waiting duration microseconds"
                "Transactions duration microseconds"
                "Duration microseconds"
              ]
              [
                "Max client wait"
                "Time in transactions"
                "Query time"
              ];
          leftUnit = {
            "12" = "s";
            "14" = "Bps";
            "16" = "s";
          };
          fixPanel =
            panel:
            panel
            // {
              targets = map (
                t:
                t
                // {
                  expr = fixExpr t.expr;
                  legendFormat = fixLegend (t.legendFormat or "");
                }
              ) panel.targets;
            }
            // lib.optionalAttrs (leftUnit ? ${toString panel.id}) {
              yaxes = lib.imap0 (
                i: axis: if i == 0 then axis // { format = leftUnit.${toString panel.id}; } else axis
              ) panel.yaxes;
            };
          # host/port/service expect labels this setup doesn't have and are unused
          unusedVars = [
            "host"
            "port"
            "service"
          ];
        in
        lib.pipe dashboard [
          (dashLib.setUid "pgbouncer")
          (dashLib.replaceDatasources [
            {
              key = "DS_PROMETHEUS";
              value = "prometheus-main";
            }
          ])
          (
            d:
            d
            // {
              panels = map fixPanel d.panels;
              templating.list = builtins.filter (v: !(builtins.elem v.name unusedVars)) d.templating.list;
            }
          )
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
          # Replace the Kubernetes table-old panel; only leaf certs of live ACME dirs
          # (skips .minica, .lego, chain/issuer files and *.bck copies)
          (
            d:
            d
            // {
              tags = [ "node-cert-exporter" ];
              panels = [
                {
                  id = 2;
                  type = "table";
                  title = "Certificates";
                  datasource = {
                    type = "prometheus";
                    uid = "prometheus-main";
                  };
                  gridPos = {
                    h = 16;
                    w = 24;
                    x = 0;
                    y = 0;
                  };
                  targets = [
                    {
                      refId = "A";
                      expr = ''min by (instance, dns_names, path) (ssl_certificate_expiry_seconds{path=~"/var/lib/acme/[^/.][^/]*\\.mares\\.id/cert\\.pem"})'';
                      format = "table";
                      instant = true;
                    }
                  ];
                  transformations = [
                    {
                      id = "organize";
                      options = {
                        excludeByName.Time = true;
                        indexByName = {
                          dns_names = 0;
                          Value = 1;
                          instance = 2;
                          path = 3;
                        };
                        renameByName = {
                          dns_names = "Names";
                          Value = "Expires in";
                          instance = "Host";
                          path = "Path";
                        };
                      };
                    }
                  ];
                  fieldConfig = {
                    defaults.custom.align = "auto";
                    overrides = [
                      {
                        matcher = {
                          id = "byName";
                          options = "Expires in";
                        };
                        properties = [
                          {
                            id = "unit";
                            value = "dtdurations";
                          }
                          {
                            id = "custom.cellOptions";
                            value.type = "color-background";
                          }
                          {
                            id = "thresholds";
                            value = {
                              mode = "absolute";
                              steps = [
                                {
                                  color = "red";
                                  value = null;
                                }
                                {
                                  color = "orange";
                                  value = 1209600;
                                }
                                {
                                  color = "green";
                                  value = 2592000;
                                }
                              ];
                            };
                          }
                        ];
                      }
                    ];
                  };
                  options.sortBy = [
                    {
                      displayName = "Expires in";
                      desc = false;
                    }
                  ];
                }
              ];
            }
          )
        ];
    };

    exportarr.dashboard = import ./dashboards/media.nix { inherit lib; };

    monitoring.dashboard = import ./dashboards/monitoring.nix { inherit lib; };

    proxmox.dashboard = import ./dashboards/proxmox.nix { inherit lib; };

    uptime.dashboard = import ./dashboards/uptime.nix { inherit lib; };

    technitium.dashboard = import ./dashboards/technitium.nix { inherit lib; };

    unifi-sites =
      unpollerDashboard "unifi-sites" 11311 5
        "0pwz5fdp4ybfgjnydip6p6wy2siikcg0ikz9li65pmwwmawx49mb";
    unifi-usw =
      unpollerDashboard "unifi-usw" 11312 9
        "1v82bzp5m6zvmvjcchd3704rsd0pg3190lvjpsy0zq883dzz94m1";
    unifi-usg =
      unpollerDashboard "unifi-usg" 11313 9
        "0ldngl8rpqkcx6y5qna4w4pl9b91ksfrnxk4lmllj2wlihkvfzzb";
    unifi-uap =
      unpollerDashboard "unifi-uap" 11314 10
        "1g1chjl1zm24l3an3jam0svrbq29k8166699c2467zy2kbgsq0nv";
    unifi-clients =
      unpollerDashboard "unifi-clients" 11315 9
        "1rf60hb5daxha3fiz2j53yrw7hk6rmwg798siiykn8zkjqkmjgz9";

  };

  mkDashboardProvider =
    name: dashCfg:
    let
      dashboardPath =
        if dashCfg ? dashboard then
          builtins.toFile "${name}.json" (builtins.toJSON dashCfg.dashboard)
        else if dashCfg ? id then
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
      transform = dashCfg.transform or null;
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

    secretKeyFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to file containing the key Grafana encrypts secrets in its database with (loaded via systemd LoadCredential).";
    };

    influxdbTokenFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to file containing InfluxDB token (loaded via systemd LoadCredential).";
    };

  };

  config = lib.mkIf cfg.enable {
    services.grafana = {
      enable = true;

      # Grafana 13 no longer bundles these datasources and would download them at startup
      declarativePlugins = with pkgs.grafanaPlugins; [
        prometheus
        loki
        influxdb
        grafana-lokiexplore-app
        grafana-metricsdrilldown-app
      ];

      settings = {
        server = {
          http_addr = "0.0.0.0";
          http_port = cfg.port;
          domain = cfg.domain;
          root_url = "https://${cfg.domain}";
        };

        security = {
          admin_user = "admin";
          admin_password =
            if cfg.adminPasswordFile != null then
              "$__file{/run/credentials/grafana.service/admin-password}"
            else
              "$__file{/var/lib/grafana/admin-password}";
          secret_key = "$__file{/run/credentials/grafana.service/secret-key}";
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
          {
            name = "InfluxDB";
            type = "influxdb";
            uid = "influxdb-main";
            access = "proxy";
            url = "http://${influxdbCfg.bindAddress}:${toString serverCfg.influxdb.port}";
            jsonData = {
              version = "Flux";
              organization = "mares";
              defaultBucket = "home-assistant";
            };
            secureJsonData = {
              token = "$__file{/run/credentials/grafana.service/influxdb-token}";
            };
          }
        ];

        dashboards.settings.providers = dashboardProviders;
      };
    };

    systemd.services.grafana.serviceConfig.LoadCredential = [
      "influxdb-token:${cfg.influxdbTokenFile}"
      "secret-key:${cfg.secretKeyFile}"
    ]
    ++ lib.optional (cfg.adminPasswordFile != null) "admin-password:${cfg.adminPasswordFile}";

    systemd.tmpfiles.rules = lib.optional (
      cfg.adminPasswordFile == null
    ) "f /var/lib/grafana/admin-password 0600 grafana grafana - admin";

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
