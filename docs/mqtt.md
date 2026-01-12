# MQTT Broker

> **Type:** PRD | **Created:** 2025-01

## Overview

Mosquitto MQTT broker with Dynamic Security plugin for authenticated device communication. All clients authenticate via the Dynamic Security plugin on port 8883 with TLS.

## VM Configuration

| Setting | Value |
|---------|-------|
| Hostname | `mqtt-01` |
| VM ID | 281 |
| VLAN | VM VLAN |
| Direct access | `mqtt-01.vm.mares.id:8883` |
| TLS | ACME certificate via Let's Encrypt |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        mqtt-01                              │
│                    VM VLAN: 10.10.22.x                      │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                    Mosquitto                         │   │
│  │                                                      │   │
│  │  Port: 8883 (TLS + Dynamic Security)                │   │
│  │  Bind: <nodeCfg.host> (specific IP)                 │   │
│  │  Cert: /var/lib/acme/mqtt-01.vm.mares.id/*.pem     │   │
│  │                                                      │   │
│  │  Auth: Dynamic Security Plugin                      │   │
│  │  Config: /var/lib/mosquitto/dynamic-security.json   │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
         ▲              ▲                ▲
         │              │                │
    ┌────┴────┐   ┌────┴────┐     ┌─────┴─────┐
    │ Shelly  │   │  ha-01  │     │  Meross   │
    │ Devices │   │         │     │  Devices  │
    └─────────┘   └─────────┘     └───────────┘
```

### Why Dynamic Security Plugin?

Originally we used file-based password auth, but Meross devices use MAC addresses (with colons) as usernames. Mosquitto's password file uses `:` as delimiter, breaking authentication for usernames like `48:e1:e9:33:89:a5`. The Dynamic Security Plugin uses JSON storage, solving this issue.

## Role & Group Structure

### Roles (ACL Definitions)

| Role | Topics | Purpose |
|------|--------|---------|
| `hass-access` | `#` (all) | Full access for Home Assistant |
| `shelly-access` | `shellies/#`, `shelly/#`, `shellies_discovery/#` | Shelly device topics |
| `meross-access` | `/appliance/#` | Meross device topics |

### Groups

| Group | Role | Purpose |
|-------|------|---------|
| `admins` | `hass-access` | Administrative clients |
| `shelly-devices` | `shelly-access` | Shelly IoT devices |
| `meross-devices` | `meross-access` | Meross smart plugs/strips |

### Clients

| Client | Group | Notes |
|--------|-------|-------|
| `admin` | (built-in) | Dynamic Security admin, created during init |
| `hass` | `admins` | Home Assistant |
| `shelly` | `shelly-devices` | Shared credentials for all Shelly devices |
| `<mac-address>` | `meross-devices` | One client per Meross device (MAC as username) |

## Management Commands

The `mctl` wrapper automatically includes connection parameters:

```bash
# List all
mctl dynsec listRoles
mctl dynsec listGroups
mctl dynsec listClients

# Get details
mctl dynsec getRole <role-name>
mctl dynsec getGroup <group-name>
mctl dynsec getClient <client-name>

# Create role with ACLs
mctl dynsec createRole <role-name>
mctl dynsec addRoleACL <role-name> publishClientSend '<topic>' allow
mctl dynsec addRoleACL <role-name> publishClientReceive '<topic>' allow
mctl dynsec addRoleACL <role-name> subscribePattern '<topic>' allow

# Create group and assign role
mctl dynsec createGroup <group-name>
mctl dynsec addGroupRole <group-name> <role-name>

# Create client and add to group
mctl dynsec createClient <client-name>
mctl dynsec setClientPassword <client-name> '<password>'
mctl dynsec addGroupClient <group-name> <client-name>

# Remove/delete
mctl dynsec removeGroupClient <group-name> <client-name>
mctl dynsec deleteClient <client-name>
mctl dynsec deleteGroup <group-name>
mctl dynsec deleteRole <role-name>
```

## Initial Setup

### 1. Initialize Dynamic Security

On first deployment, initialize the Dynamic Security plugin:

```bash
sudo -u mosquitto mosquitto_ctrl dynsec init /var/lib/mosquitto/dynamic-security.json admin
```

This creates the `admin` user (prompts for password) and the JSON config file.

### 2. Create Roles

```bash
mctl dynsec createRole hass-access
mctl dynsec addRoleACL hass-access publishClientSend '#' allow
mctl dynsec addRoleACL hass-access publishClientReceive '#' allow
mctl dynsec addRoleACL hass-access subscribePattern '#' allow

mctl dynsec createRole shelly-access
mctl dynsec addRoleACL shelly-access publishClientSend 'shellies/#' allow
mctl dynsec addRoleACL shelly-access publishClientReceive 'shellies/#' allow
mctl dynsec addRoleACL shelly-access subscribePattern 'shellies/#' allow
mctl dynsec addRoleACL shelly-access publishClientSend 'shelly/#' allow
mctl dynsec addRoleACL shelly-access publishClientReceive 'shelly/#' allow
mctl dynsec addRoleACL shelly-access subscribePattern 'shelly/#' allow
mctl dynsec addRoleACL shelly-access publishClientSend 'shellies_discovery/#' allow
mctl dynsec addRoleACL shelly-access publishClientReceive 'shellies_discovery/#' allow
mctl dynsec addRoleACL shelly-access subscribePattern 'shellies_discovery/#' allow

mctl dynsec createRole meross-access
mctl dynsec addRoleACL meross-access publishClientSend '/appliance/#' allow
mctl dynsec addRoleACL meross-access publishClientReceive '/appliance/#' allow
mctl dynsec addRoleACL meross-access subscribePattern '/appliance/#' allow
```

### 3. Create Groups

```bash
mctl dynsec createGroup admins
mctl dynsec addGroupRole admins hass-access

mctl dynsec createGroup shelly-devices
mctl dynsec addGroupRole shelly-devices shelly-access

mctl dynsec createGroup meross-devices
mctl dynsec addGroupRole meross-devices meross-access
```

### 4. Create Clients

```bash
# Home Assistant
mctl dynsec createClient hass
mctl dynsec addGroupClient admins hass

# Shelly (shared for all Shelly devices)
mctl dynsec createClient shelly
mctl dynsec addGroupClient shelly-devices shelly
```

For Meross devices, see `guide-meross-lan.md`.

## Adding a New Device Type

### 1. Create a Role
```bash
mctl dynsec createRole <device>-access
mctl dynsec addRoleACL <device>-access publishClientSend '<topic-pattern>' allow
mctl dynsec addRoleACL <device>-access publishClientReceive '<topic-pattern>' allow
mctl dynsec addRoleACL <device>-access subscribePattern '<topic-pattern>' allow
```

### 2. Create a Group
```bash
mctl dynsec createGroup <device>-devices
mctl dynsec addGroupRole <device>-devices <device>-access
```

### 3. Create Client(s)
```bash
mctl dynsec createClient <client-id>
mctl dynsec setClientPassword <client-id> '<password>'
mctl dynsec addGroupClient <device>-devices <client-id>
```

## Troubleshooting

### Check Connections
```bash
journalctl -u mosquitto -f
```

### Subscribe to All Topics (as admin)
```bash
mosquitto_sub -h mqtt-01.vm.mares.id -p 8883 \
  --cafile /etc/ssl/certs/ca-certificates.crt \
  -u admin -P '<password>' -t '#' -v
```

### Verify Client Authentication
```bash
mctl dynsec getClient '<client-name>'
```

### Check if Client is in Group
The `getClient` output shows group membership. If empty, add to group:
```bash
mctl dynsec addGroupClient <group-name> <client-name>
```

## Module Structure

```
modules/automation/mosquitto/
  ├── default.nix   # Imports
  ├── options.nix   # Interface (mares.automation.mosquitto.*)
  └── service.nix   # Implementation
```

## Secrets

| Vault | Secret | Purpose |
|-------|--------|---------|
| `easydns` | ACME DNS credentials | Certificate provisioning |

Note: MQTT user passwords are managed in Dynamic Security JSON, not sops.

## Shelly Device Configuration

Configure each Shelly device via its web UI (`http://<shelly-ip>`):

**Gen2 (Plus/Pro devices):**
1. Settings -> MQTT
2. Enable MQTT
3. Server: `mqtt-01.vm.mares.id`
4. Port: `8883`
5. SSL/TLS: Enable
6. Username: `shelly`
7. Password: (from Dynamic Security)
8. Save & Reboot

**Gen1 (older devices):**
1. Internet & Security -> Advanced - Developer Settings
2. Enable MQTT
3. Server: `mqtt-01.vm.mares.id:8883`
4. User: `shelly`
5. Password: (from Dynamic Security)
6. Enable TLS
7. Save
