# NixOS Proxmox Infrastructure Project Overview

## Purpose
NixOS-based infrastructure-as-code for a homelab on Proxmox. Declarative configuration for media, DNS, databases, home automation, monitoring and reverse proxy VMs.

## Tech Stack
- **Core**: NixOS with Nix flakes (flake-parts), nixpkgs-unstable plus nixpkgs-master for selected packages
- **Virtualization**: Proxmox VMs (custom enhanced VMA format)
- **Deployment**: deploy-rs via the `./bin/d` wrapper; remote builder build-01
- **Secrets**: sops-nix with nix-sops-vault (`sops-vault.items` in roles)
- **Formatting**: treefmt-nix with nixfmt (`nix fmt`)
- **Languages**: Nix, Bash

## Key Services
- **Home Automation**: Home Assistant (hass-01), Mosquitto with Dynamic Security (mqtt-01), Zigbee2MQTT, wmbusmeters (wmbus-01), evcc, Scrypted with OpenVINO
- **Media Stack**: Jellyfin, Sonarr, Radarr, Prowlarr, SABnzbd, Recyclarr, Seerr
- **Database**: PostgreSQL with pgbouncer, backups
- **DNS**: Technitium (primary/secondary), AdGuard Home
- **Networking**: nginx reverse proxy, Tailscale subnet router, ACME certificates
- **Monitoring**: monitoring server and clients
- **Shell History**: Atuin server/client

## Project Structure
- `flake.nix` - Flake entry point (flake-parts)
- `flake/` - Flake modules (checks, deploy, devShells, packages, nixosConfigurations, tags)
- `modules/` - NixOS modules by domain (automation, networking, starr, database, monitoring, ...)
- `modules/infrastructure/nodes.nix` - Node inventory: hosts, roles, tags
- `roles/` - Composable server roles combining modules, secrets and ACME
- `packages/` - Custom packages (home-assistant custom components and cards, scrypted)
- `lib/` - Helper functions, exposed to modules as the `mares` argument
- `bin/` - `d` (deploy wrapper), `deploy-image`, `ssh-config`
- `docs/` - Service documentation (ha.md, mqtt.md, ...)
- `treefmt.nix` - Formatter configuration

## Deployment Target
Proxmox hypervisor using a custom enhanced VMA format for SCSI disk support and other improvements.
