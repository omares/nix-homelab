# Zigbee2MQTT

> **Type:** PRD | **Created:** 2025-01

## Overview

Zigbee2MQTT bridges Zigbee devices to MQTT, enabling Home Assistant integration via MQTT discovery. Uses a Sonoff ZBDongle-E (Silicon Labs EFR32MG21) as the Zigbee coordinator with the `ember` adapter.

## VM Configuration

| Setting | Value |
|---------|-------|
| Hostname | `z2m-01` |
| VM ID | 283 |
| Proxmox Host | `pve-01` (USB dongle attached here) |
| VLAN | VM VLAN |
| Direct access | `z2m-01.vm.mares.id:8080` |
| Proxy access | `z2m.mares.id` (via nginx) |
| Frontend | zigbee2mqtt-windfront (new UI) |

## Architecture

```
                                    ┌─────────────────────────────────────┐
                                    │              z2m-01                  │
                                    │          VM VLAN: 10.10.22.x        │
                                    │                                      │
┌─────────────┐                     │  ┌────────────────────────────────┐ │
│   Zigbee    │  USB Passthrough    │  │         zigbee2mqtt            │ │
│  Devices    │◄────────────────────┼──┤                                │ │
│             │                     │  │  Adapter: ember (EFR32MG21)    │ │
│  - Sensors  │                     │  │  Channel: 20                   │ │
│  - Lights   │                     │  │  TX Power: 10 dBm              │ │
│  - Switches │                     │  │                                │ │
└─────────────┘                     │  │  Frontend: :8080 (windfront)   │ │
                                    │  └──────────────┬─────────────────┘ │
      ┌─────────────────────────────┼─────────────────┘                   │
      │                             └─────────────────────────────────────┘
      │ MQTTS (8883)
      ▼
┌─────────────┐         MQTT Discovery        ┌─────────────┐
│   mqtt-01   │◄─────────────────────────────►│   hass-01   │
│  Mosquitto  │     homeassistant/#           │ Home Assist │
└─────────────┘     zigbee2mqtt/#             └─────────────┘
```

## Hardware: Sonoff ZBDongle-E

| Specification | Value |
|---------------|-------|
| Chip | Silicon Labs EFR32MG21 |
| Adapter type | `ember` (NOT `zstack` or `ezsp`) |
| Firmware | EmberZNet 8.0.3.0 (EZSP v13) |
| Flow control | Software only (`rtscts: false`) |
| Baudrate | 115200 |
| USB ID | `/dev/serial/by-id/usb-SONOFF_Zigbee_3.0_USB_Dongle_Plus_V2_*` |

### Firmware Upgrade

The dongle ships with older firmware (EZSP v6). Upgrade required for `ember` adapter:

