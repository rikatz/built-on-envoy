#!/usr/bin/env bash
# Copyright 2026 the contributors to the Coraza WAF downstream build.
# SPDX-License-Identifier: Apache-2.0
# See the repository LICENSE.
set -euo pipefail

waf_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

"$waf_dir/scripts/generate-third-party-notices.sh" "$tmp_dir/THIRD_PARTY_NOTICES"
diff -ru "$waf_dir/THIRD_PARTY_NOTICES" "$tmp_dir/THIRD_PARTY_NOTICES"
