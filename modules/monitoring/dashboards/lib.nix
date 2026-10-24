{ lib }:
rec {
  datasource = {
    type = "prometheus";
    uid = "prometheus-main";
  };

  target =
    expr: extra:
    {
      refId = "A";
      inherit datasource expr;
    }
    // extra;

  # Builds one target per { expr, legendFormat } with refIds A, B, C, ...
  targets =
    extra: list:
    lib.imap0 (
      i: t:
      target t.expr (
        {
          refId = builtins.elemAt (lib.stringToCharacters "ABCDEFGHIJ") i;
          legendFormat = t.legendFormat or "";
        }
        // extra
      )
    ) list;

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
      expr ? null,
      queries ? null,
      thresholds,
      y ? 0,
      h ? 4,
      unit ? "short",
      mappings ? [ ],
      textMode ? "value",
      colorMode ? "background",
      legendFormat ? "",
    }:
    {
      inherit id title datasource;
      type = "stat";
      gridPos = { inherit x y w h; };
      targets =
        if queries != null then
          targets { instant = true; } queries
        else
          [
            (target expr {
              instant = true;
              inherit legendFormat;
            })
          ];
      fieldConfig = {
        defaults = {
          inherit unit mappings;
          thresholds = steps thresholds;
        };
        overrides = [ ];
      };
      options = {
        inherit textMode colorMode;
        graphMode = "none";
        reduceOptions.calcs = [ "lastNotNull" ];
      };
    };

  mkTimeseries =
    {
      id,
      title,
      gridPos,
      expr ? null,
      legendFormat ? "",
      queries ? null,
      unit,
      max ? null,
      bars ? false,
    }:
    {
      inherit
        id
        title
        datasource
        gridPos
        ;
      type = "timeseries";
      targets =
        if queries != null then targets { } queries else [ (target expr { inherit legendFormat; }) ];
      fieldConfig = {
        defaults = {
          inherit unit;
          min = 0;
          custom = {
            fillOpacity = if bars then 80 else 10;
            lineWidth = if bars then 0 else 1;
            drawStyle = if bars then "bars" else "line";
          }
          // lib.optionalAttrs bars { stacking.mode = "normal"; };
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
      sortBy ? "name",
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
          displayName = sortBy;
          desc = false;
        }
      ];
    };

  mkBargauge =
    {
      id,
      title,
      gridPos,
      queries,
      unit,
      thresholds,
      min ? null,
      max ? null,
    }:
    {
      inherit
        id
        title
        datasource
        gridPos
        ;
      type = "bargauge";
      targets = targets { instant = true; } queries;
      fieldConfig = {
        defaults = {
          inherit unit;
          thresholds = steps thresholds;
        }
        // lib.optionalAttrs (min != null) { inherit min; }
        // lib.optionalAttrs (max != null) { inherit max; };
        overrides = [ ];
      };
      options = {
        orientation = "horizontal";
        displayMode = "gradient";
        reduceOptions.calcs = [ "lastNotNull" ];
      };
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
}
