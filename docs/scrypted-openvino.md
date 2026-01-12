# Scrypted OpenVINO Plugin Pre-provisioning

> **Type:** PRD | **Created:** 2025-01

## Overview

Create a Nix package that pre-provisions Python dependencies and ML models for the Scrypted OpenVINO plugin, enabling NVR clients without internet access to run object detection.

## Problem Statement

Scrypted's OpenVINO plugin downloads Python packages via pip and ML models from HuggingFace at runtime. NVR clients on isolated networks (firewall-blocked from internet) cannot complete these downloads, causing object detection to fail.

## Goals

- **Offline Operation**: Enable NVR clients to run object detection without internet access.
- **Reproducible Builds**: Pin all dependencies (OpenVINO, models) for consistent deployments.
- **Hardware Compatibility**: Use OpenVINO 2024.5.0 specifically for hardware compatibility.
- **Multi-Platform**: Support both x86_64-linux (production) and aarch64-linux (future-proofing).
- **Maintainability**: Provide update script to sync with upstream releases.

## Architecture

- **Package**: `pkgs.scryptedPlugins.openvino`
- **Integration**: Role-level `systemd.tmpfiles.rules` symlinks package into expected location.
- **Models Source**: HuggingFace repos `scrypted/plugin-models` and `openai/clip-vit-base-patch32`.

## Platform Support

| Platform       | Build | Deploy | Notes                                 |
|----------------|-------|--------|---------------------------------------|
| x86_64-linux   | Yes   | Yes    | Primary target (nvr-client-01/02)     |
| aarch64-linux  | Yes   | Yes    | Local dev on M2 Mac + future-proofing |
| aarch64-darwin | No    | N/A    | Can evaluate, but not build wheels    |
| x86_64-darwin  | No    | N/A    | Can evaluate, but not build wheels    |

## Technical Specification

### 1. Package Structure

```
packages/scrypted-plugins/
├── default.nix              # Exposes scryptedPlugins = { openvino = ...; }
└── openvino/
    ├── default.nix          # Main package definition
    └── update.sh            # Update script
```

### 2. Package Output

```
$out/
├── python-env/              # Python site-packages symlinks
│   ├── openvino/
│   ├── PIL/
│   ├── cv2/
│   ├── transformers/
│   └── ...
├── requirements.txt
├── requirements.installed.txt
├── requirements.scrypted.txt
├── requirements.scrypted.installed.txt
└── files/                   # ML models (~450MB)
    ├── scrypted_labels.txt
    ├── 120/openvino/
    ├── hf/models--openai--clip-vit-base-patch32/
    ├── v6/
    ├── v7/
    └── v8/
```

### 3. Version Management

All version-sensitive values marked with `# VERSION-PIN:` comments:

```nix
# VERSION-PIN: Sync with @scrypted/openvino npm package
# Check: curl -s "https://registry.npmjs.org/@scrypted/openvino/latest" | jq -r '.version'
openvinoPluginVersion = "0.1.188";

# VERSION-PIN: From plugin's requirements.txt - CRITICAL for hardware compatibility
# Check: https://github.com/koush/scrypted/blob/main/plugins/openvino/src/requirements.txt
# WARNING: See requirements.txt comments for hardware-specific issues
openvinoVersion = "2024.5.0";

# VERSION-PIN: OpenVINO wheel hashes per platform
# Check: curl -s "https://pypi.org/pypi/openvino/2024.5.0/json" | jq '.urls[] | select(.filename | contains("cp312")) | {filename, digests}'
openvinoWheelHashes = {
  x86_64-linux = "sha256-...";   # manylinux2014_x86_64
  aarch64-linux = "sha256-...";  # manylinux_2_31_aarch64
};

# VERSION-PIN: Sync with scrypted/plugin-models HuggingFace repo
# Check: curl -s "https://huggingface.co/api/models/scrypted/plugin-models" | jq -r '.sha'
modelsRevision = "ae940950a104bab848c61a82fd0ed82bef4cc663";

# VERSION-PIN: From Scrypted server source
# Check: grep SCRYPTED_PYTHON_VERSION in server/src/plugin/runtime/python-worker.ts
scryptedPythonVersion = "20240317";

# VERSION-PIN: Must match python312 package used
pythonMajorMinor = "3.12";
```

