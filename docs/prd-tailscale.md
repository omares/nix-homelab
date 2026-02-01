# Tailscale VPN Integration PRD

## Overview
Integrate Tailscale into the NixOS infrastructure to provide secure remote access to internal services. The solution uses a **subnet router** approach with a dedicated VPN gateway VM, enabling browser-based access to all .mares.id services and SSH access to any internal IP.

## Overarching Goal

Enable seamless remote access to home infrastructure while traveling, with the ability to:
- Browse internal services (grafana.mares.id, jellyfin.mares.id, etc.) as if at home
- SSH into any internal machine (VMs, IoT devices, PVE hosts) from anywhere
- Keep Tailscale always-on without impacting daily internet usage (split tunneling)
- Support both personal and work Tailscale accounts via fast user switching

## Goals
1. **Primary**: Access HTTP/WebSocket services (Jellyfin, Grafana, Home Assistant, etc.) via browser from anywhere using `.mares.id` domains
2. **Secondary**: SSH access to ANY internal machine (10.10.22.x, 192.168.20.x, 192.168.30.x) via subnet routes
3. **Non-goal**: Route all internet traffic through home network (split tunneling only)
4. **Quality of life**: Always-on VPN that doesn't impair day-to-day browsing/streaming

## Architecture Decision: Subnet Router (Gateway VM)

### Rationale
- **Single Tailscale node** to manage (cleaner than hybrid approach)
- **Full network access** - reach any IP in advertised subnets directly
- **No Tailscale needed on individual VMs** - reduces complexity
- **Works with existing DNS** - `.mares.id` resolves via split DNS
- **Scalable** - add new networks by updating routes on gateway

### Architecture Diagram

```
                    Remote Device (Laptop/Phone)
                           ↓
                   Tailscale Magic Network
                   (100.64.x.x tailnet)
                           ↓
              vpn-01 (100.64.x.x) ← Tailscale Subnet Router
              ┌─────────────────────────────┐
              │  Interface 1: 10.10.22.x   │ ← VM Network
              │  Interface 2: 192.168.20.x │ ← IoT/PVE Network
              └─────────────────────────────┘
                           ↓
        ┌──────────────────┼──────────────────┐
        ↓                  ↓                  ↓
   10.10.22.0/24     192.168.20.0/24    192.168.30.0/24
   (VM network)      (IoT/PVE network)  (NVR/Cameras)
        ↓                  ↓                  ↓
   [atuin-01]        [UDM Pro]           [cameras]
   [db-01]           [PVE hosts]         [scrypted]
   [dns-03]          [IoT devices]
   [proxy-01]
   [jellyfin]
```

### Components

#### 1. Tailscale SaaS (Managed Control Plane)
- **Decision**: Use Tailscale's managed service (tailscale.com)
- **Rationale**: Easier setup, free personal tier, no infrastructure overhead
- **Multi-account**: Fast user switching supported for work/personal use
- **Alternative**: Headscale for self-hosted (documented in Future Enhancements)

#### 2. Subnet Router VM (vpn-01)
**Purpose**: Single gateway providing access to all internal networks

**Network Configuration**:
- **VM ID**: 600-699 range (network services per conventions)
- **Interface 1 (eth0)**: 192.168.20.x/24 (IoT/PVE network - default)
- **Interface 2 (eth1)**: 10.10.22.x/24 (VM network - VLAN tagged)
- **Interface 3 (eth2)**: 192.168.30.x/24 (NVR/Cameras - VLAN tagged, optional)
- **Routes advertised via Tailscale**:
  - `10.10.22.0/24` (VM network)
  - `192.168.20.0/24` (IoT/PVE network)
  - `192.168.30.0/24` (NVR/Cameras network)

**Key Features**:
- Subnet router with IP forwarding enabled
- Split DNS for `.mares.id` domains
- Tailscale SSH enabled for direct gateway access

#### 3. DNS Resolution Strategy
**Problem**: Remote devices can't resolve `.mares.id` (only exists in home Technitium DNS at 10.10.22.199)

**Solution: Split DNS via Tailscale**
- Configure in Tailscale admin console:
  - **Nameservers**: `10.10.22.199` and `10.10.22.225` (Technitium DNS servers)
  - **Domain**: `.mares.id`
  - **Restrict to domain**: Yes (only use for .mares.id)
- Remote devices will:
  - Resolve `.mares.id` via home DNS (through vpn-01)
  - Resolve everything else via normal DNS (Google/Cloudflare/etc.)

### Network Flow Examples

