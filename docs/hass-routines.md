# Home Assistant Routines

> **Type:** Guide | **Created:** 2025-01

## Overview

A decoupled automation pattern for Home Assistant that separates **when** things happen (schedules/triggers) from **what** happens (device actions). Uses `local_calendar` for UI-managed schedules, `input_button` for event signaling, and **Nix-managed scenes** for device state definitions.

This is a **pattern guide**, not a module. All configuration is written directly in HA DSL via Nix.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  Trigger Sources                                    │
├─────────────────────────────────────────────────────┤
│ calendar.routines (UI-managed)                      │
│   "Evening" at 22:00                                │
│   "Night" at 23:30                                  │
│   "Late Night" at 00:00                             │
│   "Morning" at 06:45/08:30                          │
│                                                     │
│ sun.sun (built-in)                                  │
│   sunset event                                      │
│   sunrise event                                     │
└───────────────┬─────────────────────────────────────┘
                │ trigger
                ▼
┌─────────────────────────────────────────────────────┐
│  Bridge Automations                                 │
│  trigger source → input_button press                │
└───────────────┬─────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────┐
│  input_button.routine_*                             │
├─────────────────────────────────────────────────────┤
│ routine_evening                                     │
│ routine_night                                       │
│ routine_late_night                                  │
│ routine_morning                                     │
│ routine_sunset                                      │
│ routine_sunrise                                     │
└───────────────┬─────────────────────────────────────┘
                │ state change
                ▼
