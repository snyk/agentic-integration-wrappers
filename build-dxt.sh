#!/usr/bin/env bash
set -euo pipefail

# Build Claude Desktop Extension (dxt) from snyk-ls mcp_extension
# Usage: ./build-dxt.sh <version> <output_dir>

VERSION="${1}"
OUTPUT_DIR="${2}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR=$(mktemp -d)
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

# Update version in manifest.json
echo "Updating version in manifest.json to ${VERSION}..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/\"version\":[[:space:]]*\"[^\"]*\"/\"version\": \"${VERSION}\"/" "manifest.json"
else
    # Linux
    sed -i "s/\"version\":[[:space:]]*\"[^\"]*\"/\"version\": \"${VERSION}\"/" "manifest.json"
fi

# Build the dxt file
echo "Building dxt file..."
npx @anthropic-ai/dxt pack . "${OUTPUT_DIR}/snyk.dxt"

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