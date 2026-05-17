# Variables
IMAGE_NAME    ?= rivet
TAG           ?= local
RIVET_VERSION ?= main
RIVET_GOMOD_URL = https://raw.githubusercontent.com/go-rivet/rivet/$(RIVET_VERSION)/go.mod
GO_VERSION    := $(shell curl -sSL $(RIVET_GOMOD_URL) | grep -E '^go [0-9.]+' | awk '{print $$2}')
LOCAL_ARCH      := $(shell uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/;s/armv7l/arm/')
LOCAL_PLATFORM  := linux/$(LOCAL_ARCH)

.PHONY: build build-scratch build-alpine run run-scratch run-alpine test test-scratch test-alpine clean help

default: help 

## help: Show this help message
help: 
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -h "^##" $(MAKEFILE_LIST) | sed -e 's/## //' | awk -F: '{printf "  %-15s %s\n", $$1, $$2}'

## build: Build both the scratch and alpine images
build: build-scratch build-alpine

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

## run: Run and test both locally built images
run: run-scratch run-alpine

## run-scratch: Test the scratch image execution
run-scratch: 
	@echo "Testing scratch container execution:"
	docker run --rm $(IMAGE_NAME):$(TAG) --version

## run-alpine: Test the alpine image execution
run-alpine: 
	@echo "Testing Alpine container execution:"
	docker run --rm $(IMAGE_NAME):$(TAG)-alpine rivet --version

## test: Run advanced integration tools verification tests inside both containers
test: test-scratch test-alpine

## test-scratch: Mount and verify the scratch container engine execution boundary
test-scratch:
	@echo "Running verification test inside Scratch image..."
	docker run --rm $(IMAGE_NAME):$(TAG) --version

## test-alpine: Mount and execute the test script inside the hardened Alpine container
test-alpine:
	@echo "Running verification test script inside Alpine image..."
	docker run --rm -v $(PWD)/test-alpine.sh:/workspace/test-alpine.sh --entrypoint /bin/bash $(IMAGE_NAME):$(TAG)-alpine /workspace/test-alpine.sh alpine

## clean: Remove all locally built images and prune builder layers
clean: 
	@echo "Cleaning up local images..."
	docker rmi $(IMAGE_NAME):$(TAG) 2>/dev/null || true
	docker rmi $(IMAGE_NAME):$(TAG)-alpine 2>/dev/null || true
	docker builder prune -f
