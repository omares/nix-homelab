# evcc Integration

> **Type:** PRD | **Created:** 2025-01

## Overview
Integration of [evcc](https://evcc.io/) into the NixOS Proxmox environment to manage EV charging using PV excess and dynamic electricity pricing.

## Goals
- **Automated Charging**: Optimize EV charging based on solar production (Fronius) and dynamic prices (Ostrom).
- **Hardware Integration**: Connect BMW car, Fronius Inverter/Smart Meter/Wattpilot, and Varta Battery.
- **Local Control**: Prioritize local communication (Modbus/TCP, local API) where possible.
- **Visibility**: Report all data to Home Assistant via MQTT.
- **Declarative Setup**: Fully managed via NixOS modules and roles.

## Architecture
- **Node**: `evcc-01` (New NixOS VM on Proxmox).
- **VLAN**: `vm` (10.10.22.x range).
- **Persistence**: SQLite database stored in `/var/lib/evcc`.
- **Secrets**: Managed via `sops-nix` / `sops-vault`.
- **Messaging**: Integration with existing Mosquitto broker (`mqtt-01`).
- **Database**: While `evcc` uses SQLite for internal state, historical data can be sent to Home Assistant (Postgres backend) via MQTT.

## Functional Requirements

### 1. Hardware & Service Integration
| Component | Device | Method | Connectivity |
|-----------|--------|--------|--------------|
| **Vehicle** | BMW | BMW ConnectedDrive | Cloud API |
| **PV / Grid** | Fronius Gen24 + Smart Meter | Fronius Solar API / Modbus | Local |
| **Charger** | Fronius Wattpilot | Wattpilot API | Local |
| **Storage** | Varta Battery | Modbus/TCP | Local |
| **Pricing** | Ostrom | Ostrom API | Cloud API |

### 2. Monitoring & Control
- **Home Assistant**: Full status monitoring and charge mode control via MQTT.
- **Web UI**: `evcc` dashboard accessible via reverse proxy (`evcc.mares.id`).

## MQTT Configuration (on mqtt-01)
To allow `evcc` to communicate with the broker, run the following commands on `mqtt-01`:

```bash
# 1. Create Role with ACLs
mctl dynsec createRole evcc-access
mctl dynsec addRoleACL evcc-access publishClientSend 'evcc/#' allow
mctl dynsec addRoleACL evcc-access publishClientReceive 'evcc/#' allow
mctl dynsec addRoleACL evcc-access subscribePattern 'evcc/#' allow

# 2. Create Group and assign Role
mctl dynsec createGroup evcc-devices
mctl dynsec addGroupRole evcc-devices evcc-access

# 3. Create Client and add to Group
mctl dynsec createClient evcc
mctl dynsec setClientPassword evcc '<password-from-sops>'
mctl dynsec addGroupClient evcc-devices evcc
```

## Technical Specification

### 1. NixOS Module (`modules/services/evcc`)
- Wrapper for `services.evcc`.
- Support for `LoadCredential` to securely inject secrets (BMW credentials, Ostrom tokens).
- Configuration generated from Nix attrsets.

### 2. NixOS Role (`roles/evcc.nix`)
- Site-specific configuration.
- Definition of meters, chargers, vehicles, and tariffs.
- MQTT connection settings for `mqtt-01.vm.mares.id`.

### 3. Networking
- **Port**: 7070 (Web UI).
- **Proxy**: Exposed via `proxy-01` with ACME certificates.

## Implementation Plan
1. **Research & Documentation**: (Current Step) Finalize PRD and technical plan.
2. **Secrets Setup**: Add required credentials to `sops`.
3. **Module Development**: Create `modules/services/evcc`.
4. **Role Creation**: Create `roles/evcc.nix` with site hardware config.
5. **Node Registration**: Add `evcc-01` to `modules/infrastructure/nodes.nix`.
6. **Deployment**: Initial build and deploy to Proxmox.
7. **HA Integration**: Configure MQTT discovery and dashboard in Home Assistant.

## Success Criteria
- [ ] `evcc` is running on `evcc-01`.
- [ ] Solar production and battery state are correctly displayed in `evcc`.
- [ ] BMW SoC is visible.
- [ ] Charging mode can be toggled from Home Assistant.
- [ ] Dynamic prices from Ostrom are used for charging logic.
