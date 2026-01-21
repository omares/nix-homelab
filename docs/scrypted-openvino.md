# Scrypted Plugin Pre-provisioning

> **Type:** PRD | **Created:** 2025-01 | **Status:** IMPLEMENTED

## Revision History

| Date       | Status      | Description                                                             |
| ---------- | ----------- | ----------------------------------------------------------------------- |
| 2025-01-13 | Abandoned   | Original OpenVINO-only approach abandoned due to maintenance burden     |
| 2025-01-13 | Revised     | New approach: Auto-generate packages for all Node.js plugins + sideload |
| 2025-01-13 | Implemented | Phase 1 & 2 complete - package infra + sideload service                 |

---

## Overview

Create an automated system to pre-provision Scrypted plugins for offline installation via sideloading API. This enables reproducible deployments where plugins are fetched at Nix build time and installed to Scrypted at first boot.

## Problem Statement

Scrypted plugins are normally installed via the UI, which fetches packages from npm at runtime. This creates several issues:

1. **Reproducibility**: Plugin versions can drift between deployments
2. **Reliability**: npm outages or network issues can break deployments
3. **Speed**: First boot requires downloading all plugins
4. **Air-gap scenarios**: Some environments have restricted internet access

## Goals

- **Automated Packaging**: Auto-generate Nix packages for all ~55 Node.js plugins from npm
- **Declarative Configuration**: NixOS option to specify which plugins to install
- **Offline Installation**: Sideload plugins via Scrypted API at first boot
- **Low Maintenance**: Single `update.sh` script refreshes all plugin versions/hashes
- **OpenVINO Support**: Manual package for the complex Python-based OpenVINO plugin

## Non-Goals

- Full air-gap support (NVR still downloads libav, Cloud needs licensing)
- Packaging all Python plugins (only OpenVINO for now)
- Removing plugins not in the declared list (additive only)

---

## Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Build Time (Nix)                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  update.sh ──► Fetches all @scrypted/* plugins from npm             │
│       │        Skips MANUAL_PLUGINS and IGNORED_PLUGINS             │
│       │        Generates plugins/<name>/package.nix for each        │
│       ▼                                                             │
│  plugins/                                                           │
│  ├── nvr/package.nix          (auto-generated)                      │
│  ├── doorbird/package.nix     (auto-generated)                      │
│  ├── openvino/package.nix     (manual - in MANUAL_PLUGINS)          │
│  └── ...                                                            │
│       │                                                             │
│       ▼                                                             │
│  default.nix ──► Uses lib.packagesFromDirectoryRecursive            │
│       │          to auto-discover all plugins/<name>/package.nix    │
│       ▼                                                             │
│  mkScryptedPlugin ──► Generic Nix function (mk-scrypted-plugin.nix) │
│                       fetchurl → untar → extract plugin.zip         │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       Runtime (NixOS)                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  mares.automation.scrypted = {                                      │
│    enable = true;                                                   │
│    plugins = [ "nvr" "doorbird" "amcrest" ... ];                    │
│  };                                                                 │
│       │                                                             │
│       ▼                                                             │
│  scrypted-sideload.service ──► Runs after scrypted.service          │
│       │                        Waits for API ready (server only)    │
│       │                        POSTs each plugin via sideload API   │
│       ▼                                                             │
│  Scrypted ──► Plugins installed and running                         │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Plugin Discovery

Plugins are discovered via npm registry search:

```bash
curl 'https://registry.npmjs.org/-/v1/search?text=keywords:scrypted&size=250'
```

This returns ~130 packages with name and version. We then:
1. Filter to `@scrypted/*` scope only (official plugins)
2. Fetch individual package metadata for integrity hash
3. Skip plugins in `MANUAL_PLUGINS` (hand-maintained, e.g., openvino)
4. Skip plugins in `IGNORED_PLUGINS` (Python plugins not yet supported)

Result: ~55 Node.js plugins that are auto-packaged.

