# Home Assistant

> **Type:** PRD | **Created:** 2025-01

## Overview

Home Assistant deployment for local smart home automation. First-time HA setup with focus on local control, MQTT-based device communication, and integration with existing monitoring infrastructure.

## VM Configuration

| Setting | Value |
|---------|-------|
| Hostname | `ha-01` |
| VM ID | 282 |
| VLAN | VM VLAN |
| Proxy | `ha.mares.id` via nginx |
| Direct access | `http://ha-01.vm.mares.id:8123` |
| External access | VPN only (not internet-accessible) |

## Core Configuration

| Setting | Value |
|---------|-------|
| Timezone | `Europe/Berlin` (hardcoded) |
| Location | Latitude/longitude from sops secrets |
| Country | Germany |

## Database Architecture (Three-Tier)

### PostgreSQL - Short-term Recorder
| Setting | Value |
|---------|-------|
| Purpose | UI state, Logbook, Energy Dashboard |
| Host | `db-01.vm.mares.id` via PgBouncer |
| Port | 6432 |
| Database | `hass` |
| User | `hass` |
| Pool mode | `transaction` |
| Retention | 14 days |

### InfluxDB - Long-term History
| Setting | Value |
|---------|-------|
| Purpose | Long-term sensor history |
| Host | `mon-01.vm.mares.id` |
| Port | 8086 |
| Organization | `mares` |
| Bucket | `home-assistant` |
| Retention | 365 days |

### Prometheus - Service Metrics
| Setting | Value |
|---------|-------|
| Purpose | HA service health metrics |
| Transport | Alloy push to mon-01 |
| Endpoint | `/api/prometheus` (Bearer auth) |
| Retention | 30 days |

## Integrations

### Extra Components

```nix
extraComponents = [
  "default_config"    # Includes sun, group, switch_as_x, and many others
  "isal"              # Faster compression
  "mqtt"              # MQTT broker integration
  "open_meteo"        # Weather data
  "dwd_weather_warnings"  # German weather warnings
  "mobile_app"        # Mobile push notifications
  "prometheus"        # Metrics endpoint
  "influxdb"          # Long-term history export
];
```

### What's Included in `default_config`

No need to explicitly add:
- `sun` - sunrise/sunset triggers
- `group` - entity grouping
- `switch_as_x` - convert switches to lights/fans/etc.
- Many other common integrations

### Recorder Configuration

```nix
config.recorder = {
  db_url = "!secret recorder_db_url";
  purge_keep_days = 14;
  commit_interval = 1;
  exclude = {
    domains = [ "automation" "updater" ];
  };
};
```

## MQTT / Shelly Integration

### Goal
Local control of Shelly devices via MQTT. No cloud dependency.

### MQTT Broker
Uses `mqtt-01` (see `mqtt.md`):
- Host: `mqtt-01.vm.mares.id`
- Port: 8883 (TLS)

### MQTT Users
| User | Purpose | ACL |
|------|---------|-----|
| `hass` | HA ↔ MQTT | `readwrite #` |
| `shelly` | Shelly devices | `readwrite shellies/#, shelly/#` |

### Shelly Device Setup
1. Enable MQTT in Shelly device settings (via local web UI)
2. Point to `mqtt-01.vm.mares.id:8883`
3. Use `shelly` user credentials
4. Disable Shelly cloud access
5. HA auto-discovers devices via MQTT

### Shelly Device Types
| Device | Generation | MQTT Topics |
|--------|------------|-------------|
| Plus 1PM, Plus 2PM | Gen2 | `<device-id>/...` |
| Flood, H&T | Gen1 | `shellies/<device-id>/...` |

### Firmware Updates
Since cloud is disabled, firmware updates must be done manually via:
- Shelly local web UI (`http://<shelly-ip>`)
- HA can show update availability but cannot push updates

## Users & Authentication

### User Strategy
| User | Type | Purpose |
|------|------|---------|
| Owner (your name) | Owner/Admin | Created during onboarding, daily use |
| `service` | Regular user | Owns API tokens (Alloy, future integrations) |
| Family members | Regular users | Added later as needed |

