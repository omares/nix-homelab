# Meross LAN Integration

> **Type:** Guide | **Created:** 2025-01

## Overview

This guide covers setting up Meross smart devices (power strips, plugs) with local MQTT control via the meross-lan Home Assistant integration. No cloud dependency.

## Prerequisites

- MQTT broker running with Dynamic Security (see `mqtt.md`)
- Home Assistant with meross-lan integration (HACS)
- Meross device on local network

## Architecture

```
┌─────────────┐      MQTT (8883)      ┌─────────────┐
│   Meross    │ ───────────────────── │   mqtt-01   │
│   Device    │                       │             │
└─────────────┘                       └──────┬──────┘
                                             │
                                             │ MQTT
                                             │
                                      ┌──────┴──────┐
                                      │    ha-01    │
                                      │ meross-lan  │
                                      └─────────────┘
```

## Meross Device Setup

### Step 1: Get Device Info

Use the `meross info` command to get the device MAC address and MQTT password:

```bash
meross info --ip <device-ip> --key <your-key>
```

Where `<your-key>` is a secret key stored in 1Password (or your password manager of choice).

The output provides:
- **MAC address**: Used as the MQTT username (e.g., `48:e1:e9:33:89:a5`)
- **MQTT password**: Pre-calculated in the correct format

### Password Format (Reference)

For reference, Meross MQTT passwords follow this format:

```
{mac-address}_{md5({mac-address}{key})}
```

The `meross info` tool calculates this automatically when you provide the key.

### Step 2: Add Client to MQTT

On mqtt-01, using the MAC and password from `meross info`:

```bash
mctl dynsec createClient '<mac-address>'
mctl dynsec setClientPassword '<mac-address>' '<mqtt-password>'
mctl dynsec addGroupClient meross-devices '<mac-address>'
```

### Step 3: Configure Device for Local MQTT

Meross devices have hardcoded cloud MQTT servers. Use the bytespider/Meross tool to reconfigure the device to use local MQTT.

#### Install bytespider/Meross

```bash
git clone https://github.com/bytespider/Meross.git
cd Meross
npm install
```

#### Patch Source Code (CRLF Fix)

The Meross device returns malformed HTTP responses (missing CR in CRLF line endings). Node.js HTTP parser is strict and rejects these:

```
Parse Error: Missing expected CR after response line
```

Fix by replacing the built-in Node.js HTTP/fetch calls with curl, which is more lenient with malformed responses. This is a quick hack but works reliably.

#### Build

```bash
npm run build
```

The compiled CLI is located at `./packages/cli/dist/meross.js`.

#### Run the Setup Tool

```bash
# Get device info (MAC address, MQTT password)
node ./packages/cli/dist/meross.js info --ip <device-ip> --key <your-key>

# Configure device for local MQTT
node ./packages/cli/dist/meross.js setup --ip <device-ip> --key <your-key> \
  --mqtt-host mqtt-01.vm.mares.id --mqtt-port 8883
```

The setup command will:
1. Connect to the device
2. Send configuration to point to your MQTT broker
3. Device will reboot and connect to local MQTT

### Step 4: Verify MQTT Connection

On mqtt-01, check logs:

```bash
journalctl -u mosquitto -f
```

You should see:

```
New client connected from <device-ip> as fmware:... (u'48:e1:e9:33:89:a5')
```

Verify the device is publishing:

```bash
mosquitto_sub -h mqtt-01.vm.mares.id -p 8883 \
  --cafile /etc/ssl/certs/ca-certificates.crt \
  -u admin -P '<password>' -t '/appliance/#' -v
```

### Step 5: Add to Home Assistant

1. Go to **Settings -> Devices & Services -> meross_lan**
2. The device should appear under "Discovered"
3. Click **Add** on the discovered device
4. Enter:
   - **Device name**: Following naming convention (e.g., `Living Room TV Power Strip`)
   - **Key**: `meross` (same key used in password calculation)
5. Click Submit

## Entity Naming Convention

Follow the standard convention:

```
<domain>.<area>_<device>[_<measurement>]
```

Examples:
- `switch.living_room_tv_power_strip`
- `switch.living_room_tv_power_strip_outlet_1`
- `switch.office_omar_power_strip`

Set a descriptive friendly name when adding the device, and HA will generate appropriate entity IDs.

## Troubleshooting

### Device Not Connecting

1. **Check MQTT client exists**:
   ```bash
   mctl dynsec getClient '48:e1:e9:33:89:a5'
   ```

2. **Check client is in group**:
   ```bash
   mctl dynsec getGroup meross-devices
   ```
   If not listed, add it:
   ```bash
   mctl dynsec addGroupClient meross-devices '48:e1:e9:33:89:a5'
   ```

3. **Verify password format**: Ensure no extra characters, correct MD5 hash

### Device Connects but No Topics

Check the `meross-access` role has correct ACLs:

```bash
mctl dynsec getRole meross-access
```

Should show `/appliance/#` patterns for publish/subscribe.

### meross-lan Not Discovering Device

1. Verify device is publishing to `/appliance/#` topics
2. Check meross-lan MQTT Hub is connected to mqtt-01
3. Try clicking "Refresh" button on the meross-lan integration

### Removing a Device

To remove from meross-lan:
1. Go to **Settings -> Devices & Services -> meross_lan**
2. Click on the integration (not device)
3. Find the entry and delete it

Note: The device-level delete may be grayed out. Use the integration-level delete.

## Power Monitoring

Not all Meross devices support power monitoring:

| Model | Power Monitoring |
|-------|------------------|
| MSS425E | No |
| MSS425F | Yes |
| MSS310 | Yes |
| MSS315 | Yes |

If your device doesn't show power sensors, it's likely a hardware limitation.

## Adding Another Device

For each new Meross device, repeat:

1. Get device info: `meross info --ip <device-ip> --key <your-key>`
2. Add MQTT client on mqtt-01:
   ```bash
   mctl dynsec createClient '<mac>'
   mctl dynsec setClientPassword '<mac>' '<password>'
   mctl dynsec addGroupClient meross-devices '<mac>'
   ```
3. Patch device firmware to use local MQTT
4. Add in Home Assistant meross-lan
