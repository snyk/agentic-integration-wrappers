#!/usr/bin/env bash
set -euo pipefail

# Build Claude Desktop Extension (dxt) from snyk-ls mcp_extension
# Usage: ./build-dxt.sh <version> <output_dir>

VERSION="${1}"
OUTPUT_DIR="${2}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR=$(mktemp -d)
LS_DIR="${TEMP_DIR}/snyk-ls"
CLI_DIR="${TEMP_DIR}/cli"

# Cleanup on exit
trap 'rm -rf "${TEMP_DIR}"' EXIT

echo "Building snyk.dxt with version: ${VERSION}"
echo "Output directory: ${OUTPUT_DIR}"

# Ensure output directory exists
mkdir -p "${OUTPUT_DIR}"

# Convert OUTPUT_DIR to absolute path
OUTPUT_DIR="$(cd "${OUTPUT_DIR}" && pwd)"

git clone --depth 1 https://github.com/snyk/cli "$CLI_DIR"

# Get snyk-ls commit hash from go.mod
pushd "$CLI_DIR/cliv2"
  SNYK_LS_VERSION=$(grep "github.com/snyk/snyk-ls" go.mod | head -1 | awk '{print $2}')
  echo "Using snyk-ls version: ${SNYK_LS_VERSION}"

  # Extract commit hash from version (format: v0.0.0-YYYYMMDDHHMMSS-COMMITSHORT)
  COMMIT_HASH=$(echo "${SNYK_LS_VERSION}" | sed 's/.*-//')
  echo "Using commit hash: ${COMMIT_HASH}"
popd

rm -rf "$CLI_DIR"

# Download snyk-ls source archive from GitHub
echo "Cloning snyk-ls ..."
git clone "https://github.com/snyk/snyk-ls" "$LS_DIR"
pushd "$LS_DIR"
  git reset --hard "${COMMIT_HASH}"
popd

# Verify mcp_extension exists
MCP_EXTENSION_DIR="${LS_DIR}/mcp_extension"
if [ ! -d "${MCP_EXTENSION_DIR}" ]; then
    echo "Error: mcp_extension directory not found in ${EXTRACTED_DIR}"
    exit 1
fi

# Download the logo
echo "Downloading Snyk logo..."
LOGO_URL="https://avatars.githubusercontent.com/u/211677698?v=4"
curl -L -o "${TEMP_DIR}/icon.png" "${LOGO_URL}"

# Copy mcp_extension to temp directory
cp -R "${MCP_EXTENSION_DIR}" "${TEMP_DIR}/mcp_extension"
rm -rf "${LS_DIR}"

# Make the copied files writable
chmod -R u+w "${TEMP_DIR}/mcp_extension"

# Copy the logo to the mcp_extension directory
cp "${TEMP_DIR}/icon.png" "${TEMP_DIR}/mcp_extension/icon.png"

# Update version in manifest.json
echo "Updating version in manifest.json to ${VERSION}..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/\"version\":[[:space:]]*\"[^\"]*\"/\"version\": \"${VERSION}\"/" "${TEMP_DIR}/mcp_extension/manifest.json"
else
    # Linux
    sed -i "s/\"version\":[[:space:]]*\"[^\"]*\"/\"version\": \"${VERSION}\"/" "${TEMP_DIR}/mcp_extension/manifest.json"
fi

# Ensure icon field is set correctly (if not already present)
echo "Checking icon field in manifest..."
if ! grep -q '"icon"' "${TEMP_DIR}/mcp_extension/manifest.json"; then
    echo "Adding icon field to manifest.json..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - add icon field before the last closing brace
        sed -i '' '$ s/}$/,\n  "icon": "icon.png"\n}/' "${TEMP_DIR}/mcp_extension/manifest.json"
    else
        # Linux
        sed -i '$ s/}$/,\n  "icon": "icon.png"\n}/' "${TEMP_DIR}/mcp_extension/manifest.json"
    fi
fi

# Build the dxt file
echo "Building dxt file..."
pushd "${TEMP_DIR}/mcp_extension"
  npx @anthropic-ai/dxt pack . "${OUTPUT_DIR}/snyk.dxt"
popd

# Create SHA256 checksum
pushd "${OUTPUT_DIR}"
  echo "Creating SHA256 checksum..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
      # macOS
      shasum -a 256 snyk.dxt > snyk.dxt.sha256
  else
      # Linux
      sha256sum snyk.dxt > snyk.dxt.sha256
  fi
popd

echo "Successfully built snyk.dxt"
echo "Output files:"
echo "  - ${OUTPUT_DIR}/snyk.dxt"
echo "  - ${OUTPUT_DIR}/snyk.dxt.sha256" 