### Plugin Structure (npm)

All Node.js plugins follow an identical structure:

```
package/
├── package.json         # Metadata + scrypted config
├── tsconfig.json
├── README.md
└── dist/
    └── plugin.zip       # Pre-built webpack bundle
        ├── main.nodejs.js      # All deps bundled
        ├── main.nodejs.js.map
        ├── README.md
        └── sdk.json
```

Key insight: **No build step needed** - plugins ship pre-built. We just fetch and extract.

### Sideload API

Scrypted provides official REST endpoints for plugin sideloading:

| Endpoint                                                 | Method | Body           | Purpose                  |
| -------------------------------------------------------- | ------ | -------------- | ------------------------ |
| `/web/component/script/setup?npmPackage=@scrypted/xxx`   | POST   | package.json   | Register plugin metadata |
| `/web/component/script/deploy?npmPackage=@scrypted/xxx`  | POST   | plugin.zip     | Upload plugin code       |

### Authentication

Use localhost bypass (same as Home Assistant integration):

```nix
environment = {
  SCRYPTED_ADMIN_USERNAME = "admin";     # Auto-creates admin user
  SCRYPTED_ADMIN_ADDRESS = "127.0.0.1";  # Localhost gets admin access
};
```

When both env vars are set, requests from `127.0.0.1` are automatically authenticated as the admin user - no token needed. This is only enabled when `plugins` list is non-empty.

---

## Technical Specification

### 1. Package Structure

Following nixpkgs conventions (similar to PostgreSQL extensions, Pulumi plugins, OctoDNS providers):

```
packages/scrypted/
├── package.nix                        # Main scrypted server (existing)
└── plugins/
    ├── default.nix                    # Uses lib.packagesFromDirectoryRecursive
    ├── mk-scrypted-plugin.nix         # Generic builder (mkScryptedPlugin function)
    ├── update.sh                      # Generates package.nix files from npm
    └── plugins/                       # One directory per plugin
        ├── nvr/package.nix            # Auto-generated
        ├── doorbird/package.nix       # Auto-generated
        ├── amcrest/package.nix        # Auto-generated
        ├── ...                        # ~50 more auto-generated
        └── openvino/package.nix       # Manual (complex Python plugin)
```

Directory names match npm package names without the `@scrypted/` prefix (e.g., `nvr` for `@scrypted/nvr`).

### 2. Generic Plugin Builder

```nix
# mk-scrypted-plugin.nix
# Output: $out/package.json + $out/plugin.zip (for sideload API)
{ lib, stdenvNoCC, fetchurl }:

{
  pname,
  version,
  hash,
  meta ? {},
  passthru ? {},
  postInstall ? "",
  ...
}@args:

stdenvNoCC.mkDerivation ({
  pname = "scrypted-plugin-${pname}";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@scrypted/${pname}/-/${pname}-${version}.tgz";
    inherit hash;
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    tar -xzf $src --strip-components=1 -C $out package/package.json package/dist/plugin.zip
    mv $out/dist/plugin.zip $out/
    rmdir $out/dist
    runHook postInstall
  '';

  inherit postInstall;

  passthru = {
    pluginName = "@scrypted/${pname}";
    inherit version;
  } // passthru;

  meta = {
    description = "Scrypted plugin: ${pname}";
    homepage = "https://www.scrypted.app/";
    license = lib.licenses.asl20;
  } // meta;
} // removeAttrs args [ "pname" "version" "hash" "meta" "passthru" "postInstall" ])
```

Output contains only `package.json` and `plugin.zip` - exactly what the sideload API needs. The builder merges `passthru` so complex plugins (like OpenVINO) can add custom attributes.

### 3. Versions File (Auto-Generated)

