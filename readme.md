## Project Structure Overview

### Project Organization

This repository organizes my NixOS configurations using the following structure.

```
└── root/
    ├── flake/               # Flake output definitions
    ├── roles/               # System compositions
    ├── packages/            # Custom package definitions
    └── modules/             # Configuration components
        ├── infrastructure/  # Infrastructure definitions
        ├── services/        # Custom service implementations
        ├── database/        # Database configurations
        ├── media/           # Media service configurations
        ├── networking/      # Network configurations
        └── [other domains]/ # Other domain-specific modules
```

### Directory Purposes

`⁠flake/`\
Contains the implementation of flake outputs, split into multiple files for better organization. This uses flake-parts
to modularize the flake.nix functionality, making it easier to maintain. These files define packages, NixOS modules,
and other outputs used within this project.

`⁠roles/`\
Contains composite system configurations that define specific functionality by integrating multiple modules. Roles serve
as the integration layer that connects various services and resources together.
Roles are responsible for enabling the services required for a specific function, managing resource dependencies like
storage mounts and hardware requirements or listing used SOPS secrets.

The idea of a role is to provide an overview of what functionality is provided and used without requiring deep dives
into service implementations.

A machine can have multiple roles, but a role is not tied to a specific machine. Roles define state and functionality
rather than machines themselves.

`⁠packages/`\
Contains definitions for custom packages that aren't available in nixpkgs or require modifications.

`⁠modules/[domain]/`\
Contains configurations organized by functional domains. Each domain directory groups related functionality based on
purpose rather than technical classification:

- `⁠database/`: Database service configurations
- `⁠media/`: Media-related services
- `⁠networking/`: Network configurations
- `⁠shell/`: Shell tools and configurations
- `⁠storage/`: Storage solutions
- `⁠hardware/`: Hardware-specific configurations

Modules define service capabilities, options, and detailed implementations. They handle their own internal configuration,
including service-specific secret management and firewall rules (with toggle options), but don't enable themselves by
 default.

`⁠modules/services/`\
Contains custom service implementations that aren't provided by nixpkgs.


`⁠modules/infrastructure/`\
Contains definitions of my environment's structure, primarily focusing on nodes and their associated roles. This defines
which machines exist in my environment, what roles they have, and whether they should be proxied. The infrastructure
module serves as the registry of machines that forms the foundation of my homelab.

### Design Principles
1. **Domain-based organization**: Group related functionality by purpose
2. **Separation of implementation and activation:**:
    - Modules implement services and their configuration options
    - Roles composite modules and set specific configuration values
3. **Service encapsulation**: Services handle their own implementation details, including detailed configuration, how to integrate secrets, and firewall rules (with toggle options)
4. **Role integration**: Roles enable required services, manage storage mounts and hardware requirements, connect services to required resources, and should provide an overview of functionality.
5. **Flat hierarchies**: Keep directory structures flat. Create subdirectories only when there are several related files (3+) or when the organization significantly improves clarity. For domains with just 1-2 files, prefer keeping them as direct files in the domain directory rather than creating additional subdirectories.

This structure creates a clean separation between implementation (modules) and activation (roles).


## Proxmox VM Templates