**Web Access (Browser)**:
```
User types: https://grafana.mares.id
    ↓
Remote laptop: "What's grafana.mares.id?"
    ↓
Tailscale DNS: "Ask 10.10.22.199 (via vpn-01)"
    ↓
Technitium DNS: "10.10.22.241"
    ↓
Browser connects to 10.10.22.241 via Tailscale
    ↓
vpn-01 routes traffic to 10.10.22.241
    ↓
Grafana loads ✓
```

**SSH Access (Direct IP)**:
```
User types: ssh 10.10.22.247 (atuin-01)
    ↓
Remote laptop connects via Tailscale (100.64.x.x)
    ↓
vpn-01 receives traffic for 10.10.22.0/24
    ↓
vpn-01 forwards to 10.10.22.247
    ↓
SSH session established ✓
```

**SSH Access (Gateway Jump)**:
```
User types: tailscale ssh vpn-01
    ↓
Connect to vpn-01 via Tailscale
    ↓
From vpn-01: ssh 192.168.20.21 (PVE host)
    ↓
SSH to IoT network ✓
```

## Technical Implementation

### Module Structure
```
modules/networking/tailscale/
├── default.nix      # Imports options + service
├── options.nix      # Configuration interface
└── service.nix      # Implementation
```

### Options Interface

```nix
# modules/networking/tailscale/options.nix
{
  mares.networking.tailscale = {
    enable = mkEnableOption "Tailscale VPN client";

    authKeyFile = mkOption {
      type = types.path;
      description = "Path to Tailscale auth key file (via sops)";
    };

    useAsExitNode = mkOption {
      type = types.bool;
      default = false;
      description = "Allow this node to be an exit node (route all internet traffic)";
    };

    advertiseRoutes = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Subnets to advertise via Tailscale (e.g., [\"10.10.22.0/24\", \"192.168.20.0/24\"])";
    };

    acceptRoutes = mkOption {
      type = types.bool;
      default = false;
      description = "Accept routes advertised by other Tailscale nodes";
    };

    useTailscaleSSH = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Tailscale SSH (authenticate via Tailscale identity)";
    };

    extraUpFlags = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Additional flags for 'tailscale up' command";
    };
  };
}
```

### Service Implementation

```nix
# modules/networking/tailscale/service.nix
{ config, lib, pkgs, ... }:
let cfg = config.mares.networking.tailscale;
in lib.mkIf cfg.enable {
  services.tailscale = {
    enable = true;
    authKeyFile = cfg.authKeyFile;
    # "server" enables IP forwarding, "client" enables loose reverse path filtering
    # Use "server" for subnet router or exit node, "client" for accepting routes
    useRoutingFeatures =
      if (cfg.advertiseRoutes != [] || cfg.useAsExitNode) then "server"
      else if cfg.acceptRoutes then "client"
      else "none";
    extraUpFlags = cfg.extraUpFlags ++
      (lib.optional cfg.useTailscaleSSH "--ssh") ++
      (lib.optionals (cfg.advertiseRoutes != [])
        ["--advertise-routes" (lib.concatStringsSep "," cfg.advertiseRoutes)]) ++
      (lib.optional cfg.acceptRoutes "--accept-routes") ++
      (lib.optional cfg.useAsExitNode "--advertise-exit-node");
  };

  # Trust tailscale0 interface in firewall
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
```

### Roles

#### 1. role-tailscale-subnet-router (for vpn-01)
```nix
# roles/tailscale-subnet-router.nix
{ config, nodeCfg, ... }:
{
  imports = [ ../modules/networking/tailscale ];

  sops-vault.items = [ "tailscale" ];

  sops.secrets.tailscale-authkey = { };

  mares.networking.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets.tailscale-authkey.path;
    useTailscaleSSH = true;

    # Advertise all internal networks
    advertiseRoutes = [
      "10.10.22.0/24"      # VM network
      "192.168.20.0/24"    # IoT/PVE network
      "192.168.30.0/24"    # NVR/Cameras network
    ];
  };

  # Trust internal interfaces for forwarding traffic between networks
  # tailscale0 is already trusted by the module
  networking.firewall.trustedInterfaces = [
    "eth0"  # 192.168.20.x (IoT/PVE - default)
    "eth1"  # 10.10.22.x (VM network - VLAN tagged)
    "eth2"  # 192.168.30.x (NVR/Cameras - VLAN tagged)
  ];
}
```

### SOPS Secret Structure

```yaml
# secrets/tailscale.yaml
tailscale-authkey: tskey-auth-XXXXXXXXXXXXXXXXXXXX
```

