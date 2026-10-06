# Copyright 2026 the contributors to the Coraza WAF downstream build.
# SPDX-License-Identifier: Apache-2.0
# Modified in this fork to build and package the Coraza WAF dynamic module.

ROOT := $(shell git rev-parse --show-toplevel)
WAF_DIR := $(ROOT)/downstream/waf
GO_VERSION := $(shell sed -ne 's/^go //gp' $(WAF_DIR)/go.mod)
WAF_BUILD_TAGS := coraza.rule.case_sensitive_args_keys,coraza.rule.no_regex_multiline,coraza.rule.mandatory_rule_id_check
RELEASE_VERSION ?= dev
ENVOY_VERSION ?= v1.38.0
SOURCE_REPO ?=
SOURCE_LABEL_ARG = $(if $(strip $(SOURCE_REPO)),--label=org.opencontainers.image.source=$(SOURCE_REPO),)
BUILT_REVISION ?= $(shell git -C $(ROOT) rev-parse HEAD)
BUILD_TREE_STATE := $(if $(strip $(shell git -C $(ROOT) status --porcelain --untracked-files=normal)),dirty,clean)
UPSTREAM_BASE := $(shell cat $(WAF_DIR)/UPSTREAM_BASE 2>/dev/null)
UPSTREAM_BASE_TAG ?= $(shell git -C $(ROOT) for-each-ref --format='%(refname) %(objectname) %(*objectname)' refs/tags/extensions/composer | awk -v base=$(UPSTREAM_BASE) '$$2 == base || $$3 == base { ref=$$1; sub(/^refs\/tags\//, "", ref); print ref; exit }')
LIBRARY_IMAGE ?= coraza-waf:$(RELEASE_VERSION)-$(ENVOY_VERSION)

.PHONY: build demo generate-third-party-notices check-third-party-notices validate-base-tag build-docker-library

build:
	cd $(WAF_DIR) && mkdir -p build
	cd $(WAF_DIR) && CGO_ENABLED=1 GOFLAGS="-mod=readonly -tags=$(WAF_BUILD_TAGS)" go build -trimpath -buildmode=c-shared -o build/libcoraza_waf.so .

demo: build
	$(WAF_DIR)/scripts/check-envoy-waf.sh $(WAF_DIR)/build/libcoraza_waf.so $(ENVOY_VERSION)

generate-third-party-notices:
	cd $(WAF_DIR) && GO_VERSION="$(GO_VERSION)" WAF_BUILD_TAGS="$(WAF_BUILD_TAGS)" LICENSE_PLATFORMS="linux/amd64 linux/arm64" ./scripts/generate-third-party-notices.sh

check-third-party-notices:
	cd $(WAF_DIR) && GO_VERSION="$(GO_VERSION)" WAF_BUILD_TAGS="$(WAF_BUILD_TAGS)" LICENSE_PLATFORMS="linux/amd64 linux/arm64" ./scripts/check-third-party-notices.sh

validate-base-tag:
	@if [ -n "$(UPSTREAM_BASE_TAG)" ]; then \
		resolved=$$(git -C $(ROOT) rev-parse "refs/tags/$(UPSTREAM_BASE_TAG)^{commit}" 2>/dev/null || true); \
		test "$$resolved" = "$(UPSTREAM_BASE)" || { echo "UPSTREAM_BASE_TAG must resolve to UPSTREAM_BASE" >&2; exit 2; }; \
	fi

build-docker-library: validate-base-tag check-third-party-notices
	docker build \
		$(SOURCE_LABEL_ARG) \
		--build-arg GO_VERSION=$(GO_VERSION) \
		--build-arg WAF_BUILD_TAGS=$(WAF_BUILD_TAGS) \
		--build-arg SOURCE_REPO="$(SOURCE_REPO)" \
		--build-arg BUILT_REVISION="$(BUILT_REVISION)" \
		--build-arg RELEASE_VERSION="$(RELEASE_VERSION)" \
		--build-arg BUILD_TREE_STATE="$(BUILD_TREE_STATE)" \
		--build-arg ENVOY_VERSION="$(ENVOY_VERSION)" \
		--build-arg UPSTREAM_BASE="$(UPSTREAM_BASE)" \
		--build-arg UPSTREAM_BASE_TAG="$(UPSTREAM_BASE_TAG)" \
		-f $(WAF_DIR)/Dockerfile.library -t $(LIBRARY_IMAGE) $(ROOT)
