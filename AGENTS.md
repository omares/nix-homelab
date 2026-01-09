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

## Module Implementation Patterns

### Module vs Role Responsibilities

| Aspect | Module | Role |
|--------|--------|------|
| Service config | ✅ Implementation | ❌ |
| Firewall rules | ✅ With `openFirewall` toggle | ❌ |
| ACME cert request | ❌ | ✅ |
| Cert path | ✅ Accepts `certDirectory` | ✅ Passes from ACME |
| Systemd deps | ❌ | ✅ `after`/`wants` for resources |
| Secrets declaration | ❌ | ✅ `sops-vault.items` |
| Secrets usage | ✅ Accepts `*File` options | ✅ Passes `config.sops.secrets.*.path` |

### Multi-File Module Structure

```
modules/<domain>/<service>/
├── default.nix   # imports = [ ./options.nix ./service.nix ];
├── options.nix   # Interface: mkOption/mkEnableOption
└── service.nix   # Implementation: mkIf cfg.enable { ... }
```

### Role Structure

```nix
{ config, nodeCfg, mares, ... }:
{
  imports = [ ../modules/<domain>/<service> ];
  sops-vault.items = [ "vault-name" ];
  
  mares.<domain>.<service> = {
    enable = true;
    bindAddress = nodeCfg.host;
  };
}
```

### ACME TLS Pattern

`mares.networking.acme.enable` only sets defaults (email, dnsProvider, credentials). Each cert must be explicitly requested:

```nix
{ config, nodeCfg, ... }:
let
  # IMPORTANT: Always use nodeCfg.dns.fqdn for the ACME hostname.
  # This resolves to <nodename>.vm.mares.id (e.g., mqtt-01.vm.mares.id)
  # which matches the auto-generated DNS A records.
  # Do NOT hardcode hostnames like "mqtt-01.mares.id" - these resolve
  # to the proxy server, not the actual VM.
  acmeHost = nodeCfg.dns.fqdn;
in
{
  mares.networking.acme.enable = true;

  security.acme.certs.${acmeHost} = {
    group = "service-group";
    reloadServices = [ "service.service" ];
  };

  systemd.services.service = {
    after = [ "acme-${acmeHost}.service" ];
    wants = [ "acme-${acmeHost}.service" ];
  };

  mares.<domain>.<service>.certDirectory = config.security.acme.certs.${acmeHost}.directory;
}
```

### Git Tracking

Nix flakes only see git-tracked files. After creating new files:
```bash
git add modules/<new>/ roles/<new>.nix
```

### Secrets with LoadCredential

Use systemd's `LoadCredential` for secure secret handling. This allows multiple services to read the same secret without file permission issues.

**Module** - Accepts secret file path, configures LoadCredential, uses credentials path internally:

```nix
# Options
tokenFile = lib.mkOption {
  type = lib.types.path;
  description = "Path to token file (loaded via systemd LoadCredential).";
};

# Config
systemd.services.myservice.serviceConfig.LoadCredential = [
  "my-token:${cfg.tokenFile}"
];

# Use the credentials path in service config (NOT the original path)
services.myservice.settings.tokenFile = "/run/credentials/myservice.service/my-token";
```

**Role** - Declares secrets via sops-vault, passes paths to module:

```nix
sops-vault.items = [ "myservice" ];

# For secrets read by provisioning scripts running as service user, set owner
sops.secrets.myservice-admin_password.owner = "myservice";

mares.myservice = {
  enable = true;
  tokenFile = config.sops.secrets.myservice-token.path;
};
```

**Key points:**
- `LoadCredential` copies secret to `/run/credentials/<service>.service/<name>`
- Each service gets its own copy with proper permissions
- Module uses credentials path (`/run/credentials/...`), role passes sops path (`/run/secrets/...`)
- For secrets read directly by service user (not via LoadCredential), set `sops.secrets.*.owner`

### Comments

Avoid redundant comments that restate what code obviously does:
```nix
# Bad
# Open firewall for MQTT port
networking.firewall.allowedTCPPorts = [ cfg.port ];

# Good - no comment needed
networking.firewall.allowedTCPPorts = [ cfg.port ];

# Good - explains WHY
# Technitium requires PFX format, convert from ACME PEM files
systemd.services.technitium-cert = { ... };
```

## MCP Tools (MANDATORY)
ALWAYS use NixOS MCP server for all Nix operations. Especially for verifying the correctness of options and other configurations:
`nixos_nixos_search`, `nixos_nixos_info`, `nixos_home_manager_*`, `nixos_darwin_*`, `nixos_nixhub_*` for package/option lookups.
