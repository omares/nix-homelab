#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix nurl coreutils

# Update script for scrypted-plugin-openvino
# Regenerates versions.nix with latest versions from upstream sources.
#
# Usage: ./update.sh [--system <system>]
#
# Options:
#   --system <system>   Target system for models hash (e.g., x86_64-linux)
#                       Useful on macOS to use a remote Linux builder

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# Parse arguments
TARGET_SYSTEM=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --system)
      TARGET_SYSTEM="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "==> Fetching latest versions..."

# 1. Plugin version and npm integrity hash
PLUGIN_INFO=$(curl -s "https://registry.npmjs.org/@scrypted/openvino/latest")
PLUGIN_VERSION=$(echo "$PLUGIN_INFO" | jq -r '.version')
PLUGIN_HASH=$(echo "$PLUGIN_INFO" | jq -r '.dist.integrity')
echo "    @scrypted/openvino: $PLUGIN_VERSION"

# 2. OpenVINO version from Scrypted's requirements.txt (uncommented line)
OPENVINO_VERSION=$(curl -s "https://raw.githubusercontent.com/koush/scrypted/main/plugins/openvino/src/requirements.txt" \
  | grep -E '^openvino==' | sed 's/openvino==//')
echo "    OpenVINO: $OPENVINO_VERSION"

# 3. OpenVINO wheel info from PyPI
WHEEL_INFO=$(curl -s "https://pypi.org/pypi/openvino/${OPENVINO_VERSION}/json")
WHEEL_BUILD=$(echo "$WHEEL_INFO" | jq -r '[.urls[] | select(.filename | test("cp312.*manylinux"))][0].filename' \
  | grep -oE '[0-9]+-cp312' | sed 's/-cp312//')
X86_HASH=$(echo "$WHEEL_INFO" | jq -r '.urls[] | select(.filename | test("cp312.*manylinux2014_x86_64")) | .digests.sha256')
ARM_HASH=$(echo "$WHEEL_INFO" | jq -r '.urls[] | select(.filename | test("cp312.*manylinux_2_31_aarch64")) | .digests.sha256')
echo "    OpenVINO wheel build: $WHEEL_BUILD"

# Validate we got both hashes
if [ -z "$X86_HASH" ] || [ -z "$ARM_HASH" ]; then
  echo "ERROR: Could not fetch wheel hashes for OpenVINO $OPENVINO_VERSION"
  echo "       x86_64-linux: $X86_HASH"
  echo "       aarch64-linux: $ARM_HASH"
  exit 1
fi

# 4. openvino-telemetry from PyPI
TELEMETRY_INFO=$(curl -s "https://pypi.org/pypi/openvino-telemetry/json")
TELEMETRY_VERSION=$(echo "$TELEMETRY_INFO" | jq -r '.info.version')
TELEMETRY_HASH_RAW=$(curl -s "https://pypi.org/pypi/openvino-telemetry/${TELEMETRY_VERSION}/json" \
  | jq -r '.urls[] | select(.filename | test("py3-none-any")) | .digests.sha256')
TELEMETRY_HASH=$(nix hash convert --hash-algo sha256 --to sri "$TELEMETRY_HASH_RAW")
echo "    openvino-telemetry: $TELEMETRY_VERSION"

# 5. numpy override (openvino requires numpy<2.2.0)
# Find the latest numpy version compatible with openvino's constraint
NUMPY_COMPAT_VERSION=$(curl -s "https://pypi.org/pypi/numpy/json" \
  | jq -r '[.releases | keys[] | select(startswith("2.1."))]| sort | last // empty')
if [ -z "$NUMPY_COMPAT_VERSION" ]; then
  echo "    Warning: No compatible numpy 2.1.x found, preserving existing"
  NUMPY_COMPAT_VERSION=$(nix eval --raw -f ./versions.nix numpyVersion 2>/dev/null || echo "2.1.3")
  NUMPY_HASH_X86=$(nix eval --raw -f ./versions.nix numpyHashes.x86_64-linux 2>/dev/null || echo "")
  NUMPY_HASH_ARM=$(nix eval --raw -f ./versions.nix numpyHashes.aarch64-linux 2>/dev/null || echo "")
  NUMPY_PLATFORM_X86=$(nix eval --raw -f ./versions.nix numpyWheelPlatforms.x86_64-linux 2>/dev/null || echo "")
  NUMPY_PLATFORM_ARM=$(nix eval --raw -f ./versions.nix numpyWheelPlatforms.aarch64-linux 2>/dev/null || echo "")
