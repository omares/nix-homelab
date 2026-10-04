# Suggested Commands for Development

## Formatting & Checks
```bash
# Format all Nix code (treefmt + nixfmt)
nix fmt

# Validate flake, run deploy-rs checks and the formatting check
nix flake check
```

## Build & Deployment
```bash
# deploy and other tools live in the dev shell (deploy-rs, compose2nix)
nix develop

# Build a specific NixOS configuration
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel

# Evaluate only (fast sanity check, no build)
nix eval --raw .#nixosConfigurations.<hostname>.config.system.build.toplevel.drvPath

# Deploy a node or all nodes with a tag (inside nix develop)
./bin/d <hostname>
./bin/d tag <name>

# Deploy a VM image to Proxmox
./bin/deploy-image --host <PROXMOX_HOST> --vmid <VM_ID> --apply
```

## Nix
```bash
# Update flake inputs
nix flake update

# Show flake outputs
nix flake show

# Show derivation info
nix derivation show .#<output>
```

## Notes
- Flakes only see git-tracked files: `git add` new files before building.
- Builds for x86_64-linux run on the remote builder build-01.