### 4. Implementation Components

#### Pinned OpenVINO Wheel Package (Multi-Platform)

```nix
openvino-2024 = python312.pkgs.buildPythonPackage rec {
  pname = "openvino";
  version = openvinoVersion;  # "2024.5.0"
  format = "wheel";
  src = fetchPypi {
    inherit pname version;
    format = "wheel";
    python = "cp312";
    abi = "cp312";
    platform = {
      x86_64-linux = "manylinux2014_x86_64";
      aarch64-linux = "manylinux_2_31_aarch64";
    }.${stdenv.hostPlatform.system} or (throw "Unsupported platform");
    hash = openvinoWheelHashes.${stdenv.hostPlatform.system}
      or (throw "No hash for platform");
  };
  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];
};
```

#### Python Environment

```nix
pythonEnv = python312.withPackages (ps: [
  openvino-2024          # Our pinned version
  ps.pillow              # nixpkgs version (compatible)
  ps.opencv4             # nixpkgs version (compatible)
  ps.transformers        # nixpkgs version (compatible)
  ps.huggingface-hub
  ps.ptpython
  ps.wheel
]);
```

#### Models Download (Fixed-Output Derivation)

```nix
models = stdenvNoCC.mkDerivation {
  pname = "scrypted-openvino-models";
  version = modelsRevision;
  nativeBuildInputs = [ python312 python312Packages.huggingface-hub cacert ];
  
  dontUnpack = true;
  buildPhase = ''
    export HOME=$TMPDIR
    export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt
    
    python3 << 'EOF'
    from huggingface_hub import snapshot_download
    import os
    
    out = os.environ["out"]
    
    # Download Scrypted plugin models
    snapshot_download(
      repo_id="scrypted/plugin-models",
      allow_patterns=["openvino/*"],
      local_dir=f"{out}/scrypted-plugin-models",
    )
    
    # Download CLIP model
    snapshot_download(
      repo_id="openai/clip-vit-base-patch32",
      local_dir=f"{out}/clip",
    )
    EOF
  '';
  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  outputHash = "sha256-...";  # VERSION-PIN: Update when models change
};
```

#### Combined Plugin Package

```nix
stdenvNoCC.mkDerivation {
  pname = "scrypted-plugin-openvino";
  version = openvinoPluginVersion;
  passthru = {
    pluginId = "@scrypted/openvino";
    updateScript = ./update.sh;
  };
  # ... build logic to combine pythonEnv + models + marker files
}
```

### 5. Role Integration

In `roles/nvr-client-openvino.nix` (or similar):

```nix
{ config, pkgs, lib, ... }:
let
  # VERSION-PIN: Python version must match python312 package
  pythonMajorMinor = "3.12";
  
  # VERSION-PIN: From Scrypted server/src/plugin/runtime/python-worker.ts
  scryptedPythonVersion = "20240317";
  
  # Platform-specific arch string
  platformArch = {
    x86_64-linux = "x86_64";
    aarch64-linux = "aarch64";
  }.${pkgs.stdenv.hostPlatform.system} or (throw "Unsupported platform");
  
  pythonPlatformDir = "python${pythonMajorMinor}-Linux-${platformArch}-${scryptedPythonVersion}";
  
  openvino = pkgs.scryptedPlugins.openvino;
  pluginPath = "${config.mares.services.scrypted.installPath}/volume/plugins/${openvino.pluginId}";
in
{
  mares.services.scrypted.enable = true;
  
  systemd.tmpfiles.rules = [
    "L+ ${pluginPath}/${pythonPlatformDir} - - - - ${openvino}/python-env"
    "L+ ${pluginPath}/files - - - - ${openvino}/files"
  ];
}
```

### 6. Update Script