```nix
# versions.nix - Auto-generated by update.sh
{
  # Node.js plugins (auto-generated)
  nvr = {
    version = "0.12.43";
    hash = "sha512-p+QYIgLMDB894hR3arpNRd3dy5rvEZ0TLBU/ZiGD52fnwkxv29X+7wrIJYb80ViRrrRaJw10fUlC1wiiZYQ6iA==";
  };
  doorbird = {
    version = "0.0.6";
    hash = "sha512-i6leO7zulJVHQNM0t589IH0xYP4Q8SS4lk7PFvn/p4dnmgQfG8MtciRJwOuYrLx/ypuZBjzdnkPfKiEjQ2ul6Q==";
  };
  # ... ~55 more plugins
}
```

### 4. Update Script

```bash
#!/usr/bin/env bash
# update.sh - Fetches all @scrypted plugins from npm and generates versions.nix

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSIONS_FILE="$SCRIPT_DIR/versions.nix"

echo "Fetching plugin list from npm..."
PLUGINS=$(curl -s 'https://registry.npmjs.org/-/v1/search?text=keywords:scrypted&size=250' \
  | jq -r '.objects[].package.name' \
  | grep '^@scrypted/' \
  | sed 's/@scrypted\///')

echo "Generating versions.nix..."
echo "# Auto-generated by update.sh - do not edit manually" > "$VERSIONS_FILE"
echo "{" >> "$VERSIONS_FILE"

for plugin in $PLUGINS; do
  echo "  Fetching @scrypted/$plugin..."
  
  DATA=$(curl -s "https://registry.npmjs.org/@scrypted/$plugin/latest" 2>/dev/null || echo "{}")
  
  VERSION=$(echo "$DATA" | jq -r '.version // empty')
  HASH=$(echo "$DATA" | jq -r '.dist.integrity // empty')
  RUNTIME=$(echo "$DATA" | jq -r '.scrypted.runtime // "node"')
  
  # Skip if missing data or Python plugin
  if [ -z "$VERSION" ] || [ -z "$HASH" ]; then
    echo "    Skipping (missing data)"
    continue
  fi
  
  if [ "$RUNTIME" = "python" ]; then
    echo "    Skipping (Python plugin)"
    continue
  fi
  
  echo "  $plugin = {" >> "$VERSIONS_FILE"
  echo "    version = \"$VERSION\";" >> "$VERSIONS_FILE"
  echo "    hash = \"$HASH\";" >> "$VERSIONS_FILE"
  echo "  };" >> "$VERSIONS_FILE"
done

echo "}" >> "$VERSIONS_FILE"

echo "Done! Generated versions for $(grep -c 'version =' "$VERSIONS_FILE") plugins."
```

### 5. Plugins Attrset

```nix
# plugins/default.nix
{ lib, callPackage, newScope }:

let
  versions = import ./versions.nix;
  mkScryptedPlugin = callPackage ./mk-scrypted-plugin.nix { };
  
  # Auto-generate packages from versions.nix
  nodePlugins = lib.mapAttrs (name: ver: mkScryptedPlugin {
    pname = name;
    inherit (ver) version hash;
  }) versions;

  # Manual packages
  openvino = callPackage ./openvino { };

in nodePlugins // {
  inherit openvino;
}
```

### 6. NixOS Module

