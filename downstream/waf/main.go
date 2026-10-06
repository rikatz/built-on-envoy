// Copyright 2026 the contributors to the Coraza WAF downstream build.
// SPDX-License-Identifier: Apache-2.0
// Adapted from the sibling coraza-dynamic-module for this full upstream fork.

package main

import (
	// Linked in for its //export'ed ABI symbols (envoy_dynamic_module_on_program_init etc.).
	_ "github.com/envoyproxy/envoy/source/extensions/dynamic_modules/sdk/go/abi"

	sdk "github.com/envoyproxy/envoy/source/extensions/dynamic_modules/sdk/go"
	waf "github.com/tetratelabs/built-on-envoy/extensions/composer/waf"
)

func main() {}

func init() {
	sdk.RegisterHttpFilterConfigFactories(waf.WellKnownHttpFilterConfigFactories()) // nolint:revive
}