### Long-lived Access Tokens
- Created on `service` user profile
- Used for:
  - Alloy Prometheus scraping
  - Future external integrations
- Tokens are valid for 10 years
- Independent of password changes

### Onboarding Flow (Manual, Post-Deploy)
1. Navigate to `http://ha-01.vm.mares.id:8123`
2. Create owner account (your personal account)
3. Complete location setup (pre-filled from secrets, but UI confirms)
4. Create `service` user via Settings → People → Users
5. Generate long-lived access token on `service` user profile
6. Add token to sops vault as `home-assistant-token`

## Monitoring Integration

### Alloy Configuration

The HA module uses the Alloy `extraConfig` hook to add an authenticated scrape:

```
prometheus.scrape "homeassistant" {
  targets = [{"__address__" = "localhost:8123"}]
  forward_to = [prometheus.remote_write.default.receiver]
  scrape_interval = "60s"
  metrics_path = "/api/prometheus"
  
  authorization {
    type = "Bearer"
    credentials_file = "/run/secrets/home-assistant-token"
  }
}
```

### Required Alloy Module Enhancement

Add `extraConfig` option to `modules/monitoring/alloy.nix`:

```nix
extraConfig = lib.mkOption {
  type = lib.types.lines;
  default = "";
  description = "Additional Alloy configuration blocks contributed by other modules";
};
```

## Backup

Uses Restic (see `restic.md`):

| Setting | Value |
|---------|-------|
| Paths | `/var/lib/hass/.storage` |
| User | `hass` |
| Repository | `sftp:restic@truenas.srv.mares.id:/backups/hass` |
| Schedule | Daily at 03:00 |
| Retention | 7 daily, 4 weekly, 12 monthly, 2 yearly |

### What's Backed Up
- `.storage/` contains:
  - Entity registry
  - Device registry
  - Area definitions
  - Lovelace dashboard config
  - Integration configs
  - Automations (if created via UI)

### What's NOT Backed Up (Nix-managed)
- `configuration.yaml` (generated by Nix)
- `secrets.yaml` (generated by sops template)

## Automations

### Starter Automations (MVP)

#### Device Offline Alert
```yaml
automation:
  - alias: "Device Offline Alert"
    trigger:
      - platform: state
        entity_id: all
        to: "unavailable"
        for:
          minutes: 5
    condition:
      - condition: template
        value_template: "{{ trigger.from_state.state != 'unavailable' }}"
    action:
      - service: notify.mobile_app_<device>
        data:
          title: "Device Offline"
          message: "{{ trigger.to_state.attributes.friendly_name }} is unavailable"
```

Note: This is a template. Actual implementation will use a group or more specific entity selection.

### Future Automations (Post-MVP)
- Input helpers (`input_boolean.guest_mode`, `input_select.house_mode`, etc.)
- Template sensors (`binary_sensor.anyone_home`)
- Energy-based automations

## Entity Naming Convention

```
<domain>.<area>_<device>[_<measurement>]
```

| Rule | Example |
|------|---------|
| snake_case throughout | `sensor.kitchen_coffee_machine_power` |
| English only | `sensor.living_room_temperature` |
| No abbreviations | `sensor.bathroom_humidity` not `sensor.bath_hum` |
| Measurement optional | `switch.garage_door` or `sensor.garage_door_power` |

## Organization

### Areas
- Defined via UI (stored in `.storage/core.area_registry`)
- Cannot be Nix-managed
- Examples: Kitchen, Living Room, Garage, etc.

### Groups
- Can be Nix-defined for functional categories
- Example: `group.all_lights`, `group.security_sensors`
- Configured later as devices are added

## Energy Dashboard

### Preparation
No Nix config needed. After setup:
1. Navigate to Settings → Dashboards → Energy
2. Add Shelly PM sensors as energy sources
3. Configure grid consumption/production (for Fronius later)

### Future Additions
- Fronius solar inverter
- BMW iX energy consumption
- Grid import/export tracking

## Extensions (MVP Scope)

