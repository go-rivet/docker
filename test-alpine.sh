#!/bin/bash
set -e

echo "========================================"
echo "🎯 Starting Container Tools Verification"
echo "========================================"

# Test Rivet
if command -v rivet >/dev/null 2>&1; then
    echo "✅ rivet: $(rivet --version 2>&1 || echo 'Installed')"
else
    echo "❌ rivet: Missing" && exit 1
fi

# Test Bash
echo "✅ bash:  $(bash --version | head -n 1)"

# Test Git
echo "✅ git:   $(git --version)"

# Test Curl
echo "✅ curl:  $(curl --version | head -n 1)"

# Test Make
echo "✅ make:  $(make --version | head -n 1)"

# Test jq
echo "✅ jq:    $(jq --version)"

# Test yq
echo "✅ yq:    $(yq --version | head -n 1)"

echo "========================================"
echo "🎉 All Alpine pipeline tools verified successfully!"
echo "========================================"
