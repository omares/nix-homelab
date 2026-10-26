{ lib }:
let
  inherit (import ./lib.nix { inherit lib; })
    datasource
    targets
    mkStat
    mkTimeseries
    steps
    ;

  probe = metric: "max by (service, domains) (${metric}{job=\"blackbox\"})";
in
{
  uid = "uptime";
  title = "Uptime";
  tags = [
    "blackbox"
    "prometheus"
  ];
  editable = false;
  refresh = "1m";
  schemaVersion = 39;
  time = {
    from = "now-24h";
    to = "now";
  };

  panels = [
    (mkStat {
      id = 1;
      title = "Up";
      x = 0;
      w = 6;
      expr = "sum(probe_success{job=\"blackbox\"})";
      thresholds = [
        [
          "green"
          null
        ]
      ];
    })
    (mkStat {
      id = 2;
      title = "Down";
      x = 6;
      w = 6;
      expr = "count(probe_success{job=\"blackbox\"} == 0) or vector(0)";
      thresholds = [
        [
          "green"
          null
        ]
        [
          "red"
          1
        ]
      ];
    })
    (mkStat {
      id = 3;
      title = "Slowest response";
      x = 12;
      w = 6;
      expr = "max(probe_duration_seconds{job=\"blackbox\"})";
      unit = "s";
      thresholds = [
        [
          "green"
          null
        ]
        [
          "orange"
          1
        ]
        [
          "red"
          3
        ]
      ];
    })
    (mkStat {
      id = 4;
      title = "Next cert expiry";
      x = 18;
      w = 6;
      expr = "min(probe_ssl_earliest_cert_expiry{job=\"blackbox\"}) - time()";
      unit = "dtdurations";
      thresholds = [
        [
          "red"
          null
        ]
        [
          "orange"
          1209600
        ]
        [
          "green"
          2592000
        ]
      ];
    })

    {
      id = 5;
      title = "Services";
      type = "table";
      inherit datasource;
      gridPos = {
        h = 14;
        w = 24;
        x = 0;
        y = 4;
      };
      targets =
        targets
          {
            format = "table";
            instant = true;
          }
          [
            { expr = probe "probe_success"; }
            { expr = probe "probe_http_status_code"; }
            { expr = probe "probe_duration_seconds"; }
            { expr = "${probe "probe_ssl_earliest_cert_expiry"} - time()"; }
          ];
      transformations = [
        {
          id = "merge";
          options = { };
        }
        {
          id = "organize";
          options = {
            excludeByName.Time = true;
            indexByName = {
              service = 0;
              domains = 1;
              "Value #A" = 2;
              "Value #B" = 3;
              "Value #C" = 4;
              "Value #D" = 5;
            };
            renameByName = {
              service = "Service";
              domains = "Domains";
              "Value #A" = "Status";
              "Value #B" = "HTTP";
              "Value #C" = "Response";
              "Value #D" = "Cert expires in";
            };
          };
        }
      ];
      fieldConfig = {
        defaults = { };
        overrides = [
          {
            matcher = {
              id = "byName";
              options = "Status";
            };
            properties = [
              {
                id = "mappings";
                value = [
                  {
                    type = "value";
                    options = {
                      "0" = {
                        text = "DOWN";
                        color = "red";
                      };
                      "1" = {
                        text = "UP";
                        color = "green";
                      };
                    };
                  }
                ];
              }
              {
                id = "custom.cellOptions";
                value.type = "color-background";
              }
            ];
          }
          {
            matcher = {
              id = "byName";
              options = "Response";
            };
            properties = [
              {
                id = "unit";
                value = "s";
              }
              {
                id = "decimals";
                value = 2;
              }
            ];
          }
          {
            matcher = {
              id = "byName";
              options = "Cert expires in";
            };
            properties = [
              {
                id = "unit";
                value = "dtdurations";
              }
              {
                id = "custom.cellOptions";
                value.type = "color-text";
              }
              {
                id = "thresholds";
                value = steps [
                  [
                    "red"
                    null
                  ]
                  [
                    "orange"
                    1209600
                  ]
                  [
                    "green"
                    2592000
                  ]
                ];
              }
            ];
          }
        ];
      };
      options.sortBy = [
        {
          displayName = "Status";
          desc = false;
        }
      ];
    }

    {
      id = 6;
      title = "Availability";
      type = "state-timeline";
      inherit datasource;
      gridPos = {
        h = 14;
        w = 24;
        x = 0;
        y = 18;
      };
      targets = targets { } [
        {
          expr = probe "probe_success";
          legendFormat = "{{service}}";
        }
      ];
      fieldConfig = {
        defaults = {
          mappings = [
            {
              type = "value";
              options = {
                "0" = {
                  text = "down";
                  color = "red";
                };
                "1" = {
                  text = "up";
                  color = "green";
                };
              };
            }
          ];
          custom.fillOpacity = 80;
        };
        overrides = [ ];
      };
      options = {
        showValue = "never";
        mergeValues = true;
        legend.showLegend = false;
      };
    }

    (mkTimeseries {
      id = 7;
      title = "Response time";
      gridPos = {
        h = 10;
        w = 24;
        x = 0;
        y = 32;
      };
      expr = probe "probe_duration_seconds";
      legendFormat = "{{service}}";
      unit = "s";
    })
  ];
}
