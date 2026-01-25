# Mares Home Dashboard
#
# Energy price visualization using ApexCharts cards for Ostrom integration.
{ format }:
let
  priceColorRanges = [
    {
      from = 0;
      to = 0.15;
      color = "#2ecc71";
    }
    {
      from = 0.15;
      to = 0.2;
      color = "#a6d96a";
    }
    {
      from = 0.2;
      to = 0.25;
      color = "#ffff99";
    }
    {
      from = 0.25;
      to = 0.3;
      color = "#fdae61";
    }
    {
      from = 0.3;
      to = 0.35;
      color = "#f46d43";
    }
    {
      from = 0.35;
      to = 1;
      color = "#d73027";
    }
  ];

  apexConfig = {
    xaxis = {
      type = "datetime";
      labels.datetimeFormatter = {
        hour = "HH:mm";
        day = "dd MMM";
      };
    };
    plotOptions.bar.colors.ranges = priceColorRanges;
  };

  currentPriceCard = {
    type = "custom:apexcharts-card";
    graph_span = "24h";
    header = {
      title = "Strompreise (€/kWh)";
      show = true;
    };
    apex_config = apexConfig;
    series = [
      {
        entity = "sensor.ostrom_energy_spot_price";
        type = "column";
        name = "Preis";
        float_precision = 3;
        group_by = {
          duration = "1h";
          func = "avg";
        };
        show = {
          datalabels = false;
          in_header = false;
        };
      }
    ];
    yaxis = [
      {
        min = 0;
        max = 0.5;
      }
    ];
  };

  futurePriceCard = {
    type = "custom:apexcharts-card";
    graph_span = "23h";
    span = {
      start = "hour";
      offset = "-1h";
    };
    header = {
      title = "Strompreise Zukunft (€/kWh)";
      show = true;
    };
    apex_config = apexConfig;
    series = [
      {
        entity = "sensor.ostrom_energy_spot_price";
        attribute = "prices";
        float_precision = 3;
        type = "column";
        name = "Preis";
        data_generator = ''
          const prices = entity.attributes.prices;
          return Object.entries(prices).map(([timestamp, value]) => {
            const date = new Date(timestamp);
            return [date, value];
          });
        '';
        show = {
          datalabels = false;
          in_header = true;
        };
      }
    ];
    yaxis = [
      {
        min = 0;
        max = 0.5;
      }
    ];
  };
in
format.generate "mares-home.yaml" {
  title = "Mares Home";
  views = [
    {
      title = "Energy";
      path = "energy";
      icon = "mdi:lightning-bolt";
      cards = [
        currentPriceCard
        futurePriceCard
      ];
    }
  ];
}