The flake offers packages that generate Proxmox VM templates using [nixos-generators](https://github.com/nix-community/nixos-generators).
The resulting `vma` files can be directly imported into Proxmox and used, eliminating the need to manually configure a VM and install NixOS.
Please note the EFI secure boot complications that need to be handled when not using the [deploy-image](bin/deploy-image) script.

### Available Templates

The templates use an [enhanced format](./modules/virtualisation/format/proxmox-enhanced.nix) based on the Nixpkgs [Proxmox image](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/virtualisation/proxmox-image.nix#L1). This enhanced template enables the creation of SCSI disks and other smaller improvements.

#### proxmox-x86-optimized
Optimized VM template for x86_64 systems that aligns with the hardware of my main Proxmox host.

- Machine: q35 (PCIe-based architecture)
- Storage: SCSI with optimizations (discard, I/O thread, SSD) for optimal M.2 storage usage
- Cloud-init enabled
- UEFI boot
- Extended kernel modules like ...
  - Storage: virtio_scsi, scsi_mod, sd_mod
  - Memory: virtio_balloon (dynamic memory allocation)
  - Random: virtio_rng (entropy from host)
  - USB: Full stack (1.1 through 3.0) support


#### proxmox-x86-legacy (Legacy)
Default VM template for x86_64 systems, provides highest compatibility.
I started with the template, so a few of my VMs are still running on it.

- Machine: i440fx
- Storage: VirtIO-based
- Cloud-init enabled

#### proxmox-x86-builder
Specialized template for Nix remote builders.

- Based on proxmox-x86-optimized
- Includes builder-specific configurations
- Includes remote builder role configuration
- Supports building ARM packages, but it is very slow. Helpful for getting started with ARM systems until a host-specific ARM builder can be booted.

#### proxmox-arm
Template used for virtual machines running on my Raspberry Pi using [Proxmox-Port](https://github.com/jiangcuo/Proxmox-Port).

- Based on standard nixpkgs image
- Configured according to [Proxmox ARM port specifications](https://github.com/jiangcuo/Proxmox-Port/wiki/Qemu-VM)
- Suitable for ARM-based Proxmox installations

### Building and deployment
Templates can be built using the standard Nix commands:
```nix
nix build .#proxmox-x86-optimized
```

[deploy-image](bin/deploy-image) automates the VM creation process inside proxmox:

- Uploads template to Proxmox host
- Creates/Restores the created VMA file with specified ID
- Recreates the EFI disk to prevent secure boot issues.

The build VM can be used immediately after deployment.

## Proxmox VM ID Conventions

### Overview
- `1-99`: Reserved for cluster/system use
- `100-999`: Production VMs
- `1000-1999`: Templates
- `2000-2999`: Development/Test VMs
- `9000-9999`: Temporary/Clone VMs

### Production VMs (100-999)

#### Infrastructure Services (100-199)
- `100-109`: DNS/DHCP
- `110-119`: Authentication/Directory (LDAP, AD)
- `120-129`: Monitoring/Logging
- `130-139`: Build/CI Services
- `140-149`: Backup Services
- `150-159`: Storage Services
- `160-169`: Network Services
- `170-179`: Security Services
- `180-189`: Management Tools
- `190-199`: Other Infrastructure

#### Applications (200-399)
- `200-219`: Web Services
- `220-239`: Database Servers
- `240-259`: Mail Services
- `260-279`: Media Services
- `280-299`: Home Automation
- `300-319`: Documentation/Wiki
- `320-339`: Communication Services
- `340-359`: File Sharing
- `360-379`: Development Tools
- `380-399`: Other Applications

#### Container Platforms (400-499)
- `400-419`: Kubernetes Nodes
- `420-439`: Docker Hosts
- `440-459`: Container Management
- `460-479`: Container Registry
- `480-499`: Other Container Services

#### Storage Solutions (500-599)
- `500-519`: Primary Storage
- `520-539`: Backup Storage
- `540-559`: Archive Storage
- `560-579`: Object Storage
- `580-599`: Other Storage

#### Network Services (600-699)
- `600-619`: Firewalls/Routers
- `620-639`: VPN Services
- `640-659`: Load Balancers
- `660-679`: Proxy Services
- `680-699`: Other Network Services

#### Special Purpose (700-899)
- `700-749`: Analytics/Metrics
- `750-799`: AI/ML Services
- `800-849`: IoT Services
- `850-899`: Custom Solutions

#### Reserved (900-999)
- `900-999`: Future Use/Expansion

#### Templates (1000-1999)
- `1000-1099`: Linux Distribution Templates
- `1100-1199`: Windows Templates
- `1200-1299`: Application Templates
- `1300-1399`: Container Templates
- `1400-1499`: Custom Templates
- `1500-1999`: Reserved for Future Templates

#### Development/Test (2000-2999)
- `2000-2199`: Development Environment
- `2200-2399`: Testing Environment
- `2400-2599`: Staging Environment
- `2600-2799`: QA Environment
- `2800-2999`: Experimental VMs

#### Temporary VMs (9000-9999)
- `9000-9499`: Clones
- `9500-9699`: Testing
- `9700-9899`: Temporary Workloads
- `9900-9999`: Emergency/Recovery

### Notes
- Leave gaps between used IDs for future expansion
- Critical infrastructure VMs (like storage, backup) should maintain existing IDs if already established
- Document any deviations from this scheme
- Consider using tags in addition to ID ranges for better organization

## VM Naming Convention

### Format
`{purpose}-{nn}`

Example: `dns-01`, `k8s-01`, `db-01`

### Purpose Prefixes

#### Infrastructure
- `dns`: DNS Servers
- `dhcp`: DHCP Services
- `fw`: Firewalls
- `proxy`: Reverse Proxies
- `mon`: Monitoring Services
- `backup`: Backup Services
- `nfs`: File Servers
- `git`: Git Servers
- `ldap`: Directory Services
- `vpn`: VPN Services
- `build`: Build Servers/CI

#### Applications
- `web`: Web Servers
- `app`: Application Servers
- `db`: Database Servers
- `cache`: Caching Services
- `mail`: Mail Servers
- `ci`: CI/CD Services
- `docker`: Docker Hosts
- `k8s`: Kubernetes Nodes
- `mqtt`: Message Brokers

#### Storage
- `nas`: Network Attached Storage
- `san`: Storage Area Network
- `store`: General Storage
- `archive`: Archive Storage

#### Media/Home
- `plex`: Media Servers
- `ha`: Home Assistant
- `cam`: Camera/Surveillance
- `media`: Media Services
- `pi`: Pi-hole/DNS Filtering

### Numbering
- Two-digit number starting with 01
- Example: web:01, web:02

### Best Practices
1. Use lowercase only
2. No special characters except colon (:)
3. Keep names short but meaningful
4. Be consistent with abbreviations
5. Document any exceptions
6. Use sequential numbering

### Examples
```text
# Infrastructure
dns-01     # Primary DNS
proxy-01   # Main reverse proxy
build-01   # Build server

# Applications
web-01     # Primary web server
db-01      # Main database
app-01     # Application server

# Storage
nas-01     # Primary NAS
store-01   # General storage

# Media/Home
plex-01    # Media server
ha-01      # Home Assistant
```

### Notes
- Names should be easily identifiable
- Purpose should be clear from the name
- Numbers allow for multiple instances
- Avoid environment prefixes unless needed (dev/prod)
- Consider DNS implications when naming
- Keep consistent across documentation and configurations
