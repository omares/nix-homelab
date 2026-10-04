# Home Assistant Template Sensors
{
  config,
  lib,
  ...
}:
let
  cfg = config.mares.home-assistant;
  hideLabel = "hide-dashboard";

  # Rooms shown with counters on the dashboard; members are resolved via area_entities
  lightRooms = {
    living_room = "Living Room";
    kitchen = "Kitchen";
    office = "Office";
    utility_room = "Utility Room";
    staircase = "Staircase";
    patio = "Patio";
  };
  coverRooms = {
    living_room = "Living Room";
    kitchen = "Kitchen";
    office = "Office";
    utility_room = "Utility Room";
    guest_bathroom = "Guest Bathroom";
    hallway = "Hallway";
  };

  # Light groups and hidden entities are skipped so lights are not counted twice
  mkLightsOn = area: name: {
    name = "${name} Lights On";
    unique_id = "${area}_lights_on";
    state = ''
      {% set ns = namespace(n=0) %}
      {% for e in area_entities('${area}') if e.startswith('light.') and is_state(e, 'on')
           and not is_hidden_entity(e) and state_attr(e, 'entity_id') is none
           and device_attr(e, 'model') != 'Group' %}
        {% set ns.n = ns.n + 1 %}
      {% endfor %}
      {{ ns.n }}
    '';
    icon = "{{ 'mdi:lightbulb-group' if this.state | int(0) > 0 else 'mdi:lightbulb-group-off' }}";
  };

  mkShuttersOpen = area: name: {
    name = "${name} Shutters Open";
    unique_id = "${area}_shutters_open";
    state = ''
      {{ area_entities('${area}') | select('match', 'cover\.')
         | select('is_state', ['open', 'opening']) | list | count }}
    '';
    icon = "{{ 'mdi:window-shutter-open' if this.state | int(0) > 0 else 'mdi:window-shutter' }}";
  };
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
            state = "{{ as_timestamp(state_attr('sun.sun', 'next_rising')) | timestamp_custom('%H:%M') }}";
          }
          {
            name = "Sunset Time";
            unique_id = "sunset_time";
            state = "{{ as_timestamp(state_attr('sun.sun', 'next_setting')) | timestamp_custom('%H:%M') }}";
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
            state = "{{ now().strftime('%a, %d %b %H:%M') }}";
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
            action = "weather.get_forecasts";
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
            platform = "time";
            at = "00:00:05";
          }
          {
            platform = "homeassistant";
            event = "start";
          }
        ];
        action = [
          {
            action = "calendar.get_events";
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
            name = "Waste Next Collection";
            unique_id = "waste_next_collection";
            state = ''
              {% set events = calendar_events['calendar.abfallwirtschaft_potsdam_mittelmark_apm'].events | default([]) %}
              {% if events | length > 0 %}
                {% set next_event = events | sort(attribute='start') | first %}
                {% set days = (strptime(next_event.start[:10], '%Y-%m-%d').date() - now().date()).days %}
                {% if days <= 0 %}Today{% elif days == 1 %}Tomorrow{% else %}In {{ days }} days{% endif %}: {{ next_event.summary }}
              {% else %}unknown{% endif %}
            '';
            icon = ''
              {% set events = calendar_events['calendar.abfallwirtschaft_potsdam_mittelmark_apm'].events | default([]) %}
              {% set message = (events | sort(attribute='start') | first).summary | lower if events | length > 0 else "" %}
              {% if 'grün' in message or 'bio' in message %}mdi:leaf
              {% elif 'gelb' in message %}mdi:recycle
              {% elif 'rest' in message or 'müll' in message %}mdi:trash-can
              {% elif 'papier' in message %}mdi:file-document
              {% elif 'schad' in message %}mdi:alert
              {% else %}mdi:calendar{% endif %}
            '';
            attributes = {
              days = ''
                {% set events = calendar_events['calendar.abfallwirtschaft_potsdam_mittelmark_apm'].events | default([]) %}
                {% if events | length > 0 %}
                  {{ (strptime((events | sort(attribute='start') | first).start[:10], '%Y-%m-%d').date() - now().date()).days }}
                {% endif %}
              '';
              date = ''
                {% set events = calendar_events['calendar.abfallwirtschaft_potsdam_mittelmark_apm'].events | default([]) %}
                {% if events | length > 0 %}{{ (events | sort(attribute='start') | first).start[:10] }}{% endif %}
              '';
              type = ''
                {% set events = calendar_events['calendar.abfallwirtschaft_potsdam_mittelmark_apm'].events | default([]) %}
                {% if events | length > 0 %}{{ (events | sort(attribute='start') | first).summary }}{% endif %}
              '';
            };
          }
          {
            name = "Dashboard Icon Battery SOC";
            unique_id = "dashboard_icon_battery_soc";
            state = "{{ states('sensor.evcc_battery_soc') }}";
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
            state = "{{ states('sensor.office_robot_vacuum_battery') }}";
            unit_of_measurement = "%";
            icon = ''
              {% set soc = states('sensor.office_robot_vacuum_battery') | int(0) %}
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
            state = "{{ states('sensor.evcc_carport_vehicle_soc') | int(0) }} → {{ states('sensor.evcc_carport_vehicle_limit_soc') | int(0) }}";
            icon = ''
              {% if is_state('binary_sensor.evcc_carport_connected', 'on') %}
                {% if is_state('binary_sensor.evcc_carport_charging', 'on') %}mdi:lightning-bolt
                {% else %}mdi:car-electric{% endif %}
              {% else %}mdi:car-off{% endif %}
            '';
            attributes = {
              is_charging = "{{ is_state('binary_sensor.evcc_carport_charging', 'on') }}";
              limit_soc = "{{ states('sensor.evcc_carport_vehicle_limit_soc') | int(0) }}";
            };
          }
        ];
      }
      {
        sensor = lib.mapAttrsToList mkLightsOn lightRooms ++ lib.mapAttrsToList mkShuttersOpen coverRooms;
      }
    ];
  };
}