```nix
# modules/automation/scrypted/default.nix (additions)
{ config, lib, pkgs, ... }:

let
  cfg = config.mares.automation.scrypted;
  plugins = pkgs.scrypted.plugins;
in {
  options.mares.automation.scrypted = {
    plugins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of Scrypted plugins to pre-install via sideloading";
      example = [ "nvr" "doorbird" "amcrest" "onvif" ];
    };
  };

  config = lib.mkIf (cfg.enable && cfg.plugins != []) {
    # Enable localhost admin access for sideloading
    # (added to existing environment config)
    systemd.services.scrypted.environment = {
      SCRYPTED_ADMIN_USERNAME = "nixos";
      SCRYPTED_ADMIN_ADDRESS = "127.0.0.1";
    };

    # Sideload service
    systemd.services.scrypted-sideload = {
      description = "Sideload Scrypted plugins";
      after = [ "scrypted.service" ];
      requires = [ "scrypted.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      path = [ pkgs.curl pkgs.jq ];

      script = let
        pluginPkgs = map (name: plugins.${name}) cfg.plugins;
        sideloadPlugin = pkg: ''
          echo "Sideloading ${pkg.pluginName}..."
          
          # Setup (register metadata)
          curl -sf -X POST \
            "https://127.0.0.1:10443/web/component/script/setup?npmPackage=${pkg.pluginName}" \
            -H "Content-Type: application/json" \
            -d @${pkg}/package.json \
            --insecure || echo "Setup failed for ${pkg.pluginName}"
          
          # Deploy (upload plugin.zip contents)
          # Note: plugin.zip is already extracted to $out, need to rezip or send files
          # TODO: Determine exact format needed
        '';
      in ''
        set -euo pipefail
        
        echo "Waiting for Scrypted API..."
        for i in {1..30}; do
          if curl -sf "https://127.0.0.1:10443/login" --insecure >/dev/null 2>&1; then
            echo "Scrypted API ready"
            break
          fi
          echo "Waiting... ($i/30)"
          sleep 2
        done
        
        ${lib.concatMapStrings sideloadPlugin pluginPkgs}
        
        echo "Sideload complete"
      '';
    };
  };
}
```

---

## Plugin Categories

### Fully Supported (Auto-Generated Node.js)

All ~55 plugins with `runtime != "python"` are auto-generated. Examples:

| Plugin            | Description                | Notes                    |
| ----------------- | -------------------------- | ------------------------ |
| nvr               | Scrypted NVR               | Closed source, but works |
| doorbird          | Doorbird doorbell          |                          |
| amcrest           | Amcrest cameras            |                          |
| onvif             | ONVIF cameras              |                          |
| rtsp              | RTSP streams               |                          |
| prebuffer-mixin   | Rebroadcast/prebuffer      |                          |
| snapshot          | Snapshot capture           |                          |
| objectdetector    | Video analysis coordinator |                          |
| webrtc            | WebRTC streaming           |                          |
| cloud             | Scrypted Cloud             | Needs internet for licensing |
| core              | Scrypted Core              |                          |
| homekit           | HomeKit bridge             |                          |
| google-home       | Google Home integration    |                          |
| alexa             | Alexa integration          |                          |

### Manual Package (Python)

| Plugin   | Description              | Status                                    |
| -------- | ------------------------ | ----------------------------------------- |
| openvino | OpenVINO object detection | Manual package, needs Python + HF models |

### Not Supported (Python - Require Internet)

| Plugin          | Description               |
| --------------- | ------------------------- |
| onnx            | ONNX object detection     |
| coreml          | CoreML object detection   |
| tensorflow-lite | TFLite object detection   |
| opencv          | OpenCV motion detection   |
| blink           | Blink cameras (Python)    |
| wyze            | Wyze cameras (Python)     |
| arlo            | Arlo cameras (Python)     |

---

## Implementation Status

### Phase 1: Package Infrastructure ✅

- [x] `packages/scrypted/plugins/mk-scrypted-plugin.nix` - Generic builder
- [x] `packages/scrypted/plugins/update.sh` - Generates `plugins/<name>/package.nix`
- [x] 59 auto-generated plugin packages
- [x] `packages/scrypted/plugins/default.nix` - Uses `packagesFromDirectoryRecursive`
- [x] Flake exposes `scrypted.plugins.*`
- [x] Test: `nix build .#scrypted.plugins.doorbird` ✓

### Phase 2: Sideload Module ✅

- [x] `plugins` option in `modules/automation/scrypted/common.nix`
- [x] Localhost admin env vars (when plugins enabled)
- [x] `scrypted-sideload.service` in `server.nix`
- [x] Waits for API, POSTs each plugin

### Phase 3: OpenVINO Integration ✅

