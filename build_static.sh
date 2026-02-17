#!/bin/bash
set -e

echo "Building static binaries for Crybot..."

# Build for AMD64
echo ""
echo "Building for AMD64..."
docker build . -f Dockerfile.static -t crybot-builder-amd64 \
  --platform linux/amd64

docker run --rm \
  -v "$PWD":/app \
  --user="$(id -u):$(id -g)" \
  crybot-builder-amd64 \
  /bin/sh -c "cd /app && shards build --without-development --release --static --no-debug '-Dpreview_mt' '-Dexecution_context' 'crybot'"

# Copy and compress the AMD64 binary
mkdir -p dist
cp bin/crybot dist/crybot-linux-amd64
upx --best --lzma dist/crybot-linux-amd64
echo "✓ Built: dist/crybot-linux-amd64 ($(du -h dist/crybot-linux-amd64 | cut -f1))"

# Build for ARM64 (optional - requires ARM host or proper emulation)
echo ""
echo "Building for ARM64..."
echo "Note: ARM64 build requires proper ARM64 host or CI environment."
echo "Skipping ARM64 build - can be built separately on ARM64 hardware."

# Show file sizes
echo ""
echo "Binary sizes:"
ls -lh dist/

echo ""
echo "Static binaries built successfully!"
echo "You can now ship these binaries - they have no external dependencies."
echo ""
echo "To build ARM64 binary, run on ARM64 hardware:"
echo "  docker buildx build --platform linux/arm64 -f Dockerfile.static -t crybot-builder-arm64 ."
