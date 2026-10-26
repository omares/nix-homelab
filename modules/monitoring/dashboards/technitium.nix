{ lib }:
let
  inherit (import ./lib.nix { inherit lib; })
    mkStat
    mkTimeseries
    half
    ;

  rate = metric: "sum(rate(technitium_${metric}_total{instance=~\"$instance\"}[$__rate_interval]))";
  ratio = metric: "${rate metric} / ${rate "queries"}";
  neutral = [
    [
      "green"
      null
    ]
  ];
in
{
  uid = "technitium";
  title = "Technitium DNS";
  tags = [
    "dns"
    "technitium"
    "prometheus"
  ];
  editable = false;
  refresh = "1m";
  schemaVersion = 39;
  time = {
    from = "now-24h";
    to = "now";
  };

  templating.list = [
    {
      name = "instance";
      label = "Node";
      type = "query";
      datasource = {
        type = "prometheus";
        uid = "prometheus-main";
      };
      query = "label_values(technitium_queries_total, instance)";
      refresh = 1;
      includeAll = true;
      multi = true;
      allValue = ".+";
      sort = 1;
      current = {
        text = "All";
        value = "$__all";
      };
    }
  ];

  panels = [
    (mkStat {
      id = 1;
      title = "Queries/s";
      x = 0;
      w = 4;
      expr = rate "queries";
      unit = "reqps";
      thresholds = neutral;
      colorMode = "none";
    })
    (mkStat {
      id = 2;
      title = "Cache hits";
      x = 4;
      w = 4;
      expr = ratio "cached";
      unit = "percentunit";
      thresholds = neutral;
      colorMode = "none";
    })
    (mkStat {
      id = 3;
      title = "Blocked";
      x = 8;
      w = 4;
      expr = ratio "blocked";
      unit = "percentunit";
      thresholds = neutral;
      colorMode = "none";
    })
    (mkStat {
      id = 4;
      title = "NXDOMAIN";
      x = 12;
      w = 4;
      expr = ratio "nx_domain";
      unit = "percentunit";
      thresholds = neutral;
      colorMode = "none";
    })
    (mkStat {
      id = 5;
      title = "SERVFAIL";
      x = 16;
      w = 4;
      expr = ratio "server_failure";
      unit = "percentunit";
      thresholds = [
        [
          "green"
          null
        ]
        [
          "orange"
          0.01
        ]
        [
          "red"
          0.05
        ]
      ];
    })
    (mkStat {
      id = 6;
      title = "Uptime";
      x = 20;
      w = 4;
      expr = "min(technitium_uptime_seconds{instance=~\"$instance\"})";
      unit = "dtdurations";
      thresholds = [
        [
          "orange"
          null
        ]
        [
          "green"
          3600
        ]
      ];
      colorMode = "none";
    })

    (mkTimeseries {
      id = 7;
      title = "Queries per node";
      gridPos = half 0 4;
      expr = "sum by (instance) (rate(technitium_queries_total{instance=~\"$instance\"}[$__rate_interval]))";
      legendFormat = "{{instance}}";
      unit = "reqps";
    })
    (mkTimeseries {
      id = 8;
      title = "Answered by";
      gridPos = half 12 4;
      unit = "reqps";
      bars = true;
      queries = [
        {
          expr = rate "authoritative";
          legendFormat = "Authoritative";
        }
        {
          expr = rate "cached";
          legendFormat = "Cache";
        }
        {
          expr = rate "recursive";
          legendFormat = "Recursive";
        }
        {
          expr = rate "blocked";
          legendFormat = "Blocked";
        }
      ];
    })
    (mkTimeseries {
      id = 9;
      title = "Response codes";
      gridPos = half 0 12;
      unit = "reqps";
      bars = true;
      queries = [
        {
          expr = rate "no_error";
          legendFormat = "NOERROR";
        }
        {
          expr = rate "nx_domain";
          legendFormat = "NXDOMAIN";
        }
        {
          expr = rate "server_failure";
          legendFormat = "SERVFAIL";
        }
        {
          expr = rate "refused";
          legendFormat = "REFUSED";
        }
        {
          expr = rate "dropped";
          legendFormat = "Dropped";
        }
      ];
    })
    (mkTimeseries {
      id = 10;
      title = "Error rates";
      gridPos = half 12 12;
      unit = "percentunit";
      queries = [
        {
          expr = ratio "server_failure";
          legendFormat = "SERVFAIL";
        }
        {
          expr = ratio "nx_domain";
          legendFormat = "NXDOMAIN";
        }
        {
          expr = ratio "refused";
          legendFormat = "REFUSED";
        }
      ];
    })
  ];
}
