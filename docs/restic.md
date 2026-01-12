# Restic Backup System

> **Type:** PRD + Guide | **Created:** 2025-01

## Overview

Application-level backup system using Restic with SFTP transport to TrueNAS. Designed for push-based backups where each service backs itself up to a dedicated repository.

## Architecture

```
┌─────────────────┐     SFTP      ┌─────────────────────────────┐
│ ha-01           │ ────────────→ │ TrueNAS                     │
│ scrypted-01     │ ────────────→ │                             │
│ db-01 (future)  │ ────────────→ │ /backups/                   │
└─────────────────┘               │   ├── hass/                 │
                                  │   ├── scrypted/ (future)    │
                                  │   └── postgres/ (future)    │
                                  └─────────────────────────────┘
```

### Model

- **Push-based**: Each service/VM backs itself up
- **Per-service repos**: Isolated repositories, separate encryption passwords
- **Shared SFTP user**: Single `restic` user on TrueNAS for all clients

## Transport

### SFTP to TrueNAS

| Setting | Value |
|---------|-------|
| Protocol | SFTP |
| TrueNAS user | `restic` |
| Access | SFTP-only, home dir `/mnt/storage01/backups/` |
| Authentication | SSH key (shared across clients) |

### Why SFTP

- TrueNAS has SSH built-in, no additional services needed
- No NFS UID/GID coordination required
- Simple setup, no extra VMs

### Considered Alternatives

| Option | Why Not |
|--------|---------|
| NFS mount | UID/GID dance, mount dependencies |
| Restic REST server | Would require extra VM or Docker on TrueNAS |
| REST server append-only | Nice for ransomware protection, but adds complexity |

## Repository Structure

```
/mnt/storage01/backups/
  ├── pbs/           # Existing - Proxmox Backup Server
  ├── postgres/      # Existing - pg_dump backups
  ├── hass/          # New - Restic repo for Home Assistant
  └── scrypted/      # Future - Restic repo for Scrypted
```

Each Restic repo contains its own internal structure (`data/`, `index/`, `keys/`, `snapshots/`).

## Security

### SSH Key

- Single shared SSH private key for SFTP authentication
- All backup clients use the same key to connect as `restic@truenas`
- Key stored in sops vault

### Repository Passwords

- **Per-repo passwords**: Each repository has its own encryption password
- Isolation: Compromise of one password doesn't expose other repos
- Passwords stored in sops vault

### Backup User

- Backups run as the service user (e.g., `hass`), not root
- Principle of least privilege
- sops secrets owned by the backup user

## Retention Policy

```nix
pruneOpts = [
  "--keep-daily 7"
  "--keep-weekly 4"
  "--keep-monthly 12"
  "--keep-yearly 2"
];
```

| Period | Kept | Use Case |
|--------|------|----------|
| Daily | Last 7 days | "I broke something yesterday" |
| Weekly | Last 4 weeks | "Something went wrong last week" |
| Monthly | Last 12 months | "Need to recover from months ago" |
| Yearly | Last 2 years | "Long-term archive" |

No gaps in coverage - monthly extends to full year before yearly kicks in.

## Schedule

| Setting | Value |
|---------|-------|
| Default time | `03:00:00` |
| Frequency | Daily |

Scheduled at 03:00 to avoid overlap with postgres backup at 02:15.

## Module Design

### Location

- Module: `modules/backup/restic.nix`
- Configuration: In roles (e.g., `roles/hass.nix`)
- Monitoring: Separate role following existing pattern (e.g., `roles/monitoring-restic.nix`)

### Options Structure

```nix
mares.backup.restic = {
  # Global defaults
  defaults = {
    sftpUser = "restic";
    sftpHost = "truenas.srv.mares.id";
    basePath = "/backups";
  };

  jobs.<name> = {
    # Required
    repoPath = "hass";  # → sftp:truenas-backup:hass (relative to home dir)
    passwordFile = config.sops.secrets."restic-hass_password".path;
    sshKeyFile = config.sops.secrets."restic-ssh_private_key".path;
    paths = [ "/var/lib/hass/.storage" ];
    user = "hass";
    group = "hass";

    # Optional with defaults
    exclude = [];                                    # Default: []
    timerConfig.OnCalendar = "*-*-* 03:00:00";      # Default: 03:00
    pruneOpts = [                                    # Default: 7d/4w/12m/2y
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 12"
      "--keep-yearly 2"
    ];
    backupPrepareCommand = null;                     # Default: null (live backup)
    backupCleanupCommand = null;                     # Default: null
    extraBackupArgs = [];                            # Default: []
  };
};
```

