# Home Assistant helper sensors - templates and integrations
{
  config,
  lib,
  ...
}:
let
  cfg = config.mares.home-assistant;
in
{
  config = lib.mkIf cfg.enable {
    services.home-assistant.config = lib.mkMerge [
      # Water rate helpers (requires wmbusmeters)
      (lib.mkIf cfg.components.wmbusmeters.enable {
        input_number = {
          drinking_water_rate = {
            name = "Drinking Water Rate";
            unit_of_measurement = "EUR/m³";
            min = 0;
            max = 10;
            step = 0.001;
            mode = "box";
            icon = "mdi:water";
            initial = 1.70;
          };
          wastewater_rate = {
            name = "Wastewater Rate";
            unit_of_measurement = "EUR/m³";
            min = 0;
            max = 10;
            step = 0.001;
            mode = "box";
            icon = "mdi:water-off";
            initial = 3.04;
          };
        };

        template = [
          {
            sensor = [
              {
                name = "Water Rate";
                unit_of_measurement = "EUR/m³";
                icon = "mdi:cash-multiple";
                state = ''
                  {{ (states('input_number.drinking_water_rate') | float(0) + states('input_number.wastewater_rate') | float(0)) | round(3) }}
                '';
              }
            ];
          }
        ];
      })

      # Battery energy helpers (requires evcc)
      (lib.mkIf cfg.components.evcc.enable {
        template = [
          {
            sensor = [
              {
                name = "Battery Charge Power";
                unit_of_measurement = "W";
                device_class = "power";
                state_class = "measurement";
                # evcc convention: negative = charging
                state = "{{ max(0, states('sensor.evcc_battery_power') | float(0) * -1) }}";
              }
              {
                name = "Battery Discharge Power";
                unit_of_measurement = "W";
                device_class = "power";
                state_class = "measurement";
                # evcc convention: positive = discharging
                state = "{{ max(0, states('sensor.evcc_battery_power') | float(0)) }}";
              }
            ];
          }
        ];

        sensor = [
          {
            platform = "integration";
            source = "sensor.battery_charge_power";
            name = "Battery Energy In";
            unit_prefix = "k";
            round = 2;
            method = "left";
          }
          {
            platform = "integration";
            source = "sensor.battery_discharge_power";
            name = "Battery Energy Out";
            unit_prefix = "k";
            round = 2;
            method = "left";
          }
        ];
      })
    ];
  };
}
