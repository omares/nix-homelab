# SOPS SSH Host Key Race Condition

> **Type:** PRD | **Created:** 2025-01

## Problem Statement

When deploying a new VM, there's a race condition between SSH host key generation and sops secret encryption that causes deployment failures.

### Current Workflow (Broken)

1. Clone VM from Proxmox template
2. Boot VM, note IP address
3. Run `ssh-keyscan <ip>` to get SSH host key
4. Convert to age key, add to `.sops.yaml`
5. Encrypt secrets for the new host
6. Deploy with `./bin/d --init .#hostname`
7. **FAIL**: sops can't decrypt - host key changed

### Root Cause

- Proxmox templates include SSH host keys baked in during `nix build`
- When VM boots, NixOS regenerates SSH host keys (correct security behavior)
- The keyscan at step 3 captures the **template's** key, not the **final** key
- After first boot, the host has a different key than secrets were encrypted for

## Requirements

### Must Have

- Predictable SSH host key before first deployment
- Single keyscan that captures the permanent key
- No manual retry/rescan workflow

### Nice to Have

- Automated key extraction during VM creation
- Integration with existing `./bin/d` workflow

## Proposed Solutions

### Option A: Workflow Change (No Code)

Document the correct order:
1. Clone VM, boot it
2. SSH in once to trigger key regeneration: `ssh root@<ip> "true"`
3. **Then** keyscan - this captures the final key
4. Continue with sops setup and deploy

**Pros**: No code changes
**Cons**: Easy to forget, error-prone

### Option B: Remove Keys from Template

Modify template to NOT include SSH host keys. Keys only generate on first boot.

```nix
# In proxmox template config
services.openssh.hostKeys = lib.mkForce [];
```

First boot generates keys, and that's the permanent key.

**Pros**: Simple, keyscan at any time after boot works
**Cons**: Slightly longer first boot, need to test cloud-init interaction

### Option C: Pre-define Host Keys in Config

Store SSH host keys in sops, define them in node config:

```nix
# In role or node config
services.openssh.hostKeys = [
  { path = "/etc/ssh/ssh_host_ed25519_key"; type = "ed25519"; }
];

# Key content from sops
environment.etc."ssh/ssh_host_ed25519_key" = {
  source = config.sops.secrets.ssh-host-key.path;
  mode = "0600";
};
```

**Pros**: Key known before VM exists, fully deterministic
**Cons**: Chicken-and-egg (need key to encrypt, need encrypt to deploy key), more complex setup

### Option D: Generate Key Locally, Inject via Cloud-Init

1. Generate SSH host key locally during VM creation
2. Inject via cloud-init user-data
3. Use that key for sops immediately

Could integrate with `./bin/deploy-image`:
```bash
./bin/deploy-image --vm-id 283 --name mqtt-01
# Generates key, outputs age public key, injects into VM
```

**Pros**: Fully automated, key available immediately
**Cons**: Requires cloud-init customization, more complex

## Recommendation

**Short term**: Option A (document the workflow)
**Medium term**: Option B (remove keys from template) - simplest code change
**Long term**: Option D (full automation) - best UX

## Success Criteria

- Zero failed deployments due to SSH key mismatch
- Single, clear workflow for new VM setup
- No manual key re-scanning required

## Related Files

- `modules/virtualisation/format/proxmox-enhanced.nix` - Template config
- `bin/deploy-image` - VM creation script
- `.sops.yaml` - Secret encryption config