### Generated Configuration

The module generates:

1. `services.restic.backups.<job>` with:
   - `repository` constructed from defaults + `repoPath`
   - `passwordFile` and SSH key via environment
   - `createWrapper = true` for CLI access
   - `initialize = true` for auto-init

2. sops secret ownership set to `user`/`group`

### What the Module Does NOT Do

- Configure Prometheus exporter (separate monitoring role)
- Configure Alloy scrape targets (separate monitoring role)

This follows the existing pattern where monitoring is composed in roles.

## Role Examples

### Backup Role (in service role)

```nix
# roles/hass.nix
{ config, ... }:
{
  sops.secrets."restic-hass_password" = {
    sopsFile = ../secrets/restic.yaml;
    owner = "hass";
    group = "hass";
  };

  sops.secrets."restic-ssh_private_key" = {
    sopsFile = ../secrets/restic.yaml;
    owner = "hass";
    group = "hass";
  };

  mares.backup.restic.jobs.hass = {
    repoPath = "hass";
    passwordFile = config.sops.secrets."restic-hass_password".path;
    sshKeyFile = config.sops.secrets."restic-ssh_private_key".path;
    paths = [ "/var/lib/hass/.storage" ];
    user = "hass";
    group = "hass";
  };
}
```

### Monitoring Role

```nix
# roles/monitoring-restic.nix
{ config, ... }:
{
  imports = [
    ../modules/monitoring
  ];

  services.prometheus.exporters.restic = {
    enable = true;
    repository = "sftp:truenas-backup:hass";
    passwordFile = config.sops.secrets."restic-hass_password".path;
    refreshInterval = 3600;  # 1 hour
    port = 9753;
  };

  mares.monitoring.alloy.extraScrapeTargets = [
    {
      job = "restic";
      targets = [ "localhost:9753" ];
    }
  ];
}
```

## Secrets

### Vault: `restic`

| Secret | Purpose | Ownership |
|--------|---------|-----------|
| `restic-ssh_private_key` | SFTP authentication (shared) | Backup user |
| `restic-hass_password` | HA repo encryption | `hass:hass` |
| `restic-scrypted_password` | Scrypted repo encryption (future) | `scrypted:scrypted` |
| `restic-postgres_password` | Postgres repo encryption (future) | TBD |

### Example sops file

```yaml
# secrets/restic.yaml
restic-ssh_private_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  ...
  -----END OPENSSH PRIVATE KEY-----
restic-hass_password: "randomly-generated-secure-password"
```

## TrueNAS Setup (Manual)

These steps are performed manually on TrueNAS, outside of Nix:

1. **Create user**: `restic` with home dir `/mnt/storage01/backups/`
2. **SSH key**: Add public key to `~restic/.ssh/authorized_keys`
3. **Directories**: Create `hass/` in home dir (Restic will initialize the repo)

## CLI Usage

With `createWrapper = true`, a wrapper script is available:

```bash
# List snapshots
restic-hass snapshots

# Browse a snapshot
restic-hass ls latest

# Restore (run as root for proper ownership)
sudo restic-hass restore latest --target /restore/path

# Manual backup
restic-hass backup /var/lib/hass/.storage
```

## Prometheus Metrics

The Restic exporter provides:

| Metric | Description |
|--------|-------------|
| `restic_snapshots_total` | Number of snapshots |
| `restic_backup_timestamp` | Last backup time |
| `restic_backup_files_total` | Files in latest snapshot |
| `restic_backup_size_bytes` | Size of latest snapshot |

Useful for alerting on "backup too old" scenarios.

## Initial Scope

| Service | Status |
|---------|--------|
| Home Assistant | ✅ MVP |
| Scrypted | Future |
| PostgreSQL | Future (evaluate vs existing pg_dump) |

## Open Questions

None - ready for implementation.

## References

- [Restic Documentation](https://restic.readthedocs.io/)
- [NixOS Restic Module](https://search.nixos.org/options?query=services.restic)
- [NixOS Restic Prometheus Exporter](https://search.nixos.org/options?query=prometheus.exporters.restic)
