#!/bin/bash
# build-dist.sh - Build RT extension distribution without RT installed
# Usage: ./tools/build-dist.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FAKE_RT_DIR="$REPO_ROOT/t/lib"

# Verify fake RT environment exists
if [[ ! -f "$FAKE_RT_DIR/RT.pm" ]]; then
    echo "Error: Fake RT environment not found at $FAKE_RT_DIR"
    exit 1
fi

cd "$REPO_ROOT"

# Clean up any previous build artifacts
rm -f Makefile MYMETA.* RT-Extension-*.tar.gz

# Generate Makefile using fake RT environment
echo "Generating Makefile with fake RT environment..."
RTHOME="$FAKE_RT_DIR" perl Makefile.PL

# Build the distribution
echo "Building distribution..."
make dist

# Cleanup build artifacts, keep META files and the tarball
rm -f Makefile MYMETA.*

echo ""
echo "Distribution built successfully!"
ls -lh RT-Extension-*.tar.gz
