{ lib }:
let
  datasource = {
    type = "prometheus";
    uid = "prometheus-main";
  };

  # Every series is wrapped in max by (...) so overlapping scrape targets never double count
  guestInfo = "max by (id, name) (pve_guest_info{node=~\"$node\", template=\"0\"})";
  byGuest = expr: "max by (name) ((${expr}) * on (id) group_left (name) ${guestInfo})";
  byNode = metric: "max by (node) (label_replace(${metric}{id=~\"node/($node)\"}, \"node\", \"$1\", \"id\", \"node/(.+)\"))";

  storageLabels =
    expr:
    "label_replace(label_replace(${expr}, \"node\", \"$1\", \"id\", \"storage/([^/]+)/.+\"), \"storage\", \"$1\", \"id\", \"storage/[^/]+/(.+)\")";
  storageRatio =
    idRegex:
    "max by (id, node, storage) (${storageLabels "pve_disk_usage_bytes{id=~\"${idRegex}\"}"}) / max by (id, node, storage) (${storageLabels "pve_disk_size_bytes{id=~\"${idRegex}\"}"})";
  sharedStorage = "(max by (id) (pve_storage_shared) == 1)";

  target = expr: extra: {
    refId = "A";
    inherit datasource expr;
  }
  // extra;

  steps = list: {
    mode = "absolute";
    steps = map (s: {
      color = builtins.elemAt s 0;
      value = builtins.elemAt s 1;
    }) list;
  };

  mkStat =
    {
      id,
      title,
      x,
      w,
      expr,
      thresholds,
      mappings ? [ ],
      textMode ? "value",
      legendFormat ? "",
    }:
    {
      inherit id title datasource;
      type = "stat";
      gridPos = {
        h = 4;
        y = 0;
        inherit x w;
      };
      targets = [
        (target expr {
          instant = true;
          inherit legendFormat;
        })
      ];
      fieldConfig = {
        defaults = {
          thresholds = steps thresholds;
          inherit mappings;
        };
        overrides = [ ];
      };
      options = {
        colorMode = "background";
        graphMode = "none";
        inherit textMode;
        reduceOptions.calcs = [ "lastNotNull" ];
      };
    };

  mkTimeseries =
    {
      id,
      title,
      gridPos,
      expr,
      legendFormat,
      unit,
      max ? null,
    }:
    {
      inherit
        id
        title
        datasource
        gridPos
        ;
      type = "timeseries";
      targets = [ (target expr { inherit legendFormat; }) ];
      fieldConfig = {
        defaults = {
          inherit unit;
          min = 0;
          custom = {
            fillOpacity = 10;
            lineWidth = 1;
          };
        }
        // lib.optionalAttrs (max != null) { inherit max; };
        overrides = [ ];
      };
      options = {
        legend = {
          displayMode = "list";
          placement = "bottom";
        };
        tooltip.mode = "multi";
      };
    };

  mkTable =
    {
      id,
      title,
      gridPos,
      expr,
      exclude,
      overrides ? [ ],
    }:
    {
      inherit
        id
        title
        datasource
        gridPos
        ;
      type = "table";
      targets = [
        (target expr {
          format = "table";
          instant = true;
        })
      ];
      transformations = [
        {
          id = "organize";
          options.excludeByName = lib.genAttrs exclude (_: true);
        }
      ];
      fieldConfig = {
        defaults = { };
        inherit overrides;
      };
      options.sortBy = [
        {
          displayName = "name";
          desc = false;
        }
      ];
    };

  half = x: y: {
    h = 8;
    w = 12;
    inherit x y;
  };
  third = x: y: {
    h = 8;
    w = 8;
    inherit x y;
  };