else
  echo "    numpy (compat): $NUMPY_COMPAT_VERSION"
  NUMPY_INFO=$(curl -s "https://pypi.org/pypi/numpy/${NUMPY_COMPAT_VERSION}/json")
  NUMPY_HASH_X86_RAW=$(echo "$NUMPY_INFO" | jq -r '.urls[] | select(.filename | test("cp312.*manylinux.*x86_64.*\\.whl")) | .digests.sha256' | head -1)
  NUMPY_HASH_ARM_RAW=$(echo "$NUMPY_INFO" | jq -r '.urls[] | select(.filename | test("cp312.*manylinux.*aarch64.*\\.whl")) | .digests.sha256' | head -1)
  NUMPY_WHEEL_X86=$(echo "$NUMPY_INFO" | jq -r '.urls[] | select(.filename | test("cp312.*manylinux.*x86_64.*\\.whl")) | .filename' | head -1)
  NUMPY_WHEEL_ARM=$(echo "$NUMPY_INFO" | jq -r '.urls[] | select(.filename | test("cp312.*manylinux.*aarch64.*\\.whl")) | .filename' | head -1)
  # Extract platform tag from wheel filename: numpy-VER-cp312-cp312-<PLATFORM>.whl
  NUMPY_PLATFORM_X86=$(echo "$NUMPY_WHEEL_X86" | sed 's/.*-cp312-cp312-\(.*\)\.whl/\1/')
  NUMPY_PLATFORM_ARM=$(echo "$NUMPY_WHEEL_ARM" | sed 's/.*-cp312-cp312-\(.*\)\.whl/\1/')
  NUMPY_HASH_X86="sha256:$NUMPY_HASH_X86_RAW"
  NUMPY_HASH_ARM="sha256:$NUMPY_HASH_ARM_RAW"
fi

# 6. Fetch models hash (downloads ~2GB from HuggingFace)
echo "==> Fetching models hash (this may take a while)..."
REPO_ROOT="$(git rev-parse --show-toplevel)"

# Use nurl to compute hash; NIX_CONFIG sets target system for remote builders
SYSTEM_FOR_HASH="${TARGET_SYSTEM:-x86_64-linux}"
NURL_EXPR="(builtins.getFlake (toString ${REPO_ROOT})).packages.${SYSTEM_FOR_HASH}.scrypted.plugins.openvino.models"

if MODELS_HASH=$(NIX_CONFIG="system = ${SYSTEM_FOR_HASH}" nurl -e "$NURL_EXPR" 2>/dev/null); then
  echo "    Models hash: $MODELS_HASH"
else
  CURRENT_MODELS_HASH=$(nix eval --raw -f ./versions.nix modelsHash 2>/dev/null || echo "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=")
  echo "    Warning: Could not compute models hash"
  echo "    Preserving existing: $CURRENT_MODELS_HASH"
  MODELS_HASH="$CURRENT_MODELS_HASH"
fi

echo ""
echo "==> Writing versions.nix..."

cat > versions.nix << EOF
# Auto-generated by update.sh - do not edit manually
{
  # Plugin version (@scrypted/openvino)
  version = "$PLUGIN_VERSION";
  # npm integrity hash
  hash = "$PLUGIN_HASH";

  # OpenVINO Python package (from Scrypted requirements.txt)
  openvinoVersion = "$OPENVINO_VERSION";
  openvinoWheelBuild = "$WHEEL_BUILD";
  openvinoHashes = {
    x86_64-linux = "sha256:$X86_HASH";
    aarch64-linux = "sha256:$ARM_HASH";
  };

  # openvino-telemetry dependency
  openvinoTelemetryVersion = "$TELEMETRY_VERSION";
  openvinoTelemetryHash = "$TELEMETRY_HASH";

  # numpy override (openvino requires numpy<2.2.0)
  numpyVersion = "$NUMPY_COMPAT_VERSION";
  numpyHashes = {
    x86_64-linux = "$NUMPY_HASH_X86";
    aarch64-linux = "$NUMPY_HASH_ARM";
  };
  numpyWheelPlatforms = {
    x86_64-linux = "$NUMPY_PLATFORM_X86";
    aarch64-linux = "$NUMPY_PLATFORM_ARM";
  };

  # HuggingFace models (scrypted/plugin-models, openai/clip-vit-base-patch32, koushd/clip)
  modelsHash = "$MODELS_HASH";
}
EOF

echo "==> Done!"
echo ""
echo "Updated versions.nix:"
echo "  - version: $PLUGIN_VERSION"
echo "  - hash: $PLUGIN_HASH"
echo "  - openvinoVersion: $OPENVINO_VERSION"
echo "  - openvinoWheelBuild: $WHEEL_BUILD"
echo "  - openvinoTelemetryVersion: $TELEMETRY_VERSION"
echo "  - numpyVersion: $NUMPY_COMPAT_VERSION"
echo "  - modelsHash: $MODELS_HASH"