| Extension | MVP | Later | Notes |
|-----------|-----|-------|-------|
| Node-RED | No | Maybe | If native automations become limiting |
| HACS | No | Maybe | When custom integration needed |
| Custom cards | No | Maybe | Requires HACS |
| Lovelace (default) | Yes | - | UI mode initially |

## Module Structure

```
modules/home-assistant/
  ├── default.nix     # Imports
  ├── options.nix     # Interface (mares.home-assistant.*)
  └── service.nix     # Implementation
```

## Secrets

### Vault: `home-assistant`
| Secret | Purpose |
|--------|---------|
| `home-assistant-latitude` | Home location |
| `home-assistant-longitude` | Home location |
| `home-assistant-token` | Long-lived access token (for Alloy) |

### Other Vaults
| Vault | Secret | Purpose |
|-------|--------|---------|
| `mqtt` | `mqtt-hass_password` | HA → MQTT broker |
| `pgsql` | `pgsql-hass_password` | HA → PostgreSQL |
| `influxdb` | `influxdb-hass_token` | HA → InfluxDB |
| `restic` | `restic-hass_password` | Backup encryption |

### secrets.yaml Template

sops-nix template generates HA's `secrets.yaml`:

```nix
sops.templates."ha-secrets.yaml" = {
  content = ''
    # Home Assistant secrets - managed by sops-nix
    latitude: ${config.sops.placeholder."home-assistant-latitude"}
    longitude: ${config.sops.placeholder."home-assistant-longitude"}
    
    # Database connections
    recorder_db_url: "postgresql://hass:${config.sops.placeholder."pgsql-hass_password"}@db-01.vm.mares.id:6432/hass"
    
    # MQTT
    mqtt_password: ${config.sops.placeholder."mqtt-hass_password"}
    
    # InfluxDB
    influxdb_token: ${config.sops.placeholder."influxdb-hass_token"}
  '';
  path = "/var/lib/hass/secrets.yaml";
  owner = "hass";
  group = "hass";
  mode = "0400";
};
```

## Naming Conventions

| Context | Convention | Example |
|---------|------------|---------|
| Short form | `hass` | DB user, MQTT user, secrets |
| Long form | `home-assistant` | Hostname, module, vault |
| Entities | snake_case | `sensor.kitchen_temperature` |

## Proxy Configuration

nginx proxy on proxy VM:

```nix
services.nginx.virtualHosts."ha.mares.id" = {
  forceSSL = true;
  useACMEHost = "mares.id";
  locations."/" = {
    proxyPass = "http://ha-01.vm.mares.id:8123";
    proxyWebsockets = true;
  };
};
```

### HA HTTP Configuration

```nix
config.http = {
  use_x_forwarded_for = true;
  trusted_proxies = [ "proxy-01.vm.mares.id" ];
};
```

## PostgreSQL Setup

Add to `roles/postgres.nix`:

```nix
databases = {
  # ... existing ...
  hass = { };
};

users = {
  # ... existing ...
  hass = {
    ensureDBOwnership = true;
    createdb = false;
    databases = [ "hass" ];
  };
};
```

## Dependencies

| Dependency | Required For | PRD |
|------------|--------------|-----|
| mqtt-01 | MQTT broker | `mqtt.md` |
| mon-01 + InfluxDB | Long-term history | `influxdb.md` |
| db-01 | PostgreSQL recorder | Existing |
| Restic | Backups | `restic.md` |

## Deployment Order

1. Ensure mqtt-01 is deployed and running
2. Ensure InfluxDB is added to mon-01
3. Add `hass` user/db to PostgreSQL
4. Deploy ha-01
5. Complete onboarding via UI
6. Create `service` user and generate token
7. Update sops with token, redeploy for Alloy integration

## Open Questions

None - ready for implementation.

## References

- [Home Assistant Documentation](https://www.home-assistant.io/docs/)
- [NixOS Home Assistant Module](https://search.nixos.org/options?query=services.home-assistant)
- [Shelly MQTT API](https://shelly-api-docs.shelly.cloud/gen2/ComponentsAndServices/Mqtt)
- [HA Recorder](https://www.home-assistant.io/integrations/recorder/)
- [HA InfluxDB](https://www.home-assistant.io/integrations/influxdb/)
