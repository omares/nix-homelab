# Routine System (see docs/prd-hass-routines.md)
#
# Architecture:
#   Trigger (sun/calendar) → input_button → scene automation → scene
#
# Scenes are Nix-managed, defining exact entity states for each routine.
# Scenes are written to scenes.yaml for compatibility with HA scene editor.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mares.home-assistant;
  format = pkgs.formats.yaml { };

  # ==========================================================================
  # Input Buttons
  # ==========================================================================

  routineInputButtons = {
    routine_evening = {
      name = "Routine: Evening";
      icon = "mdi:weather-sunset-down";
    };
    routine_night = {
      name = "Routine: Night";
      icon = "mdi:weather-night";
    };
    routine_late_night = {
      name = "Routine: Late Night";
      icon = "mdi:weather-night-partly-cloudy";
    };
    routine_morning = {
      name = "Routine: Morning";
      icon = "mdi:weather-sunny";
    };
    routine_sunset = {
      name = "Routine: Sunset";
      icon = "mdi:weather-sunset";
    };
    routine_sunrise = {
      name = "Routine: Sunrise";
      icon = "mdi:weather-sunset-up";
    };
  };

  # ==========================================================================
  # Scenes
  # ==========================================================================

  # Scenes with unique IDs (required for HA scene editor compatibility)
  routineScenes = [
    {
      id = "routine_evening";
      name = "Routine: Evening";
      icon = "mdi:weather-sunset-down";
      entities = {
        "cover.office_shutter_cover".state = "closed";
        "cover.office_shutter_fixed_cover".state = "closed";
        "cover.hallway_shutter_cover".state = "closed";
        "cover.guest_bathroom_shutter_cover".state = "closed";
        "cover.utility_room_shutter_cover".state = "closed";
      };
    }
    {
      id = "routine_night";
      name = "Routine: Night";
      icon = "mdi:weather-night";
      entities = {
        "cover.living_room_shutter_left_cover".state = "closed";
        "cover.living_room_shutter_right_cover".state = "closed";
        "cover.living_room_shutter_terrace_door_cover".state = "closed";
        "cover.living_room_shutter_terrace_window_cover".state = "closed";
        "cover.kitchen_shutter_cover".state = "closed";
      };
    }
    {
      id = "routine_late_night";
      name = "Routine: Late Night";
      icon = "mdi:weather-night-partly-cloudy";
      entities = {
        "switch.carport_garden_path_light_relay".state = "off";
      };
    }
    {
      id = "routine_morning";
      name = "Routine: Morning";
      icon = "mdi:weather-sunny";
      entities = {
        "cover.guest_bathroom_shutter_cover".state = "open";
        "cover.hallway_shutter_cover".state = "open";
        "cover.kitchen_shutter_cover".state = "open";
        "cover.living_room_shutter_left_cover".state = "open";
        "cover.living_room_shutter_right_cover".state = "open";
        "cover.living_room_shutter_terrace_door_cover".state = "open";
        "cover.living_room_shutter_terrace_window_cover".state = "open";
        "cover.office_shutter_fixed_cover".state = "open";
        "cover.office_shutter_cover".state = "open";
        "cover.utility_room_shutter_cover".state = "open";
      };
    }
    {
      id = "routine_sunset";
      name = "Routine: Sunset";
      icon = "mdi:weather-sunset";
      entities = {
        "switch.carport_garden_path_light_relay".state = "on";
      };
    }
  ];

  # Generate scenes.yaml file
  scenesYaml = format.generate "scenes.yaml" routineScenes;

  # ==========================================================================
  # Bridge Automations (Triggers → Input Buttons)
  # ==========================================================================

  # Calendar events → input_button presses
  routineCalendarBridgeAutomation = {
    id = "routine_calendar_bridge";
    alias = "Routine: Calendar Bridge";
    mode = "queued";
    triggers = [
      {
        trigger = "calendar";
        event = "start";
        entity_id = "calendar.routines";
      }
    ];
    actions = [
      {
        choose = [
          {
            conditions = "{{ trigger.calendar_event.summary == 'Evening' }}";
            sequence = [
              {
                service = "input_button.press";
                target.entity_id = "input_button.routine_evening";
              }
            ];
          }
          {
            conditions = "{{ trigger.calendar_event.summary == 'Night' }}";
            sequence = [
              {
                service = "input_button.press";
                target.entity_id = "input_button.routine_night";
              }
            ];
          }
          {
            conditions = "{{ trigger.calendar_event.summary == 'Late Night' }}";
            sequence = [
              {
                service = "input_button.press";
                target.entity_id = "input_button.routine_late_night";
              }
            ];
          }
          {
            conditions = "{{ trigger.calendar_event.summary == 'Morning' }}";
            sequence = [
              {
                service = "input_button.press";
                target.entity_id = "input_button.routine_morning";
              }
            ];
          }
        ];
      }
    ];
  };

  # Sunset → input_button press
  routineSunsetBridgeAutomation = {
    id = "routine_sunset_bridge";
    alias = "Routine: Sunset Bridge";
    triggers = [
      {
        trigger = "sun";
        event = "sunset";
        offset = "00:00:00";
      }
    ];
    actions = [
      {
        service = "input_button.press";
        target.entity_id = "input_button.routine_sunset";
      }
    ];
  };

  # Sunrise → input_button press
  routineSunriseBridgeAutomation = {
    id = "routine_sunrise_bridge";
    alias = "Routine: Sunrise Bridge";
    triggers = [
      {
        trigger = "sun";
        event = "sunrise";
        offset = "00:00:00";
      }
    ];
    actions = [
      {
        service = "input_button.press";
        target.entity_id = "input_button.routine_sunrise";
      }
    ];
  };

  # ==========================================================================
  # Scene Automations (Input Buttons → Scenes)
  # ==========================================================================

  routineEveningAutomation = {
    id = "routine_evening";
    alias = "Routine: Evening";
    triggers = [
      {
        trigger = "state";
        entity_id = "input_button.routine_evening";
      }
    ];
    actions = [
      {
        service = "scene.turn_on";
        target.entity_id = "scene.routine_evening";
      }
    ];
  };

  routineNightAutomation = {
    id = "routine_night";
    alias = "Routine: Night";
    triggers = [
      {
        trigger = "state";
        entity_id = "input_button.routine_night";
      }
    ];
    actions = [
      {
        service = "scene.turn_on";
        target.entity_id = "scene.routine_night";
      }
    ];
  };

  routineLateNightAutomation = {
    id = "routine_late_night";
    alias = "Routine: Late Night";
    triggers = [
      {
        trigger = "state";
        entity_id = "input_button.routine_late_night";
      }
    ];
    actions = [
      {
        service = "scene.turn_on";
        target.entity_id = "scene.routine_late_night";
      }
    ];
  };

  routineMorningAutomation = {
    id = "routine_morning";
    alias = "Routine: Morning";
    triggers = [
      {
        trigger = "state";
        entity_id = "input_button.routine_morning";
      }
    ];
    actions = [
      {
        service = "scene.turn_on";
        target.entity_id = "scene.routine_morning";
      }
    ];
  };

  routineSunsetAutomation = {
    id = "routine_sunset";
    alias = "Routine: Sunset";
    triggers = [
      {
        trigger = "state";
        entity_id = "input_button.routine_sunset";
      }
    ];
    actions = [
      {
        service = "scene.turn_on";
        target.entity_id = "scene.routine_sunset";
      }
    ];
  };
in
{
  config = lib.mkIf cfg.enable {
    services.home-assistant.config = {
      input_button = routineInputButtons;

      # Use !include to reference scenes.yaml (deployed via preStart)
      scene = "!include scenes.yaml";

      automation = [
        # Bridge automations
        routineCalendarBridgeAutomation
        routineSunsetBridgeAutomation
        routineSunriseBridgeAutomation
        # Scene automations
        routineEveningAutomation
        routineNightAutomation
        routineLateNightAutomation
        routineMorningAutomation
        routineSunsetAutomation
      ];
    };

    # Deploy scenes.yaml to Home Assistant config directory
    systemd.services.home-assistant.preStart = lib.mkAfter ''
      ln -fns ${scenesYaml} "${cfg.configDir}/scenes.yaml"
    '';
  };
}