### Node Configuration

```nix
# modules/infrastructure/nodes.nix - NEW NODE:

vpn-01 = {
  tags = [ "infra" "tailscale" "vpn" ];
  roles = [
    config.flake.nixosModules.role-tailscale-subnet-router
    config.flake.nixosModules.role-atuin-client
    config.flake.nixosModules.role-monitoring-client
  ];
  host = "192.168.20.XXX";  # Primary IP on IoT/PVE network

  dns = {
    vlan = "pve";  # Or appropriate VLAN for primary interface
  };

  # Note: vpn-01 will have triple network interfaces configured in Proxmox:
  # - eth0 (default): 192.168.20.x/24 (IoT/PVE network)
  # - eth1 (VLAN tagged): 10.10.22.x/24 (VM network)
  # - eth2 (VLAN tagged): 192.168.30.x/24 (NVR/Cameras network)
};
```

## Setup Workflow

### Phase 1: Pre-implementation (One-time setup)

1. **Create Tailscale Account**
   - Sign up at https://login.tailscale.com
   - Create a tailnet (e.g., `mares`)
   - Use GitHub/Google/Microsoft SSO if desired

2. **Generate Auth Key**
   - Admin console → Settings → Keys → Generate auth key
   - **Reusable**: Yes
   - **Ephemeral**: No
   - **Pre-authorized**: Yes
   - Tags: `tag:infra`

3. **Configure Split DNS**
   - Admin console → DNS → Nameservers → Add nameserver
   - **Nameservers**: `10.10.22.199` and `10.10.22.225` (Technitium DNS)
   - **Domain**: `.mares.id`
   - **Restrict to domain**: Yes

4. **Add Secret to SOPS**
   ```bash
   # Add to existing secrets or create new file
   echo "tailscale-authkey: tskey-auth-xxxxx" >> secrets/tailscale.yaml
   sops encrypt secrets/tailscale.yaml
   ```

5. **Proxmox Network Setup for vpn-01**
   - Create VM from NixOS template
   - **Network Interface 1 (eth0)**: Default bridge → gets 192.168.20.x (IoT/PVE)
   - **Network Interface 2 (eth1)**: Bridge with VLAN tag → gets 10.10.22.x (VM network)
   - **Network Interface 3 (eth2)**: Bridge with VLAN tag → gets 192.168.30.x (NVR/Cameras)
   - Boot VM and note assigned IPs

### Phase 2: Implementation

1. **Create Tailscale module** (`modules/networking/tailscale/`)
   - `default.nix`: imports
   - `options.nix`: configuration options
   - `service.nix`: implementation

2. **Create subnet router role** (`roles/tailscale-subnet-router.nix`)

3. **Update nodes.nix** to add vpn-01 with dual network interfaces

4. **Deploy vpn-01**
   ```bash
   ./bin/d vpn-01
   ```

5. **Verify in Tailscale Admin Console**
   - vpn-01 should appear as connected
   - Check that advertised routes are listed
   - Approve routes if needed (subnet router approval)

6. **Enable Subnet Routes**
   - Admin console → Machines → vpn-01 → Edit route settings
   - **Approve** all advertised routes (10.10.22.0/24, 192.168.20.0/24, 192.168.30.0/24)

7. **Test from Remote Device**
   ```bash
   # Install Tailscale
   # Connect to tailnet

   # Test DNS resolution
   dig grafana.mares.id  # Should resolve to 10.10.22.241

   # Test web access
   curl https://grafana.mares.id

   # Test SSH to VM
   ssh 10.10.22.247

   # Test SSH to IoT network
   ssh 192.168.20.21

   # Test SSH via Tailscale to gateway
   tailscale ssh vpn-01
   ```

## Security Considerations

1. **Subnet Router Approval**
   - Routes must be approved in admin console before they're active
   - Prevents malicious nodes from hijacking traffic

2. **Auth Key Rotation**
   - Rotate auth keys every 90 days
   - Procedure: Generate new key → Update sops → Redeploy

3. **ACLs (Access Control Lists)**
   - Default: All devices can reach all destinations
   - Recommended for production:
     ```json
     {
       "acls": [
         {"action": "accept", "src": ["tag:personal"], "dst": ["tag:infra:*"]},
         {"action": "accept", "src": ["tag:work"], "dst": ["tag:work:*"]}
       ]
     }
     ```

4. **Device Approval**
   - Enable in Admin console → Settings → Device approval
   - New devices require manual approval before accessing network