- [x] OpenVINO uses `mkScryptedPlugin` as base with `postInstall` hook
- [x] `openvino/update.sh` uses `nurl` to auto-compute `modelsHash`
- [x] Client role uses tmpfiles for Python env + models symlinks
- [x] Main `update.sh` delegates to complex plugins via `COMPLEX_PLUGINS` list

### Phase 4: Testing 📋

- [x] Deploy to nvr-server-01
- [x] Verify plugins appear in Scrypted UI (dummy-switch tested successfully)
- [ ] Test OpenVINO plugin on worker nodes

---

## Usage Example

```nix
# hosts/nvr-server-01/default.nix
{ config, ... }:

{
  imports = [ ../../roles/scrypted-server.nix ];

  mares.automation.scrypted = {
    enable = true;
    role = "server";
    
    plugins = [
      # Core functionality
      "nvr"
      "core"
      "cloud"
      
      # Camera providers
      "doorbird"
      "amcrest"
      "onvif"
      "rtsp"
      
      # Streaming & processing
      "prebuffer-mixin"
      "snapshot"
      "objectdetector"
      "webrtc"
      
      # Integrations
      "homekit"
      "google-home"
      
      # Utilities
      "diagnostics"
      "dummy-switch"
    ];
  };
}
```

---

## Resolved Questions

1. **Sideload API format**: `/deploy` expects raw `plugin.zip` binary with `Content-Type: application/zip`. The server converts to base64 internally.

2. **Plugin updates**: Re-sideloading always overwrites - no version checking. Scrypted handles plugin restart.

3. **Worker nodes**: Workers get plugins via RPC from server. Only sideload on server.

4. **Idempotency**: Let Scrypted handle it - sideload service runs on every boot, Scrypted overwrites existing plugins.

5. **Models hash**: The `openvino/update.sh` uses `nurl -e` to automatically compute the HuggingFace models hash. This downloads ~2GB but eliminates manual hash updates. Falls back to existing hash on non-Linux.

---

## Success Criteria

- [x] `update.sh` generates valid plugin packages (~59 plugins)
- [x] `update.sh` delegates to complex plugins (openvino) via `COMPLEX_PLUGINS`
- [x] `nix build .#scrypted.plugins.<name>` works for any Node.js plugin
- [x] `mares.automation.scrypted.plugins = [...]` triggers sideload on boot
- [x] Sideloaded plugins appear in Scrypted UI (dummy-switch verified)
- [x] Plugins function correctly (dummy-switch verified)
- [ ] OpenVINO plugin works on worker nodes

---

## Appendix: Original OpenVINO-Only PRD

<details>
<summary>Click to expand original PRD (historical reference)</summary>

### Original Problem Statement

Scrypted's OpenVINO plugin downloads Python packages via pip and ML models from HuggingFace at runtime. NVR clients on isolated networks (firewall-blocked from internet) cannot complete these downloads, causing object detection to fail.

### Original Goals

- **Offline Operation**: Enable NVR clients to run object detection without internet access.
- **Reproducible Builds**: Pin all dependencies (OpenVINO, models) for consistent deployments.
- **Hardware Compatibility**: Use OpenVINO 2024.5.0 specifically for hardware compatibility.
- **Multi-Platform**: Support both x86_64-linux (production) and aarch64-linux (future-proofing).
- **Maintainability**: Provide update script to sync with upstream releases.

### Why It Was Abandoned (Initially)

1. **Maintenance Burden**: Scrypted moves fast, hash updates required constantly
2. **Incomplete Solution**: NVR (closed source) downloads libav at runtime
3. **Limited Scope**: Only OpenVINO needed special handling

### Why We're Reviving It (Revised)

The key insight: **automate the packaging** of simple Node.js plugins. Instead of manually maintaining each plugin, we:
1. Auto-fetch all plugins from npm registry
2. Auto-generate Nix packages
3. Single `update.sh` refreshes everything

This makes the maintenance burden acceptable.

</details>