1. Open [Silabs Firmware Flasher](https://darkxst.github.io/silabs-firmware-builder/)
2. Connect dongle via USB
3. Flash NCP firmware 7.4.4+ or 8.0.x
4. Verify: EZSP version 13

## Zigbee Network Configuration

### Channel Selection

Zigbee and WiFi both use 2.4 GHz. Channel 20 selected to avoid interference:

| WiFi Channel | Overlapping Zigbee Channels |
|--------------|----------------------------|
| 1 | 11-14 |
| 6 | 16-19 |
| 11 | 21-24 |

With WiFi on channels 1 and 11, **Zigbee channel 20** sits in the gap.

### Network Identifiers

All pre-generated and stored in sops to enable backup/restore without re-pairing:

| Parameter | Format | Purpose |
|-----------|--------|---------|
| `network_key` | 16-byte hex | AES-128 encryption for Zigbee traffic |
| `pan_id` | 16-bit hex | Short network identifier |
| `ext_pan_id` | 8-byte hex | Unique network fingerprint |

Generate with:
```bash
# network_key (16 bytes)
openssl rand -hex 16

# pan_id (2 bytes, prefix with 0x)
echo "0x$(openssl rand -hex 2)"

# ext_pan_id (8 bytes)
openssl rand -hex 8
```

## MQTT Configuration

| Setting | Value |
|---------|-------|
| Server | `mqtts://mqtt-01.vm.mares.id:8883` |
| Base topic | `zigbee2mqtt` |
| Username | `zigbee2mqtt` |
| TLS CA | `/etc/ssl/certs/ca-certificates.crt` (system store) |
| Protocol | MQTT 5.0 |

### MQTT Topics

| Topic | Purpose |
|-------|---------|
| `zigbee2mqtt/bridge/*` | Bridge status, config, devices |
| `zigbee2mqtt/<device>` | Device state messages |
| `zigbee2mqtt/<device>/set` | Device commands |
| `homeassistant/*` | HA MQTT discovery |

## Home Assistant Integration

Enabled via MQTT discovery. Devices auto-appear in HA when paired.

| Setting | Value |
|---------|-------|
| Discovery | Enabled |
| Discovery topic | `homeassistant` |
| Status topic | `homeassistant/status` |

## Frontend Configuration

| Setting | Value |
|---------|-------|
| Package | `zigbee2mqtt-windfront` (new UI) |
| Port | 8080 |
| Bind | `0.0.0.0` (all interfaces) |
| Access | Via nginx proxy at `z2m.mares.id` |
| WebSockets | Required for windfront |

## Device Settings

### Availability Tracking

| Setting | Value | Purpose |
|---------|-------|---------|
| `availability.enabled` | `true` | Track device online/offline |
| `availability.active.timeout` | 10 min | Mains-powered devices |
| `availability.passive.timeout` | 1500 min | Battery devices (~25 hours) |

### Device Defaults

| Setting | Value | Purpose |
|---------|-------|---------|
| `retain` | `true` | Broker keeps last message; HA gets state on restart |
| `qos` | `1` | At-least-once delivery, guaranteed |
| `last_seen` | `ISO_8601` | Timestamp in device messages |

### Security

| Setting | Value |
|---------|-------|
| `permit_join` | `false` (always) |

Enable pairing temporarily via frontend or MQTT when adding devices.

## Module Structure

```
modules/automation/zigbee2mqtt/
  ├── default.nix   # Imports
  ├── options.nix   # Interface (mares.automation.zigbee2mqtt.*)
  └── service.nix   # Implementation

roles/z2m.nix       # Role definition
```

### Module Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | `false` | Enable zigbee2mqtt |
| `openFirewall` | bool | `true` | Open frontend port |
| `serialPort` | string | required | USB adapter path |
| `mqtt.server` | string | required | MQTT broker URL |
| `mqtt.user` | string | `"zigbee2mqtt"` | MQTT username |
| `channel` | int | `20` | Zigbee channel |
| `transmitPower` | int | `10` | TX power in dBm |
| `frontend.port` | port | `8080` | Frontend port |
| `frontend.bindAddress` | string | `"0.0.0.0"` | Frontend bind address |

### Baked-in Settings (not configurable)

- Adapter: `ember`, `rtscts: false`, baudrate 115200
- Frontend package: `zigbee2mqtt-windfront`
- Home Assistant integration: always enabled
- Device defaults: `retain: true`, `qos: 1`
- Availability: enabled with sensible timeouts
- Permit join: `false`
- MQTT version: 5
- Log level: `info`

## Secrets

### zigbee2mqtt vault

| Secret | Format | Purpose |
|--------|--------|---------|
| `zigbee2mqtt-password` | string | MQTT broker authentication |
| `zigbee2mqtt-network_key` | hex string | Zigbee network encryption |
| `zigbee2mqtt-pan_id` | `0xXXXX` | Network PAN ID |
| `zigbee2mqtt-ext_pan_id` | hex string | Extended PAN ID |

### restic vault (add to existing)

| Secret | Purpose |
|--------|---------|
| `restic-zigbee2mqtt_repo_key` | Backup repo encryption |

## Backup

Daily backup to TrueNAS via restic:

| Setting | Value |
|---------|-------|
| Schedule | `03:30` (30 min after hass) |
| Paths | `/var/lib/zigbee2mqtt` |
| Repo | `zigbee2mqtt` on TrueNAS |

Critical files backed up:
- `configuration.yaml` - Main config
- `devices.yaml` - Paired devices
- `groups.yaml` - Device groups
- `coordinator_backup.json` - Network backup
- `database.db` - Device database

## Initial Setup

### 1. Create VM in Proxmox

Create VM 283 on pve-01 from NixOS template.

### 2. USB Passthrough

In Proxmox, add USB device to VM:
1. VM → Hardware → Add → USB Device
2. Select "Sonoff Zigbee 3.0 USB Dongle Plus V2" (or by vendor ID)
3. Start VM

### 3. Identify Serial Port

```bash
ls -la /dev/serial/by-id/
# Look for: usb-SONOFF_Zigbee_3.0_USB_Dongle_Plus_V2_*-if00
```

Update `serialPort` in role with exact path.

### 4. Generate Secrets

```bash
# Generate all network secrets
openssl rand -hex 16  # network_key
openssl rand -hex 2   # pan_id (add 0x prefix)
openssl rand -hex 8   # ext_pan_id

# Generate restic repo password
openssl rand -base64 32
```

Add to sops vault.

### 5. Initialize Restic Repo

On TrueNAS, create backup path. Then initialize:
```bash
restic -r sftp:truenas:/path/to/zigbee2mqtt init
```

### 6. Create MQTT User

On mqtt-01:
```bash
mctl dynsec createRole zigbee2mqtt-access
mctl dynsec addRoleACL zigbee2mqtt-access publishClientSend 'zigbee2mqtt/#' allow
mctl dynsec addRoleACL zigbee2mqtt-access publishClientReceive 'zigbee2mqtt/#' allow
mctl dynsec addRoleACL zigbee2mqtt-access subscribePattern 'zigbee2mqtt/#' allow
mctl dynsec addRoleACL zigbee2mqtt-access publishClientSend 'homeassistant/#' allow
mctl dynsec addRoleACL zigbee2mqtt-access publishClientReceive 'homeassistant/#' allow
mctl dynsec addRoleACL zigbee2mqtt-access subscribePattern 'homeassistant/#' allow

mctl dynsec createGroup zigbee2mqtt-clients
mctl dynsec addGroupRole zigbee2mqtt-clients zigbee2mqtt-access

mctl dynsec createClient zigbee2mqtt
mctl dynsec setClientPassword zigbee2mqtt '<password-from-sops>'
mctl dynsec addGroupClient zigbee2mqtt-clients zigbee2mqtt
```

### 7. Deploy

```bash
./bin/d .#z2m-01
```

### 8. Verify

1. Check service: `systemctl status zigbee2mqtt`
2. Check logs: `journalctl -u zigbee2mqtt -f`
3. Access frontend: `https://z2m.mares.id`
4. Verify MQTT connection in frontend dashboard

## Pairing Devices

1. Open frontend at `z2m.mares.id`
2. Click "Permit join" (top right)
3. Put device in pairing mode (usually hold button 5+ seconds)
4. Device appears in list
5. Rename device with friendly name
6. Disable "Permit join"

Device auto-appears in Home Assistant via MQTT discovery.

## Troubleshooting

### Check Service Status
```bash
systemctl status zigbee2mqtt
journalctl -u zigbee2mqtt -f
```

### Verify USB Device
```bash
ls -la /dev/serial/by-id/
dmesg | grep -i usb
```

### Test MQTT Connection
```bash
# On mqtt-01, subscribe to zigbee2mqtt topics
mosquitto_sub -h mqtt-01.vm.mares.id -p 8883 \
  --cafile /etc/ssl/certs/ca-certificates.crt \
  -u admin -P '<password>' -t 'zigbee2mqtt/#' -v
```

### Firmware Version Mismatch
If logs show EZSP version error:
```
NCP EZSP protocol version of XX does not match Host version 13
```
Re-flash dongle with EmberZNet 7.4.4+ firmware.

### Device Won't Pair
1. Ensure permit_join is enabled
2. Move device closer to coordinator
3. Factory reset device
4. Check channel compatibility (some devices only work on ZLL channels: 11, 15, 20, 25)

### Network Key Issues
If devices stop responding after restore:
- Verify network_key, pan_id, ext_pan_id match original
- May need to re-pair devices if keys changed

## References

- [Zigbee2MQTT Documentation](https://www.zigbee2mqtt.io/)
- [EmberZNet Adapters](https://www.zigbee2mqtt.io/guide/adapters/emberznet.html)
- [Sonoff ZBDongle-E](https://sonoff.tech/product/gateway-and-sensors/sonoff-zigbee-3-0-usb-dongle-plus-e/)
- [Silabs Firmware Flasher](https://darkxst.github.io/silabs-firmware-builder/)
- [zigbee2mqtt-windfront](https://github.com/Nerivec/zigbee2mqtt-windfront)