in
{
  uid = "proxmox";
  title = "Proxmox";
  tags = [
    "proxmox"
    "prometheus"
  ];
  editable = false;
  refresh = "1m";
  schemaVersion = 39;
  time = {
    from = "now-6h";
    to = "now";
  };

  templating.list = [
    {
      name = "node";
      label = "Node";
      type = "query";
      inherit datasource;
      query = "label_values(pve_node_info, name)";
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
      title = "Quorum";
      x = 0;
      w = 3;
      expr = "count(pve_cluster_info{quorate=\"1\"}) or vector(0)";
      thresholds = [
        [
          "red"
          null
        ]
        [
          "green"
          1
        ]
      ];
      mappings = [
        {
          type = "value";
          options."0".text = "No quorum";
        }
        {
          type = "range";
          options = {
            from = 1;
            to = 1000;
            result.text = "Quorate";
          };
        }
      ];
    })
    (mkStat {
      id = 2;
      title = "Nodes offline";
      x = 3;
      w = 3;
      expr = "count(max by (id) (pve_up{id=~\"node/.+\"}) == 0) or vector(0)";
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
      title = "Guests running";
      x = 6;
      w = 4;
      expr = "sum(max by (id) (pve_up{id=~\"(qemu|lxc)/.+\"}))";
      thresholds = [
        [
          "blue"
          null
        ]
      ];
    })
    (mkStat {
      id = 4;
      title = "Onboot but stopped";
      x = 10;
      w = 4;
      expr = "count(max by (id) (pve_onboot_status) == 1 unless on (id) (max by (id) (pve_up) == 1)) or vector(0)";
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
      id = 5;
      title = "Not backed up";
      x = 14;
      w = 3;
      expr = "max(pve_not_backed_up_total)";
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
      title = "Locked guests";
      x = 17;
      w = 3;
      expr = "count(max by (id, state) (pve_lock_state) == 1) or vector(0)";
      thresholds = [
        [
          "green"
          null
        ]
        [
          "yellow"
          1
        ]
      ];
    })
    (mkStat {
      id = 7;
      title = "PVE version";
      x = 20;
      w = 4;
      expr = "max by (version) (pve_version_info)";
      legendFormat = "{{version}}";
      textMode = "name";
      thresholds = [
        [
          "text"
          null
        ]
      ];
    })

    (mkTimeseries {
      id = 10;
      title = "Node CPU";
      gridPos = half 0 4;
      expr = byNode "pve_cpu_usage_ratio";
      legendFormat = "{{node}}";
      unit = "percentunit";
      max = 1;
    })
    (mkTimeseries {
      id = 11;
      title = "Node memory";
      gridPos = half 12 4;
      expr = "${byNode "pve_memory_usage_bytes"} / ${byNode "pve_memory_size_bytes"}";
      legendFormat = "{{node}}";
      unit = "percentunit";
      max = 1;
    })

    {
      id = 12;
      title = "Storage usage";
      type = "bargauge";
      inherit datasource;
      gridPos = half 0 12;
      targets = [
        (target "max by (node, storage) (${storageRatio "storage/($node)/.+"} unless on (id) ${sharedStorage})" {
          instant = true;
          legendFormat = "{{node}}/{{storage}}";
        })
        (target "max by (storage) (${storageRatio "storage/.+"} and on (id) ${sharedStorage})" {
          refId = "B";
          instant = true;
          legendFormat = "{{storage}} (shared)";
        })
      ];
      fieldConfig = {
        defaults = {
          unit = "percentunit";
          min = 0;
          max = 1;
          thresholds = steps [
            [
              "green"
              null
            ]
            [
              "orange"
              0.8
            ]
            [
              "red"
              0.9
            ]
          ];
        };
        overrides = [ ];
      };
      options = {
        orientation = "horizontal";
        displayMode = "gradient";
        reduceOptions.calcs = [ "lastNotNull" ];
      };
    }
    (mkTimeseries {
      id = 13;
      title = "Guest CPU (cores used, top 10)";
      gridPos = half 12 12;
      expr = "topk(10, ${byGuest "max by (id) (pve_cpu_usage_ratio) * max by (id) (pve_cpu_usage_limit)"})";
      legendFormat = "{{name}}";
      unit = "none";
    })

    (mkTimeseries {
      id = 14;
      title = "Guest memory (PVE view incl. page cache, top 10)";
      gridPos = third 0 20;
      expr = "topk(10, ${byGuest "max by (id) (pve_memory_usage_bytes)"})";
      legendFormat = "{{name}}";
      unit = "bytes";
    })
    (mkTimeseries {
      id = 15;
      title = "Guest disk I/O (top 10)";
      gridPos = third 8 20;
      expr = "topk(10, ${byGuest "max by (id) (rate(pve_disk_read_bytes_total[$__rate_interval])) + max by (id) (rate(pve_disk_written_bytes_total[$__rate_interval]))"})";
      legendFormat = "{{name}}";
      unit = "Bps";
    })
    (mkTimeseries {
      id = 16;
      title = "Guest network (top 10)";
      gridPos = third 16 20;
      expr = "topk(10, ${byGuest "max by (id) (rate(pve_network_receive_bytes_total[$__rate_interval])) + max by (id) (rate(pve_network_transmit_bytes_total[$__rate_interval]))"})";
      legendFormat = "{{name}}";
      unit = "Bps";
    })

    (mkTable {
      id = 17;
      title = "Guests";
      gridPos = {
        h = 12;
        w = 16;
        x = 0;
        y = 28;
      };
      expr = "max by (name, node, type) (pve_guest_info{node=~\"$node\", template=\"0\"} * on (id) group_left () max by (id) (pve_up))";
      exclude = [ "Time" ];
      overrides = [
        {
          matcher = {
            id = "byName";
            options = "Value";
          };
          properties = [
            {
              id = "displayName";
              value = "status";
            }
            {
              id = "mappings";
              value = [
                {
                  type = "value";
                  options = {
                    "0" = {
                      text = "stopped";
                      color = "red";
                    };
                    "1" = {
                      text = "running";
                      color = "green";
                    };
                  };
                }
              ];
            }
            {
              id = "custom.cellOptions";
              value.type = "color-text";
            }
          ];
        }
      ];
    })
    (mkTable {
      id = 18;
      title = "Guests without backup job";
      gridPos = {
        h = 12;
        w = 8;
        x = 16;
        y = 28;
      };
      expr = "max by (name, node) (pve_guest_info{node=~\"$node\"} * on (id) group_left () max by (id) (pve_not_backed_up_info))";
      exclude = [
        "Time"
        "Value"
      ];
    })
  ];
}