```bash
#!/usr/bin/env bash
# packages/scrypted-plugins/openvino/update.sh
set -eu -o pipefail

echo "=== Checking upstream versions ==="

# 1. Plugin version from npm
PLUGIN_VERSION=$(curl -s "https://registry.npmjs.org/@scrypted/openvino/latest" | jq -r '.version')
echo "Plugin version: $PLUGIN_VERSION"

# 2. OpenVINO version from requirements.txt
REQUIREMENTS_URL="https://raw.githubusercontent.com/koush/scrypted/main/plugins/openvino/src/requirements.txt"
OPENVINO_VERSION=$(curl -s "$REQUIREMENTS_URL" | grep "^openvino==" | cut -d'=' -f3)
echo "OpenVINO version: $OPENVINO_VERSION"

# 3. Models repo SHA
MODELS_SHA=$(curl -s "https://huggingface.co/api/models/scrypted/plugin-models" | jq -r '.sha')
echo "Models SHA: $MODELS_SHA"

# 4. Scrypted Python version
PYTHON_VERSION_URL="https://raw.githubusercontent.com/koush/scrypted/main/server/src/plugin/runtime/python-worker.ts"
SCRYPTED_PYTHON_VERSION=$(curl -s "$PYTHON_VERSION_URL" | grep "SCRYPTED_PYTHON_VERSION:" | grep -oP "'\\K[^']+")
echo "Scrypted Python version: $SCRYPTED_PYTHON_VERSION"

echo ""
echo "=== VERSION-PIN values to update ==="
echo "openvinoPluginVersion = \"$PLUGIN_VERSION\";"
echo "openvinoVersion = \"$OPENVINO_VERSION\";"
echo "modelsRevision = \"$MODELS_SHA\";"
echo "scryptedPythonVersion = \"$SCRYPTED_PYTHON_VERSION\";"
echo ""
echo "After updating, rebuild to get new hashes from error messages."
```

## Implementation Plan

1. **Create Package Structure**: Set up `packages/scrypted-plugins/` directory.
2. **Implement OpenVINO Package**: Build pinned wheel package with multi-platform support.
3. **Implement Models Derivation**: Fixed-output derivation for HuggingFace downloads.
4. **Create Combined Package**: Merge python-env, models, and marker files.
5. **Expose in Flake**: Add `scryptedPlugins` to flake outputs.
6. **Update Role**: Add tmpfiles rules to NVR client role.
7. **Create Update Script**: Script to check upstream versions.
8. **Test & Deploy**: Build, deploy to nvr-client-02, verify object detection.

## Files to Create/Modify

| File                                            | Action | Description                    |
|-------------------------------------------------|--------|--------------------------------|
| `packages/scrypted-plugins/default.nix`         | Create | Exposes scryptedPlugins set    |
| `packages/scrypted-plugins/openvino/default.nix`| Create | Main package definition        |
| `packages/scrypted-plugins/openvino/update.sh`  | Create | Update script                  |
| `roles/nvr-client.nix` (or similar)             | Modify | Add tmpfiles rules             |
| `flake.nix` or overlay                          | Modify | Expose scryptedPlugins         |

## Testing Plan

1. **Build locally (aarch64)**: `nix build .#scryptedPlugins.openvino`
2. **Build for target (x86_64)**: Build on remote builder or deploy target.
3. **Deploy**: Apply to nvr-client-02 (currently broken).
4. **Verify symlinks**: `ls -la /var/lib/scrypted/volume/plugins/@scrypted/openvino/`
5. **Verify logs**: Should show "requirements.txt (up to date)".
6. **Verify detection**: Test camera feeds for object detection.

## Known Limitations

1. **Read-only files directory**: If Scrypted writes to `files/` at runtime (lock files), symlink may fail. Fallback: symlink subdirectories only, keep parent writable.
2. **Manual hash updates**: After version bump, rebuild to get new hashes from error messages.
3. **Darwin builds**: Cannot build the wheel packages on macOS directly - use Linux builder.

## Success Criteria

- [ ] `nix build .#scryptedPlugins.openvino` succeeds on x86_64-linux.
- [ ] Symlinks are created at expected paths on nvr-client-02.
- [ ] Scrypted logs show "requirements.txt (up to date)" instead of pip errors.
- [ ] Object detection works on camera feeds.
- [ ] Update script correctly reports upstream versions.
