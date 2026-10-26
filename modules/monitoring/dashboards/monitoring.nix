{ lib }:
let
  inherit (import ./lib.nix { inherit lib; })
    mkStat
    mkTimeseries
    half
    ;

  node = ''instance="mon-01", job="node"'';
  # Prometheus scrapes itself as localhost:9090, everything else is pushed by Alloy as mon-01
  stack = ''instance=~"mon-01|localhost:9090", job=~"prometheus|loki|integrations/self|unpoller"'';
  memUsed = "1 - node_memory_MemAvailable_bytes{${node}} / node_memory_MemTotal_bytes{${node}}";
  ioStall = "rate(node_pressure_io_stalled_seconds_total{${node}}[$__rate_interval])";
  neutral = [
    [
      "green"
      null
    ]
  ];
in
{
  uid = "monitoring";
  title = "Monitoring Stack";
  tags = [
    "monitoring"
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
      title = "mon-01 memory";
      x = 0;
      w = 4;
      expr = memUsed;
      unit = "percentunit";
      thresholds = [
        [
          "green"
          null
        ]
        [
          "orange"
          0.75
        ]
        [
          "red"
          0.85
        ]
      ];
    })
    (mkStat {
      id = 2;
      title = "IO stalled";
      x = 4;
      w = 4;
      expr = ioStall;
      unit = "percentunit";
      thresholds = [
        [
          "green"
          null
        ]
        [
          "orange"
          0.05
        ]
        [
          "red"
          0.15
        ]
      ];
    })
    (mkStat {
      id = 3;
      title = "Active series";
      x = 8;
      w = 4;
      expr = "prometheus_tsdb_head_series";
      thresholds = neutral;
      colorMode = "none";
    })
    (mkStat {
      id = 4;
      title = "Samples/s";
      x = 12;
      w = 4;
      expr = "rate(prometheus_tsdb_head_samples_appended_total[$__rate_interval])";
      unit = "short";
      thresholds = neutral;
      colorMode = "none";
    })
    (mkStat {
      id = 5;
      title = "Log lines/s";
      x = 16;
      w = 4;
      expr = "sum(rate(loki_distributor_lines_received_total[$__rate_interval]))";
      unit = "short";
      thresholds = neutral;
      colorMode = "none";
    })
    (mkStat {
      id = 6;
      title = "Prometheus disk";
      x = 20;
      w = 4;
      expr = "prometheus_tsdb_storage_blocks_bytes + prometheus_tsdb_wal_storage_size_bytes";
      unit = "bytes";
      thresholds = neutral;
      colorMode = "none";
    })

    (mkTimeseries {
      id = 7;
      title = "Memory per service";
      gridPos = half 0 4;
      # Grafana prefixes its process metrics, InfluxDB only exposes Go runtime memory
      expr = ''max by (job) (process_resident_memory_bytes{${stack}}) or max by (job) (grafana_process_resident_memory_bytes{instance="mon-01"}) or max by (job) (go_memstats_sys_bytes{instance="mon-01", job="influxdb"})'';
      legendFormat = "{{job}}";
      unit = "bytes";
      bars = true;
    })
    (mkTimeseries {
      id = 8;
      title = "mon-01 pressure";
      gridPos = half 12 4;
      unit = "percentunit";
      queries = [
        {
          expr = memUsed;
          legendFormat = "Memory used";
        }
        {
          expr = ioStall;
          legendFormat = "IO stalled";
        }
        {
          expr = "rate(node_pressure_memory_stalled_seconds_total{${node}}[$__rate_interval])";
          legendFormat = "Memory stalled";
        }
        {
          expr = "rate(node_pressure_cpu_waiting_seconds_total{${node}}[$__rate_interval])";
          legendFormat = "CPU waiting";
        }
      ];
    })

    (mkTimeseries {
      id = 9;
      title = "Prometheus series and ingestion";
      gridPos = half 0 12;
      unit = "short";
      queries = [
        {
          expr = "prometheus_tsdb_head_series";
          legendFormat = "Active series";
        }
        {
          expr = "rate(prometheus_tsdb_head_samples_appended_total[$__rate_interval])";
          legendFormat = "Samples/s";
        }
      ];
    })
    (mkTimeseries {
      id = 10;
      title = "Slowest scrapes";
      gridPos = half 12 12;
      expr = "topk(10, max by (job) (scrape_duration_seconds))";
      legendFormat = "{{job}}";
      unit = "s";
    })

    (mkTimeseries {
      id = 11;
      title = "Loki ingestion";
      gridPos = half 0 20;
      unit = "Bps";
      queries = [
        {
          expr = "sum(rate(loki_distributor_bytes_received_total[$__rate_interval]))";
          legendFormat = "Received";
        }
        {
          expr = "sum by (reason) (rate(loki_discarded_bytes_total[$__rate_interval]))";
          legendFormat = "Discarded: {{reason}}";
        }
      ];
    })
    (mkTimeseries {
      id = 12;
      title = "Grafana requests";
      gridPos = half 12 20;
      expr = "sum by (status_code) (rate(grafana_http_request_duration_seconds_count[$__rate_interval]))";
      legendFormat = "{{status_code}}";
      unit = "reqps";
    })
  ];
}
