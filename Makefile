SHELL := bash

PROJECT := ml-bridge

VERSION := $(shell cat VERSION 2>/dev/null || echo "1.0.0")

# Nuke Configuration for DNEG
NUKE_VERSION := 14.1v4
NUKE_INSTALL_PATH := /usr/local/Nuke$(NUKE_VERSION)

# Build Configuration
BUILD_DIR := build
BUILD_TYPE := Release
CMAKE_GENERATOR := "Unix Makefiles"

# Plugin output
PLUGIN_NAME := ImageBridge.so
PLUGIN_OUTPUT := $(BUILD_DIR)/$(PLUGIN_NAME)

.PHONY: help
help: ## Show available commands
	@echo ""
	@echo "Please use 'make <target>' where <target> is one of:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: check
check: ## Check build environment
	@printf "\n\033[36m--- $@: Checking Build Environment ---\033[0m\n"
	@if [ ! -d "$(NUKE_INSTALL_PATH)" ]; then \
		echo "ERROR: Nuke not found at $(NUKE_INSTALL_PATH)"; \
		echo "Set NUKE_INSTALL_PATH in Makefile or environment"; \
		exit 1; \
	fi
	@if [ ! -f "$(NUKE_INSTALL_PATH)/libDDImage.so" ]; then \
		echo "ERROR: DDImage library not found"; \
		exit 1; \
	fi
	@if [ ! -d "src" ]; then \
		echo "ERROR: src/ directory not found"; \
		echo "Expected structure: src/ImageBridge.{cpp,h}"; \
		exit 1; \
	fi
	@if [ ! -f "src/ImageBridge.cpp" ] || [ ! -f "src/ImageBridge.h" ]; then \
		echo "ERROR: Source files not found in src/"; \
		echo "Required: src/ImageBridge.cpp and src/ImageBridge.h"; \
		exit 1; \
	fi
	@echo "✓ Nuke installation: $(NUKE_INSTALL_PATH)"
	@echo "✓ Source directory: src/"
	@echo "✓ Source files: ImageBridge.cpp, ImageBridge.h"
	@echo "✓ Build directory: $(BUILD_DIR)"
	@echo "✓ Build configuration OK"

.PHONY: configure
configure: check ## Configure CMake build
	@printf "\n\033[36m--- $@: Configuring Build ---\033[0m\n"
	mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && cmake \
		-G $(CMAKE_GENERATOR) \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
		-DNUKE_INSTALL_PATH=$(NUKE_INSTALL_PATH) \
		..

.PHONY: build
build: configure ## Build the plugin
	@printf "\n\033[36m--- $@: Building ImageBridge Plugin ---\033[0m\n"
	cmake --build $(BUILD_DIR) --config $(BUILD_TYPE) -- -j$$(nproc)
	@if [ -f "$(PLUGIN_OUTPUT)" ]; then \
		echo ""; \
		echo "✓ Plugin built successfully: $(PLUGIN_OUTPUT)"; \
		ls -lh $(PLUGIN_OUTPUT); \
	else \
		echo "ERROR: Plugin build failed"; \
		exit 1; \
	fi

.PHONY: install
install: build ## Install plugin to ~/.nuke
	@printf "\n\033[36m--- $@: Installing Plugin ---\033[0m\n"
	mkdir -p ~/.nuke/plugins/$(PROJECT)
	cp $(PLUGIN_OUTPUT) ~/.nuke/plugins/$(PROJECT)/
	@echo "✓ Installed to: ~/.nuke/plugins/$(PROJECT)/$(PLUGIN_NAME)"
	@echo ""
	@echo "Add to ~/.nuke/init.py:"
	@echo "  import nuke"
	@echo "  nuke.pluginAddPath('~/.nuke/plugins/$(PROJECT)')"

