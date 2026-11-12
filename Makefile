# Variables
IMAGE_NAME    ?= rivet
TAG           ?= local
RIVET_VERSION ?= main
RIVET_GOMOD_URL = https://raw.githubusercontent.com/go-rivet/rivet/$(RIVET_VERSION)/go.mod
GO_VERSION    := $(shell curl -sSL $(RIVET_GOMOD_URL) | grep -E '^go [0-9.]+' | awk '{print $$2}')
LOCAL_ARCH      := $(shell uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/;s/armv7l/arm/')
LOCAL_PLATFORM  := linux/$(LOCAL_ARCH)

.PHONY: build build-scratch build-distroless build-alpine run run-scratch run-distroless run-alpine test test-scratch test-distroless test-alpine clean help

default: help 

## help: Show this help message
help: 
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -h "^##" $(MAKEFILE_LIST) | sed -e 's/## //' | awk -F: '{printf "  %-15s %s\n", $$1, $$2}'

## build: Build the scratch, distroless, and Alpine images
build: build-scratch build-distroless build-alpine

## build-scratch: Build only the minimal scratch image
build-scratch: 
	@if [ -z "$(GO_VERSION)" ]; then \
		echo "Error: Could not retrieve Go version for branch/tag '$(RIVET_VERSION)' from remote repository."; \
		exit 1; \
	fi
	@echo "Building scratch image using Go version: $(GO_VERSION)"
	docker buildx build \
		-f Dockerfile.scratch \
		--platform $(LOCAL_PLATFORM) \
		--build-arg GO_VERSION=$(GO_VERSION) \
		--build-arg RIVET_VERSION=$(RIVET_VERSION) \
		-t $(IMAGE_NAME):$(TAG) \
		--load \
		.

## build-distroless: Build the minimal distroless runtime image
build-distroless:
	@if [ -z "$(GO_VERSION)" ]; then \
		echo "Error: Could not retrieve Go version for branch/tag '$(RIVET_VERSION)' from remote repository."; \
		exit 1; \
	fi
	docker buildx build \
		-f Dockerfile.scratch \
		--target distroless \
		--platform $(LOCAL_PLATFORM) \
		--build-arg GO_VERSION=$(GO_VERSION) \
		--build-arg RIVET_VERSION=$(RIVET_VERSION) \
		-t $(IMAGE_NAME):$(TAG)-distroless \
		--load \
		.

## build-alpine: Build only the utility-packed Alpine image
build-alpine: 
	@if [ -z "$(GO_VERSION)" ]; then \
		echo "Error: Could not retrieve Go version for branch/tag '$(RIVET_VERSION)' from remote repository."; \
		exit 1; \
	fi
	@echo "Building Alpine image using Go version: $(GO_VERSION)"
	docker buildx build \
		-f Dockerfile.alpine \
		--platform $(LOCAL_PLATFORM) \
		--build-arg GO_VERSION=$(GO_VERSION) \
		--build-arg RIVET_VERSION=$(RIVET_VERSION) \
		-t $(IMAGE_NAME):$(TAG)-alpine \
		--load \
		.

## run: Run and test all locally built images
run: run-scratch run-distroless run-alpine

## run-scratch: Test the scratch image execution
run-scratch: 
	@echo "Testing scratch container execution:"
	docker run --rm $(IMAGE_NAME):$(TAG) --version

## run-distroless: Test the distroless image execution
run-distroless:
	docker run --rm $(IMAGE_NAME):$(TAG)-distroless --version

## run-alpine: Test the alpine image execution
run-alpine: 
	@echo "Testing Alpine container execution:"
	docker run --rm $(IMAGE_NAME):$(TAG)-alpine rivet --version

## test: Run integration tests inside all containers
test: test-scratch test-distroless test-alpine

## test-scratch: Mount and verify the scratch container engine execution boundary
test-scratch:
	@echo "Running verification test inside Scratch image..."
	docker run --rm -v "$(CURDIR)/test-lua.yml:/workspace/Taskfile.yml:ro" -w /workspace $(IMAGE_NAME):$(TAG)

## test-distroless: Verify Lua and HTTPS Taskfile fetching
test-distroless:
	docker run --rm -v "$(CURDIR)/test-lua.yml:/workspace/Taskfile.yml:ro" $(IMAGE_NAME):$(TAG)-distroless
	docker run --rm $(IMAGE_NAME):$(TAG)-distroless --yes --taskfile https://raw.githubusercontent.com/go-rivet/rivet/a22891eeebba5b2b8df10aff643f3f3b90e9504d/pkg/rivet/testdata/includes_remote/first/second/Taskfile.yml --list-all

## test-alpine: Mount and execute the test script inside the hardened Alpine container
test-alpine:
	@echo "Running verification test script inside Alpine image..."
	docker run --rm -v $(PWD)/test-alpine.sh:/workspace/test-alpine.sh --entrypoint /bin/bash $(IMAGE_NAME):$(TAG)-alpine /workspace/test-alpine.sh alpine
	docker run --rm -v "$(CURDIR)/test-lua.yml:/workspace/Taskfile.yml:ro" $(IMAGE_NAME):$(TAG)-alpine rivet

## clean: Remove all locally built images and prune builder layers
clean: 
	@echo "Cleaning up local images..."
	docker rmi $(IMAGE_NAME):$(TAG) 2>/dev/null || true
	docker rmi $(IMAGE_NAME):$(TAG)-distroless 2>/dev/null || true
	docker rmi $(IMAGE_NAME):$(TAG)-alpine 2>/dev/null || true
	docker builder prune -f
