# Home Assistant Template Sensors
{
  config,
  lib,
  ...
}:
let
  cfg = config.mares.home-assistant;
  hideLabel = "hide-dashboard";
in
{
  config = lib.mkIf (cfg.enable) {
    services.home-assistant.config.template = [
      {
        sensor = [
          {
            name = "Lights On";
            unique_id = "lights_on";
            state = ''
              {% set exclude = label_entities('${hideLabel}') %}
              {{ states.light
                | selectattr('state','eq','on')
                | rejectattr('entity_id','in', exclude)
                | list
                | count }}
            '';
            icon = "mdi:lightbulb-on-outline";
          }
          {
            name = "Shutters Open";
            unique_id = "shutters_open";
            state = ''
              {% set exclude = label_entities('${hideLabel}') %}
              {{ states.cover
                | selectattr('attributes.device_class', 'eq', 'shutter')
                | selectattr('state', 'eq', 'open')
                | rejectattr('entity_id','in', exclude)
                | list | count }}
            '';
            icon = "mdi:window-shutter-open";
          }
          {
            name = "Locks Unlocked";
            unique_id = "locks_unlocked";
            state = ''
              {% set exclude = label_entities('${hideLabel}') %}
              {{ states.lock
                | selectattr('state', 'eq', 'unlocked')
                | rejectattr('entity_id','in', exclude)
                | list | count }}
            '';
            icon = "mdi:lock-open-outline";
          }
          {
            name = "Sunrise Time";
            unique_id = "sunrise_time";
            state = ''{{ as_timestamp(state_attr('sun.sun', 'next_rising')) | timestamp_custom('%H:%M') }}'';
          }
          {
            name = "Sunset Time";
            unique_id = "sunset_time";
            state = ''{{ as_timestamp(state_attr('sun.sun', 'next_setting')) | timestamp_custom('%H:%M') }}'';
          }
          {
            name = "Day Progress";
            unique_id = "day_progress";
            state = ''
              {% set now_ts = as_timestamp(now()) %}
              {% set rising = state_attr('sun.sun', 'next_rising') %}
              {% set setting = state_attr('sun.sun', 'next_setting') %}
              {% if rising and setting %}
                {% set sunrise_ts = as_timestamp(rising) %}
                {% set sunset_ts = as_timestamp(setting) %}
                {% if now_ts < sunrise_ts %}
                  {# Before sunrise - night/morning #}
                  0
                {% elif now_ts > sunset_ts %}
                  {# After sunset - evening/night #}
                  100
                {% else %}
                  {# During daytime #}
                  {% set day_length = sunset_ts - sunrise_ts %}
                  {% set elapsed = now_ts - sunrise_ts %}
                  {{ ((elapsed / day_length) * 100) | round(0) }}
                {% endif %}
              {% else %}0{% endif %}
            '';
            unit_of_measurement = "%";
            icon = "mdi:sun-clock";
          }
          {
            name = "Current Date Time";
            unique_id = "current_date_time";
            state = ''{{ now().strftime('%a, %d %b %H:%M') }}'';
            icon = "mdi:clock-outline";
          }
        ];
      }
      {
        trigger = [
          {
            platform = "time_pattern";
            minutes = "/30";
          }
          {
            platform = "homeassistant";
            event = "start";
          }
        ];
        action = [
          {
            service = "weather.get_forecasts";
            data = {
              type = "daily";
            };
            target.entity_id = "weather.home";
            response_variable = "weather_forecast";
          }
        ];
        sensor = [
          {
            name = "Weather Forecast Today";
            unique_id = "weather_forecast_today";
            state = ''
              {% set forecast = weather_forecast['weather.home'].forecast | default([]) %}
              {% if forecast | length > 0 %}
                {{ forecast[0].temperature }}°C {{ forecast[0].condition }}
              {% else %}unavailable{% endif %}
            '';
            attributes = {
              condition = ''
                {% set forecast = weather_forecast['weather.home'].forecast | default([]) %}
                {{ forecast[0].condition if forecast | length > 0 else 'unknown' }}
              '';
            };
          }
          {
            name = "Weather Forecast Tomorrow";
            unique_id = "weather_forecast_tomorrow";
            state = ''
              {% set forecast = weather_forecast['weather.home'].forecast | default([]) %}
              {% if forecast | length > 1 %}
                {{ forecast[1].temperature }}°C {{ forecast[1].condition }}
              {% else %}unavailable{% endif %}
            '';
            attributes = {
              condition = ''
                {% set forecast = weather_forecast['weather.home'].forecast | default([]) %}
                {{ forecast[1].condition if forecast | length > 1 else 'unknown' }}
              '';
            };
          }
        ];
      }
      {
        trigger = [
          {
            platform = "time_pattern";
            hours = "/1";
          }
          {
            platform = "homeassistant";
            event = "start";
          }
        ];
        action = [
          {
            service = "calendar.get_events";
            target.entity_id = "calendar.abfallwirtschaft_potsdam_mittelmark_apm";
            data = {
              duration.days = 14;
            };
            response_variable = "calendar_events";
          }
        ];
        sensor = [
          {
            name = "Dashboard Icon Waste Type";
            unique_id = "dashboard_icon_waste_type";
            state = ''
              {% set events = calendar_events['calendar.abfallwirtschaft_potsdam_mittelmark_apm'].events | default([]) %}
              {% if events | length > 0 %}
                {% set next_event = events | sort(attribute='start') | first %}
                {{ next_event.summary }}
              {% else %}unknown{% endif %}
            '';
            icon = ''
              {% set events = calendar_events['calendar.abfallwirtschaft_potsdam_mittelmark_apm'].events | default([]) %}
              {% if events | length > 0 %}
                {% set next_event = events | sort(attribute='start') | first %}
                {% set message = next_event.summary | lower %}
                {% if 'grün' in message or 'bio' in message %}mdi:leaf
                {% elif 'gelb' in message %}mdi:recycle
                {% elif 'rest' in message or 'müll' in message %}mdi:trash-can
                {% elif 'papier' in message %}mdi:file-document
                {% elif 'schad' in message %}mdi:alert
                {% else %}mdi:calendar{% endif %}
              {% else %}mdi:calendar{% endif %}
            '';
            attributes = {
              color_mapping = ''
                {% set events = calendar_events['calendar.abfallwirtschaft_potsdam_mittelmark_apm'].events | default([]) %}
                {% if events | length > 0 %}
                  {% set next_event = events | sort(attribute='start') | first %}
                  {% set message = next_event.summary | lower %}
                  {% if 'papier' in message %}#2196F3
                  {% elif 'gelb' in message %}#FFEB3B
                  {% elif 'grün' in message or 'bio' in message %}#795548
                  {% elif 'rest' in message or 'müll' in message %}#FFFFFF
                  {% elif 'schad' in message %}#F44336
                  {% else %}#9E9E9E{% endif %}
                {% else %}#9E9E9E{% endif %}
              '';
            };
          }
          {
            name = "Dashboard Icon Battery SOC";
            unique_id = "dashboard_icon_battery_soc";
            state = ''{{ states('sensor.evcc_battery_soc') }}'';
            unit_of_measurement = "%";
            icon = ''
              {% set soc = states('sensor.evcc_battery_soc') | int(0) %}
              {% if soc == 0 %}mdi:battery-outline
              {% elif soc <= 10 %}mdi:battery-10
              {% elif soc <= 20 %}mdi:battery-20
              {% elif soc <= 30 %}mdi:battery-30
              {% elif soc <= 40 %}mdi:battery-40
              {% elif soc <= 50 %}mdi:battery-50
              {% elif soc <= 60 %}mdi:battery-60
              {% elif soc <= 70 %}mdi:battery-70
              {% elif soc <= 80 %}mdi:battery-80
              {% elif soc <= 90 %}mdi:battery-90
              {% else %}mdi:battery{% endif %}
            '';
          }
          {
            name = "Dashboard Icon Vacuum SOC";
            unique_id = "dashboard_icon_vacuum_soc";
            state = ''{{ states('sensor.office_robot_vacuum_dock_battery') }}'';
            unit_of_measurement = "%";
            icon = ''
              {% set soc = states('sensor.office_robot_vacuum_dock_battery') | int(0) %}
              {% if soc == 0 %}mdi:battery-outline
              {% elif soc <= 10 %}mdi:battery-10
              {% elif soc <= 20 %}mdi:battery-20
              {% elif soc <= 30 %}mdi:battery-30
              {% elif soc <= 40 %}mdi:battery-40
              {% elif soc <= 50 %}mdi:battery-50
              {% elif soc <= 60 %}mdi:battery-60
              {% elif soc <= 70 %}mdi:battery-70
              {% elif soc <= 80 %}mdi:battery-80
              {% elif soc <= 90 %}mdi:battery-90
              {% else %}mdi:battery{% endif %}
            '';
          }
          {
            name = "Dashboard Icon EV SOC";
            unique_id = "dashboard_icon_ev_soc";
            state = ''{{ states('sensor.evcc_carport_vehicle_soc') | int(0) }} → {{ states('sensor.evcc_carport_vehicle_limit_soc') | int(0) }}'';
            icon = ''
              {% if is_state('binary_sensor.evcc_carport_connected', 'on') %}
                {% if is_state('binary_sensor.evcc_carport_charging', 'on') %}mdi:lightning-bolt
                {% else %}mdi:car-electric{% endif %}
              {% else %}mdi:car-off{% endif %}
            '';
            attributes = {
              is_charging = ''{{ is_state('binary_sensor.evcc_carport_charging', 'on') }}'';
              limit_soc = ''{{ states('sensor.evcc_carport_vehicle_limit_soc') | int(0) }}'';
            };
          }
        ];
      }
    ];
  };
}