5. **Tailscale SSH**
   - More secure than traditional SSH (no exposed 22/tcp)
   - Authenticates via Tailscale identity (MFA if enabled on account)
   - Check SSH sessions in admin console logs

6. **Firewall on vpn-01**
   - Trust tailscale0 for incoming
   - Forward traffic to internal networks only from tailscale0
   - Block direct access from internet

## Client Device Setup

### macOS
```bash
# Install
brew install tailscale
# Or download from https://tailscale.com/download

# Start
sudo tailscale up

# Switch to work account (if needed)
tailscale switch work

# Back to personal
tailscale switch personal
```

### iOS
1. App Store → "Tailscale"
2. Sign in
3. Connect
4. Safari: `https://grafana.mares.id`

### Linux
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
# Authenticate via browser link
```

### Windows
1. Download from https://tailscale.com/download
2. Install
3. Sign in
4. Connect

## Multi-Account Support (Work + Personal)

**Scenario**: Work uses Tailscale, you want to access both work and home tailnets

**Solution**: Fast User Switching

```bash
# Add work account
tailscale login
# (authenticate with work)

# Set nicknames for easy switching
tailscale set --nickname=personal  # current account
tailscale switch work
tailscale set --nickname=work

# Switch between them
tailscale switch work      # work VPN active
tailscale switch personal  # home VPN active (access .mares.id)
```

**GUI**: Menu bar → Account → Switch account

**Note**: Only ONE tailnet active at a time. Use separate devices for simultaneous access.

## Troubleshooting

### Routes Not Working
```bash
# On vpn-01, check IP forwarding
sysctl net.ipv4.ip_forward

# Check Tailscale status
sudo tailscale status

# Check routes are advertised
sudo tailscale debug prefs | grep Routes

# Check firewall
cat /proc/sys/net/ipv4/conf/all/forwarding
```

### DNS Not Resolving
```bash
# Check Tailscale DNS is being used
cat /etc/resolv.conf

# Should see: nameserver 100.100.100.100

# Test DNS
dig @100.100.100.100 grafana.mares.id
```

### Can't Access IoT Network
```bash
# Check vpn-01 can reach IoT network
ping 192.168.20.1  # UDM Pro

# Check interface configuration
ip addr show

# Check routes are approved in admin console
```

## Success Criteria

- [ ] Can access `https://grafana.mares.id` from remote location via browser
- [ ] Can access `https://jellyfin.mares.id` from remote location via browser
- [ ] Can SSH to `10.10.22.247` (atuin-01) directly from remote device
- [ ] Can SSH to `192.168.20.21` (PVE host) directly from remote device
- [ ] Can access `https://scrypted.mares.id` (NVR network via proxy)
- [ ] Home internet traffic NOT routed through VPN (split tunnel verified)
- [ ] Tailscale can run always-on without impairing daily browsing/streaming
- [ ] Can switch between work and personal tailnets via `tailscale switch`

## Future Enhancements

1. **Exit Node**: Enable on vpn-01 for full-tunnel option when on untrusted networks
   ```nix
   useAsExitNode = true;
   ```

2. **High Availability**: Deploy vpn-02 as backup subnet router
   - Both advertise same routes
   - Tailscale automatically failover

3. **Mullvad Integration**: Tailscale + Mullvad for privacy exit nodes
   - `tailscale up --exit-node=gb-mnc-wg-201.mullvad.ts.net`

4. **Tailscale Funnel**: Expose specific services publicly without VPN
   - `tailscale funnel 443 https://localhost:8080`
   - Use case: Share jellyfin with friends without giving VPN access

5. **Headscale (Self-Hosted)**: If Tailscale SaaS becomes undesirable
   - Pros: Full control, no external dependencies
   - Cons: Additional VM to maintain, more complex

6. **ACL Hardening**: Implement restrictive ACLs
   - Separate tags for `tag:infra`, `tag:personal`, `tag:guest`
   - Restrict guest access to specific services only

7. **Tailscale SSH Session Recording**: For compliance/auditing
   - Record all SSH sessions via Tailscale

## References

- NixOS Tailscale Wiki: https://wiki.nixos.org/wiki/Tailscale
- Tailscale NixOS Options: https://search.nixos.org/options?query=services.tailscale
- Subnet Routing: https://tailscale.com/kb/1019/subnets
- Split DNS: https://tailscale.com/kb/1054/dns
- Tailscale SSH: https://tailscale.com/kb/1193/tailscale-ssh
- Fast User Switching: https://tailscale.com/kb/1225/fast-user-switching
- Headscale: https://github.com/juanfont/headscale
