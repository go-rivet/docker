# Variables
IMAGE_NAME    ?= rivet
TAG           ?= local
RIVET_VERSION ?= main
RIVET_GOMOD_URL = https://raw.githubusercontent.com/go-rivet/rivet/$(RIVET_VERSION)/go.mod
GO_VERSION    := $(shell curl -sSL $(RIVET_GOMOD_URL) | grep -E '^go [0-9.]+' | awk '{print $$2}')

.PHONY: build run clean help

default: help 

## help: Show this help message
help: 
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/## //' | awk -F: '{printf "  %-15s %s\n", $$1, $$2}'


## build: Build the image for your current architecture and load it into Docker
build: 
	@if [ -z "$(GO_VERSION)" ]; then \
		echo "Error: Could not retrieve Go version for branch/tag '$(RIVET_VERSION)' from remote repository."; \
		exit 1; \
	fi
	docker buildx build \
		--build-arg GO_VERSION=$(GO_VERSION) \
		--build-arg RIVET_VERSION=$(RIVET_VERSION) \
		-t $(IMAGE_NAME):$(TAG) \
		--load \
		.

## run: Run the locally built image
run: 
	docker run --rm $(IMAGE_NAME):$(TAG) --version

## clean: Remove the locally built image
clean: 
	docker rmi $(IMAGE_NAME):$(TAG) 2>/dev/null || true
	docker builder prune -f

