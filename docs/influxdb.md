# InfluxDB

> **Type:** PRD | **Created:** 2025-01

## Overview

Add InfluxDB 2.x to the existing monitoring stack on mon-01 to provide long-term time-series storage for Home Assistant sensor data. This complements the existing Prometheus (infrastructure metrics) and Loki (logs) setup.

## Goals

- Provide long-term (1 year) storage for Home Assistant sensor data
- Enable advanced time-series analysis via Grafana
- Follow existing mon-01 patterns and conventions
- Fully declarative provisioning (no manual setup)

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                              mon-01                                      │
│                                                                          │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐             │
│  │   Prometheus   │  │      Loki      │  │   InfluxDB 2   │  ◄── NEW   │
│  │   (infra)      │  │    (logs)      │  │  (HA sensors)  │             │
│  │   30d retain   │  │                │  │   365d retain  │             │
│  │   :9090        │  │   :3100        │  │   :8086        │             │
│  └───────▲────────┘  └───────▲────────┘  └───────▲────────┘             │
│          │                   │                   │                       │
│          │ Alloy push        │ Alloy push        │ HA push               │
│          │                   │                   │                       │
│  ┌───────┴───────────────────┴───────────────────┴────────────────┐     │
│  │                          Grafana                                │     │
│  │                    (unified dashboards)                         │     │
│  │  Datasources: prometheus-main, loki-main, influxdb-main        │     │
│  └─────────────────────────────────────────────────────────────────┘     │
│                                                                          │
│  Storage:                                                                │
│    /var/lib/prometheus2  - Prometheus data (existing disk)              │
│    /var/lib/influxdb2    - InfluxDB data (NEW dedicated disk)           │
└──────────────────────────────────────────────────────────────────────────┘
                                   ▲
                                   │ HTTP POST /api/v2/write
                                   │ (push from ha-01)
                              ┌────┴────┐
                              │  ha-01  │
                              │  Home   │
                              │Assistant│
                              └─────────┘
```

## Technical Specifications

### Service Configuration

| Setting | Value |
|---------|-------|
| Service | InfluxDB 2.x |
| Port | 8086 |
| Bind Address | mon-01's specific IP (from `nodeCfg.host`) |
| Data Directory | `/var/lib/influxdb2` |
| Storage | Dedicated disk (>20GB, user provisions) |

### Organization & Bucket

| Setting | Value |
|---------|-------|
| Organization | `mares` |
| Bucket | `home-assistant` |
| Retention | 31536000 seconds (365 days) |

### Authentication

| User/Token | Purpose | Permissions |
|------------|---------|-------------|
| `admin` | Admin user | Full access |
| `home-assistant` | HA write token | Read/Write to `home-assistant` bucket only |

### Firewall Rules

| Source | Destination | Port | Purpose |
|--------|-------------|------|---------|
| ha-01 | mon-01 | 8086/TCP | HA → InfluxDB writes |

## Implementation

### Files to Modify

#### 1. `modules/monitoring/influxdb.nix` (NEW)

```nix
{
  config,
  lib,
  nodeCfg,
  ...
}:
let
  cfg = config.mares.monitoring.influxdb;