┌─────────────────────────────────────────────────────┐
│  Scene Automations                                  │
│  button press → scene.turn_on                       │
└───────────────┬─────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────┐
│  Scenes (Nix-managed)                               │
├─────────────────────────────────────────────────────┤
│ scene.routine_evening     → Close office, hallway,  │
│                             guest bath, utility     │
│ scene.routine_night       → Close living room,      │
│                             kitchen                 │
│ scene.routine_late_night  → Garden light off        │
│ scene.routine_morning     → Open all shutters       │
│ scene.routine_sunset      → Garden light on         │
└─────────────────────────────────────────────────────┘
```

## Design Principles

1. **Decoupled**: Schedules, events, and actions are independent layers
2. **UI-adjustable**: Change times via calendar
3. **Testable**: Press buttons manually to trigger routines
4. **Nix-managed**: Scenes define exact entity states, version-controlled
5. **Traceable**: Clear flow from trigger → button → scene
6. **Per-entity control**: Scenes allow different parameters per entity (brightness, position)

## Naming Conventions

### Two Dimensions of House State

| Dimension | Prefix | Helper Type | Trigger Source |
|-----------|--------|-------------|----------------|
| Routines (time/sun) | `routine_*` | `input_button` | Calendar, sun events |
| Home occupancy | `home_*` | `input_boolean` | Presence/manual (future) |

These are orthogonal - house can be in `routine_night` AND `home_away` simultaneously.

### Routine Buttons

| Button | Trigger | Purpose |
|--------|---------|---------|
| `routine_evening` | Calendar 22:00 | House winding down |
| `routine_night` | Calendar 23:30 | House in sleep mode |
| `routine_late_night` | Calendar 00:00 | Late night mode |
| `routine_morning` | Calendar 06:45/08:30 | House waking up |
| `routine_sunset` | Sun event | Sun has set |
| `routine_sunrise` | Sun event | Sun has risen |

### Scenes (Nix-Managed)

Scenes are defined in `modules/automation/home-assistant/automations.nix` and specify exact entity states:

| Scene | Entities | State |
|-------|----------|-------|
| `routine_evening` | Office shutters (2), Hallway, Guest Bath, Utility | Closed |
| `routine_night` | Living Room shutters (4), Kitchen | Closed |
| `routine_late_night` | Garden path light | Off |
| `routine_morning` | All shutters (10) | Open |
| `routine_sunset` | Garden path light | On |

### Future: Home Occupancy States

| State | Purpose |
|-------|---------|
| `home_away` | Everyone left temporarily |
| `home_vacation` | Extended absence |
| `home_guest` | Guests present |

## Device Naming Convention

In many integrations, the entity ID `domain.object_id` is generated from a combination of **Device Name + Entity (channel) Name**. To avoid redundant entity IDs, follow this pattern:

- **Device Name** = identity: `Area + Thing` (optionally + side/number)
- **Entity Name** = function: short, generic, channel-specific only

### Device Name

Use: `<Room/Area> <Load/Thing> [Qualifier]`

Examples:
- `Kitchen Ceiling Light`
- `Living Room Shutter Left`
- `Garden Path Light`
- `Office Window Sensor`
- `Hallway Motion`
- `Bedroom Climate`

**Rules:**
- Describes **where** and **what it's used for** (purpose, not just device type)
- Must be **unique per physical device** to avoid collision on shared sensors (temperature, RSSI, etc.)
- Avoid putting brand/model in the name unless truly needed

### Entity Name

Keep it minimal and do not repeat words already in the Device Name.

| Device Type | Entity Name |
|-------------|-------------|
| Single-channel relay | `Relay` |
| Cover (roller/shutter/blind) | `Cover` |
| Multi-channel devices | `Channel 1`, `Channel 2` or `Left`, `Right` |
| Window/Door contact | `Contact` |
| Motion sensor | `Trigger` |
| Climate sensors | `Temperature`, `Humidity` |
| Other sensors | `State` |

### Quick Templates

**Cover (shutter):**
- Device Name: `Living Room Shutter Left`
- Entity Name: `Cover`
- Result: `cover.living_room_shutter_left_cover`

**Relay controlling a light (shows as `switch.*`):**
- Device Name: `Garden Path Light`
- Entity Name: `Relay`
- Result: `switch.garden_path_light_relay`

**Window contact sensor:**
- Device Name: `Office Window Sensor`
- Entity Name: `Contact`
- Result: `binary_sensor.office_window_sensor_contact`

**Motion sensor:**
- Device Name: `Hallway Motion`
- Entity Name: `Trigger`
- Result: `binary_sensor.hallway_motion_trigger`

**Climate sensor:**
- Device Name: `Bedroom Climate`
- Entity Name: `Temperature` / `Humidity`
- Result: `sensor.bedroom_climate_temperature`, `sensor.bedroom_climate_humidity`

### One-Line Rule of Thumb

Put "where + what" in the Device Name; put only "what function/channel is this entity" in the Entity Name.

### Shelly MQTT Topic Prefix

For Shelly devices using MQTT, the topic prefix must match the full entity ID (slugified Device Name + Entity Name):

```
shellies/<device_name_slug>_<entity_name_slug>
```

Examples:
- `shellies/living_room_shutter_left_cover`
- `shellies/garden_path_light_relay`
- `shellies/hallway_motion_trigger`

## Implementation

### Module Structure

The Home Assistant module is split into separate files:

```
modules/automation/home-assistant/
├── default.nix      # Imports all submodules
├── options.nix      # Module options
├── service.nix      # Core HA service config (http, recorder, zones)
├── automations.nix  # Routine system (buttons, scenes, automations)
└── shelly.nix       # Shelly discovery system
```

### Scenes

Scenes are defined in `automations.nix`:

```nix
routineScenes = [
  {
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
  # ... more scenes
];
```

### Scene Automations

Each routine button triggers its corresponding scene:

```nix
routineEveningAutomation = {
  id = "routine_evening";
  alias = "Routine: Evening";
  triggers = [
    { trigger = "state"; entity_id = "input_button.routine_evening"; }
  ];
  actions = [
    { service = "scene.turn_on"; target.entity_id = "scene.routine_evening"; }
  ];
};
```

### Bridge Automations

Calendar events and sun events trigger button presses:

```nix
# Calendar → Button
{
  id = "routine_calendar_bridge";
  alias = "Routine: Calendar Bridge";
  mode = "queued";
  triggers = [
    { trigger = "calendar"; event = "start"; entity_id = "calendar.routines"; }
  ];
  actions = [
    {
      choose = [
        {
          conditions = "{{ trigger.calendar_event.summary == 'Evening' }}";
          sequence = [
            { service = "input_button.press"; target.entity_id = "input_button.routine_evening"; }
          ];
        }
        # ... more cases
      ];
    }
  ];
}

# Sun → Button
{
  id = "routine_sunset_bridge";
  alias = "Routine: Sunset Bridge";
  triggers = [
    { trigger = "sun"; event = "sunset"; offset = "00:00:00"; }
  ];
  actions = [
    { service = "input_button.press"; target.entity_id = "input_button.routine_sunset"; }
  ];
}
```

## Manual Setup (Post-Deploy)

### 1. Create Local Calendar

1. Settings → Devices & Services → Add Integration
2. Search "Local Calendar"
3. Name: "Routines" (creates `calendar.routines`)

### 2. Create Calendar Events

In HA Calendar dashboard (sidebar), create recurring events:

| Event Name | Time | Recurrence |
|------------|------|------------|
| Evening | 22:00 | Daily |
| Night | 23:30 | Daily |
| Late Night | 00:00 | Daily |
| Morning | 06:45 | Mon-Fri |
| Morning | 08:30 | Sat-Sun |

**Important**: Event names must match exactly (case-sensitive) for bridge automation to work.

#### Calendar Event Details

**Evening** (22:00 Daily)
```
Name: Evening
Description: Wind down. Close office, hallway, guest bath, utility shutters.
Start: 22:00
End: 22:01
Recurrence: Daily
```

**Night** (23:30 Daily)
```
Name: Night
Description: Bedtime. Close living room and kitchen shutters.
Start: 23:30
End: 23:31
Recurrence: Daily
```

**Late Night** (00:00 Daily)
```
Name: Late Night
Description: Late night mode. Turn off outdoor lights.
Start: 00:00
End: 00:01
Recurrence: Daily
```

**Morning Weekday** (06:45 Mon-Fri)
```
Name: Morning
Description: Good morning! Open all shutters.
Start: 06:45
End: 06:46
Recurrence: Weekly on Monday, Tuesday, Wednesday, Thursday, Friday
```

**Morning Weekend** (08:30 Sat-Sun)
```
Name: Morning
Description: Good morning! Open all shutters.
Start: 08:30
End: 08:31
Recurrence: Weekly on Saturday, Sunday
```

## Adding New Devices to Routines

1. Edit `modules/automation/home-assistant/automations.nix`
2. Add entity to appropriate scene(s)
3. Deploy

Example - adding a new shutter to evening routine:

```nix
{
  name = "Routine: Evening";
  entities = {
    # ... existing entities ...
    "cover.new_shutter_cover".state = "closed";  # Add new entity
  };
}
```

## Adding New Routines

1. Add new `input_button` in `automations.nix`
2. Add new scene with entity states
3. Add scene automation (button → scene)
4. Add case to calendar bridge (if calendar-triggered)
5. Deploy
6. If calendar-triggered: create calendar event in HA UI

## Future Extensions

### Combining with Occupancy

```nix
routineEveningAutomation = {
  id = "routine_evening";
  alias = "Routine: Evening";
  triggers = [
    { trigger = "state"; entity_id = "input_button.routine_evening"; }
  ];
  conditions = [
    { condition = "state"; entity_id = "input_boolean.home_away"; state = "off"; }
  ];
  actions = [
    { service = "scene.turn_on"; target.entity_id = "scene.routine_evening"; }
  ];
};
```

### Sun Offsets

```nix
{
  trigger = "sun";
  event = "sunset";
  offset = "-00:30:00";  # 30 minutes before sunset
}
```

### Per-Entity Parameters

Scenes support per-entity parameters like brightness and position:

```nix
{
  name = "Routine: Evening";
  entities = {
    "cover.office_shutter_cover" = {
      state = "open";
      position = 50;  # Half-closed
    };
    "light.living_room" = {
      state = "on";
      brightness = 77;  # Dimmed
    };
  };
}
```

## Backup

Calendar events are stored in `.storage/` which is backed up by restic (see `ha.md`).

## References

- [Local Calendar Integration](https://www.home-assistant.io/integrations/local_calendar/)
- [Calendar Automations](https://www.home-assistant.io/integrations/calendar/#automation)
- [Input Button](https://www.home-assistant.io/integrations/input_button/)
- [Sun Integration](https://www.home-assistant.io/integrations/sun/)
- [Scenes](https://www.home-assistant.io/integrations/scene/)
- Related: `ha.md`