.PHONY: install-shared
install-shared: build ## Install plugin to shared location
	@printf "\n\033[36m--- $@: Installing Plugin to Shared Location ---\033[0m\n"
	@if [ -z "$(SHARED_PLUGIN_PATH)" ]; then \
		echo "ERROR: SHARED_PLUGIN_PATH not set"; \
		echo "Usage: make install-shared SHARED_PLUGIN_PATH=/path/to/shared/plugins"; \
		exit 1; \
	fi
	mkdir -p $(SHARED_PLUGIN_PATH)/$(PROJECT)/$(VERSION)
	cp $(PLUGIN_OUTPUT) $(SHARED_PLUGIN_PATH)/$(PROJECT)/$(VERSION)/
	@echo "✓ Installed to: $(SHARED_PLUGIN_PATH)/$(PROJECT)/$(VERSION)"

.PHONY: test
test: build ## Run basic plugin test
	@printf "\n\033[36m--- $@: Testing Plugin ---\033[0m\n"
	@if [ ! -f "$(PLUGIN_OUTPUT)" ]; then \
		echo "ERROR: Plugin not built"; \
		exit 1; \
	fi
	@echo "Checking plugin format..."
	@if file $(PLUGIN_OUTPUT) | grep -q "ELF 64-bit LSB shared object"; then \
		echo "✓ Plugin is valid 64-bit shared library"; \
	else \
		echo "ERROR: Invalid plugin format"; \
		exit 1; \
	fi
	@echo "Checking dependencies..."
	@if ldd $(PLUGIN_OUTPUT) | grep -q "not found"; then \
		echo "ERROR: Missing dependencies:"; \
		ldd $(PLUGIN_OUTPUT) | grep "not found"; \
		exit 1; \
	else \
		echo "✓ All dependencies satisfied"; \
		ldd $(PLUGIN_OUTPUT) | grep -E "(DDImage|libstdc)"; \
	fi
	@echo "✓ Basic tests passed"

.PHONY: clean
clean: ## Remove build artifacts
	@printf "\n\033[36m--- $@: Cleaning Build Directory ---\033[0m\n"
	rm -rf $(BUILD_DIR)
	find . -name '*.pyc' -delete
	find . -name '__pycache__' -delete
	find . -name '*~' -delete
	@echo "✓ Clean complete"

.PHONY: distclean
distclean: clean ## Remove all generated files
	@printf "\n\033[36m--- $@: Deep Clean ---\033[0m\n"
	rm -rf dist/
	rm -rf *.egg-info
	find . -name '.DS_Store' -delete

.PHONY: rebuild
rebuild: clean build ## Clean and rebuild

.PHONY: info
info: ## Display build information
	@echo ""
	@echo "Project: $(PROJECT) v$(VERSION)"
	@echo "Purpose: Bridge between Nuke viewer and external ML servers (e.g., ComfyUI)"
	@echo ""
	@echo "Configuration:"
	@echo "  Nuke Version: $(NUKE_VERSION)"
	@echo "  Nuke Path:    $(NUKE_INSTALL_PATH)"
	@echo "  Build Type:   $(BUILD_TYPE)"
	@echo "  Plugin:       $(PLUGIN_NAME)"
	@echo "  Source Dir:   src/"
	@echo ""
	@echo "Build Status:"
	@if [ -d "$(BUILD_DIR)" ]; then \
		echo "  Build Dir:    EXISTS"; \
	else \
		echo "  Build Dir:    NOT CONFIGURED"; \
	fi
	@if [ -f "$(PLUGIN_OUTPUT)" ]; then \
		echo "  Plugin:       BUILT"; \
		ls -lh $(PLUGIN_OUTPUT); \
	else \
		echo "  Plugin:       NOT BUILT"; \
	fi
	@echo ""
	@echo "Source Files:"
	@if [ -d "src" ]; then \
		ls -lh src/*.{cpp,h} 2>/dev/null || echo "  No source files found in src/"; \
	else \
		echo "  src/ directory not found"; \
	fi
	@echo ""
	@echo "Note: This plugin only handles viewer→knob bridging."
	@echo "      External ML server (e.g., ComfyUI) must be run separately."

.PHONY: all
all: check build test ## Run full build and test

# Development helpers
.PHONY: watch
watch: ## Watch for changes and rebuild
	@printf "\n\033[36m--- $@: Watching for changes ---\033[0m\n"
	@echo "Requires: inotify-tools (apt install inotify-tools)"
	@while true; do \
		inotifywait -r -e modify,create,delete src/ CMakeLists.txt 2>/dev/null && \
		make build; \
	done