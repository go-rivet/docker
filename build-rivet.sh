#!/bin/sh
set -eu

case "$TARGETOS/$TARGETARCH${TARGETVARIANT:+/$TARGETVARIANT}" in
    linux/amd64) zig_target=x86_64-linux-musl ;;
    linux/arm64|linux/arm64/v8) zig_target=aarch64-linux-musl ;;
    linux/arm/v7) zig_target=arm-linux-musleabihf; export GOARM=7 ;;
    *) echo "Unsupported target: $TARGETOS/$TARGETARCH${TARGETVARIANT:+/$TARGETVARIANT}" >&2; exit 1 ;;
esac

VERSION=$(git describe --tags --always --dirty 2>/dev/null || echo "v0.1.0-dev")
COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "none")
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
MODULE_PATH=github.com/go-rivet/rivet/internal/version

CGO_ENABLED=1 GOOS="$TARGETOS" GOARCH="$TARGETARCH" CC="zig cc -target $zig_target" \
    go build \
    -trimpath \
    -tags "netgo osusergo" \
    -ldflags "-s -w -extldflags '-static -s' \
              -X '${MODULE_PATH}.Version=${VERSION}' \
              -X '${MODULE_PATH}.CommitSHA=${COMMIT_SHA}' \
              -X '${MODULE_PATH}.BuildTime=${BUILD_TIME}'" \
    -o /build/rivet ./cmd/rivet
