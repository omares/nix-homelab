# NixOS Proxmox VM Deployment

Deploys NixOS VMs on Proxmox using Nix Flakes, deploy-rs, and custom VMA format.

**Response Format**: 
- Prefix all replies with ⚡ when adhering to these instructions
- Prefix sub-process spawning replies with 🔀 (replaces ⚡)

## Project Context
Read `readme.md` at the start of every conversation to understand project structure, conventions, and available tooling.

## Sub-Process Delegation
Long-running tasks MUST be delegated to sub-agents to avoid polluting the main conversation:
- **Formatting**: `nix fmt`
- **Builds**: `nix build`, `nix flake check`
- **Deployments**: `./bin/d`, `deploy`
- **Research**: Use Serena for codebase exploration and analysis
- **Documentation**: Reading external docs or fetching sources

## Commands
- **Format**: `nix fmt` (uses treefmt-nix with nixfmt)
- **Check**: `nix flake check` (validates outputs, runs deploy-rs checks, and verifies formatting)
- **Build**: `nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel`
- **Deploy**: Changes are deployed using deploy-rs (https://github.com/serokell/deploy-rs) via `deploy --targets <TARGETS>` often using the `--skip-checks` flag to reduce waiting time. Use the `./bin/d` wrapper for easier deployments: `./bin/d .#<hostname>` or `./bin/d tag <name>`.
- **Dev shell**: `nix develop` (provides deploy-rs, compose2nix)

## Code Style
- **Module args**: `{ lib, config, pkgs, ... }:` — custom lib via `mares` argument
- **Imports**: At top: `imports = [ ./file.nix ];`
- **Options**: `mkOption` with type/default/description; `mkEnableOption` for booleans
- **Naming**: camelCase for options, kebab-case for files
- **Formatting**: nixfmt-rfc-style (2-space indent, aligned attrsets)
- **Structure**: `default.nix` (imports), `options.nix` (interface), `service.nix` (impl)
- **Roles**: Composable configs in `roles/` combining multiple modules
- **Conditionals**: Use `mkIf config.option.enable` for conditional config

Keep the nix code simple.

## MCP Tools (MANDATORY)
ALWAYS use NixOS MCP server for all Nix operations. Especially for verifying the correctness of options and other configurations:
`nixos_nixos_search`, `nixos_nixos_info`, `nixos_home_manager_*`, `nixos_darwin_*`, `nixos_nixhub_*` for package/option lookups.
