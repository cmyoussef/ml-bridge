SHELL := bash

PROJECT := ml-bridge
VERSION := 1.0.0
BUILD_DIR := build
PLUGIN_NAME := ImageBridge

# CMake configuration
CMAKE := cmake
CMAKE_FLAGS := -DCMAKE_BUILD_TYPE=Release

.PHONY: help
help: ## Show available commands
	@echo ""
	@echo "Please use 'make <target>' where <target> is one of:"
	@grep -E '^[a-zA-Z_\(\)\$$[:space:]-]+:.*?## .*$$' $(MAKEFILE_LIST) | sed -r 's/[:space:]*\$$\([a-zA-Z_-]+\)//' | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

.PHONY: configure
configure: ## Configure the build with CMake
	@printf "\n\033[36m--- $@: Configuring Build ---\033[0m\n"
	mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && $(CMAKE) $(CMAKE_FLAGS) ..

.PHONY: build
build: configure ## Build the ImageBridge plugin
	@printf "\n\033[36m--- $@: Building $(PLUGIN_NAME) ---\033[0m\n"
	cd $(BUILD_DIR) && $(MAKE)

.PHONY: install
install: build ## Install the plugin
	@printf "\n\033[36m--- $@: Installing $(PLUGIN_NAME) ---\033[0m\n"
	cd $(BUILD_DIR) && $(MAKE) install

.PHONY: clean
clean: ## Remove build artifacts
	@printf "\n\033[36m--- $@: Cleaning Build Directory ---\033[0m\n"
	rm -rf $(BUILD_DIR)
	find . -name '*.o' -delete
	find . -name '*.so' -delete
	find . -name '*~' -delete

.PHONY: rebuild
rebuild: clean build ## Clean and rebuild

.PHONY: dist
dist: build ## Create distribution package
	@printf "\n\033[36m--- $@: Creating Distribution ---\033[0m\n"
	git tag v$(VERSION)
	git push origin v$(VERSION)

.PHONY: testrelease
testrelease: ## Put distributed plugin into testrelease
	@printf "\n\033[36m--- $@: Create and Install a New Version to SITE ---\033[0m\n"
	testrelease --bob-only dneg_nuke_package__$(PROJECT) $(VERSION)