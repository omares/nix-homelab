{ lib }:
let
  inherit (import ./lib.nix { inherit lib; })
    mkStat
    mkTimeseries
    mkTable
    mkBargauge
    half
    third
    ;

  # Matches both the old "prometheus.scrape.<app>" and the plain "<app>" job names
  appLabel =
    expr: "label_replace(${expr}, \"app\", \"$1\", \"job\", \".*?(radarr|sonarr|prowlarr|sabnzbd)\")";
  healthIssues = "radarr_system_health_issues or sonarr_system_health_issues or prowlarr_system_health_issues";

  upDown = [
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
  upThresholds = [
    [
      "red"
      null
    ]
    [
      "green"
      1
    ]
  ];

  appStat =
    id: x: title: expr:
    mkStat {
      inherit id x title;
      w = 3;
      expr = "${expr} or vector(0)";
      thresholds = upThresholds;
      mappings = upDown;
    };

  libraryStat =
    id: x: title: queries:
    mkStat {
      inherit
        id
        x
        title
        queries
        ;
      y = 12;
      h = 5;
      w = 12;
      textMode = "value_and_name";
      colorMode = "none";
      thresholds = [
        [
          "text"
          null
        ]
      ];
    };

  indexerIncrease = metric: "increase(${metric}[$__interval])";
in
{
  uid = "exportarr";
  title = "Media";
  tags = [
    "media"
    "exportarr"
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
      name = "period";
      label = "Download period";
      type = "custom";
      query = "day,week,month,total";
      current = {
        text = "month";
        value = "month";
      };
      options =
        map
          (p: {
            text = p;
            value = p;
            selected = p == "month";
          })
          [
            "day"
            "week"
            "month"
            "total"
          ];
    }
  ];

  panels = [
    (appStat 1 0 "Radarr" "max(radarr_system_status)")
    (appStat 2 3 "Sonarr" "max(sonarr_system_status)")
    (appStat 3 6 "Prowlarr" "max(prowlarr_system_status)")
    (appStat 4 9 "SABnzbd" "max(up{job=~\".*sabnzbd\"})")
    (mkStat {
      id = 5;
      title = "Health issues";
      x = 12;
      w = 3;
      expr = "count(${healthIssues}) or vector(0)";
      thresholds = [
        [
          "green"
          null
        ]
        [
          "orange"
          1
        ]
      ];
    })
    (mkStat {
      id = 6;
      title = "Arr queue";
      x = 15;
      w = 3;
      expr = "sum(radarr_queue_total or sonarr_queue_total) or vector(0)";
      thresholds = [
        [
          "blue"
          null
        ]
      ];
    })
    (mkStat {
      id = 7;
      title = "SABnzbd speed";
      x = 18;
      w = 3;
      expr = "max(sabnzbd_queue_download_rate_bytes_per_second)";
      unit = "Bps";
      colorMode = "value";
      thresholds = [
        [
          "blue"
          null
        ]
      ];
    })
    (mkStat {
      id = 8;
      title = "SABnzbd";
      x = 21;
      w = 3;
      expr = "max(sabnzbd_paused)";
      thresholds = [
        [
          "green"
          null
        ]
        [
          "orange"
          1
        ]
      ];
      mappings = [
        {
          type = "value";
          options = {
            "0".text = "running";
            "1".text = "paused";
          };
        }
      ];
    })

    (mkTable {
      id = 9;
      title = "Health issues";
      gridPos = half 0 4;
      expr = "max by (app, type, source, message) (${appLabel healthIssues})";
      exclude = [
        "Time"
        "Value"
      ];
      sortBy = "app";
    })
    (mkBargauge {
      id = 10;
      title = "Free space per root folder";
      gridPos = half 12 4;
      queries = [
        {
          expr = "max by (app, path) (${appLabel "radarr_rootfolder_freespace_bytes or sonarr_rootfolder_freespace_bytes"})";
          legendFormat = "{{app}} {{path}}";
        }
      ];
      unit = "bytes";
      thresholds = [
        [
          "red"
          null
        ]
        [
          "orange"
          500000000000
        ]
        [
          "green"
          1000000000000
        ]
      ];
    })

    (libraryStat 11 0 "Radarr library" [
      {
        expr = "max(radarr_movie_total)";
        legendFormat = "movies";
      }
      {
        expr = "max(radarr_movie_downloaded_total)";
        legendFormat = "downloaded";
      }
      {
        expr = "max(radarr_movie_missing_total)";
        legendFormat = "missing";
      }
      {
        expr = "max(radarr_movie_wanted_total)";
        legendFormat = "wanted";
      }
      {
        expr = "max(radarr_movie_cutoff_unmet_total)";
        legendFormat = "cutoff unmet";
      }
    ])
    (libraryStat 12 12 "Sonarr library" [
      {
        expr = "max(sonarr_series_total)";
        legendFormat = "series";
      }
      {
        expr = "max(sonarr_episode_total)";
        legendFormat = "episodes";
      }
      {
        expr = "max(sonarr_episode_downloaded_total)";
        legendFormat = "downloaded";
      }
      {
        expr = "max(sonarr_episode_missing_total)";
        legendFormat = "missing";
      }
      {
        expr = "max(sonarr_episode_cutoff_unmet_total)";
        legendFormat = "cutoff unmet";
      }
    ])

    (mkTimeseries {
      id = 13;
      title = "Prowlarr queries & grabs";
      gridPos = third 0 17;
      queries = [
        {
          expr = "sum by (indexer) (${indexerIncrease "prowlarr_indexer_queries_total"})";
          legendFormat = "{{indexer}} queries";
        }
        {
          expr = "sum by (indexer) (${indexerIncrease "prowlarr_indexer_grabs_total"})";
          legendFormat = "{{indexer}} grabs";
        }
      ];
      unit = "short";
    })
    (mkTimeseries {
      id = 14;
      title = "Prowlarr failures";
      gridPos = third 8 17;
      queries = [
        {
          expr = "sum by (indexer) (${indexerIncrease "prowlarr_indexer_failed_queries_total"})";
          legendFormat = "{{indexer}} queries";
        }
        {
          expr = "sum by (indexer) (${indexerIncrease "prowlarr_indexer_failed_grabs_total"})";
          legendFormat = "{{indexer}} grabs";
        }
      ];
      unit = "short";
      bars = true;
    })
    (mkTimeseries {
      id = 15;
      title = "Prowlarr response time";
      gridPos = third 16 17;
      expr = "max by (indexer) (prowlarr_indexer_average_response_time_ms)";
      legendFormat = "{{indexer}}";
      unit = "ms";
    })

    (mkTimeseries {
      id = 16;
      title = "SABnzbd download speed";
      gridPos = third 0 25;
      expr = "max(sabnzbd_queue_download_rate_bytes_per_second)";
      legendFormat = "speed";
      unit = "Bps";
    })
    (mkTimeseries {
      id = 17;
      title = "SABnzbd queue";
      gridPos = third 8 25;
      queries = [
        {
          expr = "max(sabnzbd_queue_remaining_bytes)";
          legendFormat = "remaining";
        }
        {
          expr = "max(sabnzbd_queue_total_size_bytes)";
          legendFormat = "total";
        }
      ];
      unit = "bytes";
    })
    (mkBargauge {
      id = 18;
      title = "SABnzbd downloads ($period)";
      gridPos = third 16 25;
      queries = [
        {
          expr = "max(sabnzbd_download_bytes{period=\"$period\"})";
          legendFormat = "all servers";
        }
        {
          expr = "max by (server) (sabnzbd_server_download_bytes{period=\"$period\"})";
          legendFormat = "{{server}}";
        }
      ];
      unit = "bytes";
      thresholds = [
        [
          "blue"
          null
        ]
      ];
    })
  ];
}