in
{
  options.mares.monitoring.influxdb = {
    enable = lib.mkEnableOption "InfluxDB 2.x time-series database";
  };

  config = lib.mkIf cfg.enable {
    services.influxdb2 = {
      enable = true;

      settings = {
        "http-bind-address" = "${nodeCfg.host}:8086";
      };

      provision = {
        enable = true;

        initialSetup = {
          organization = "mares";
          bucket = "home-assistant";
          username = "admin";
          passwordFile = config.sops.secrets.influxdb-admin-password.path;
          tokenFile = config.sops.secrets.influxdb-admin-token.path;
          retention = 31536000; # 365 days in seconds
        };

        organizations.mares = {
          buckets.home-assistant = {
            retention = 31536000; # 365 days
          };

          auths.home-assistant = {
            description = "Home Assistant write token";
            tokenFile = config.sops.secrets.influxdb-home-assistant-token.path;
            writeBuckets = [ "home-assistant" ];
            readBuckets = [ "home-assistant" ];
          };
        };
      };
    };

    sops.secrets = {
      influxdb-admin-password = { };
      influxdb-admin-token = { };
      influxdb-home-assistant-token = { };
    };

    networking.firewall.allowedTCPPorts = [ 8086 ];
  };
}
```

#### 2. `modules/monitoring/default.nix`

Add import for the new influxdb module:

```nix
{
  imports = [
    ./options.nix
    ./alloy.nix
    ./grafana.nix
    ./loki.nix
    ./prometheus.nix
    ./influxdb.nix  # ADD THIS
  ];
}
```

#### 3. `modules/monitoring/grafana.nix`

Add InfluxDB datasource to the existing `datasources.settings.datasources` list:

```nix
# In services.grafana.provision.datasources.settings.datasources, add:
{
  name = "InfluxDB";
  type = "influxdb";
  uid = "influxdb-main";
  access = "proxy";
  url = "http://${nodeCfg.host}:8086";
  jsonData = {
    version = "Flux";
    organization = "mares";
    defaultBucket = "home-assistant";
  };
  secureJsonData = {
    token = "$__file{${config.sops.secrets.influxdb-home-assistant-token.path}}";
  };
}
```

**Note:** Grafana needs access to the InfluxDB token. Either:
- Use the same `home-assistant` token (read access is sufficient for Grafana)
- Create a separate read-only token for Grafana

For simplicity, reuse the `home-assistant` token since it has read access.

#### 4. `roles/monitoring-server.nix`

Add InfluxDB enablement and disk mount:

```nix
{
  config,
  ...
}:
{
  imports = [
    ../modules/monitoring
  ];

  sops-vault.items = [
    "grafana"
    "influxdb"  # ADD THIS
  ];

  # Existing Prometheus disk
  fileSystems."/var/lib/prometheus2" = {
    device = "/dev/disk/by-label/prometheus-data";
    autoResize = true;
    fsType = "ext4";
  };

  # ADD: InfluxDB dedicated disk
  fileSystems."/var/lib/influxdb2" = {
    device = "/dev/disk/by-label/influxdb-data";
    autoResize = true;
    fsType = "ext4";
  };

  mares.monitoring.prometheus.enable = true;
  mares.monitoring.loki.enable = true;
  mares.monitoring.influxdb.enable = true;  # ADD THIS

  mares.monitoring.grafana = {
    enable = true;
    adminPasswordFile = config.sops.secrets.grafana-password.path;
  };
}
```

### Secrets to Create

Create sops vault `influxdb` with the following secrets:

| Secret Name | Type | Description |
|-------------|------|-------------|
| `influxdb-admin-password` | string | Password for admin user |
| `influxdb-admin-token` | string | Admin API token (full access) |
| `influxdb-home-assistant-token` | string | Token for HA to read/write `home-assistant` bucket |

**Token Generation:**

Generate secure tokens before creating the vault:

```bash
# Generate random tokens (example)
openssl rand -hex 32  # For admin token
openssl rand -hex 32  # For home-assistant token
```

## Deployment Steps

### Pre-Deployment

1. **Add dedicated disk to mon-01 VM in Proxmox:**
   - Add new disk (>20GB recommended)
   - Format with ext4
   - Label as `influxdb-data`:
     ```bash
     mkfs.ext4 -L influxdb-data /dev/sdX
     ```

2. **Create sops vault `influxdb`** with required secrets

3. **Create the module files** as specified above

### Deployment

```bash
# Deploy mon-01 with InfluxDB
./bin/d .#mon-01
```

### Post-Deployment Verification

1. **Check service status:**
   ```bash
   ssh mon-01 systemctl status influxdb2
   ```

2. **Verify InfluxDB is listening:**
   ```bash
   ssh mon-01 ss -tlnp | grep 8086
   ```

3. **Test API access (from mon-01):**
   ```bash
   curl -s http://localhost:8086/health
   # Expected: {"status":"pass"}
   ```

4. **Verify Grafana datasource:**
   - Login to Grafana (grafana.mares.id)
   - Go to Configuration → Data Sources
   - Check "InfluxDB" datasource is listed and test connection

5. **Test write access (from ha-01 network):**
   ```bash
   # Replace TOKEN with influxdb-home-assistant-token value
   curl -X POST "http://mon-01.vm.mares.id:8086/api/v2/write?org=mares&bucket=home-assistant" \
     -H "Authorization: Token TOKEN" \
     -H "Content-Type: text/plain" \
     --data-raw "test,host=ha-01 value=1"
   ```

## Grafana Dashboard (Optional)

Consider adding an InfluxDB monitoring dashboard. Available options:

- InfluxDB 2.x dashboard (ID: 15650) - Monitor InfluxDB itself
- Custom Home Assistant sensor dashboards (create after HA is running)

This can be added later as a separate enhancement.

## Dependencies

| Dependency | Purpose |
|------------|---------|
| Existing mon-01 setup | Prometheus, Loki, Grafana already configured |
| `sops-vault` | Secrets management |
| Dedicated disk | Storage for InfluxDB data |

## Future Enhancements

- Add InfluxDB monitoring dashboard to Grafana
- Create Home Assistant sensor dashboards
- Consider backup strategy for InfluxDB data
- Evaluate retention policies per measurement type

## Out of Scope

- Home Assistant configuration (see `ha.md`)
- MQTT broker (see `mqtt.md`)
- InfluxDB clustering (single instance is sufficient)

## Open Items

- [ ] User to provision dedicated disk for mon-01 (>20GB, label: `influxdb-data`)
- [ ] User to create sops vault `influxdb` with secrets
- [ ] User to update Grafana module with InfluxDB datasource (or implement as separate PR)
