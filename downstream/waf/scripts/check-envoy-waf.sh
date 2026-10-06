#!/usr/bin/env bash
# Copyright 2026 the contributors to the Coraza WAF downstream build.
# SPDX-License-Identifier: Apache-2.0
# See the repository LICENSE.

set -euo pipefail

usage() {
	printf 'Usage: %s /path/to/libcoraza_waf.so [envoy-version]\n' "$0" >&2
	printf 'Example: %s /tmp/libcoraza_waf.so v1.38.0\n' "$0" >&2
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
	usage
	exit 2
fi

library=$1
version=${2:-v1.38.0}
version=${version#v}
image="envoyproxy/envoy:v${version}"

if [[ ! -f "$library" ]]; then
	printf 'Shared library not found: %s\n' "$library" >&2
	usage
	exit 2
fi
if ! command -v docker >/dev/null || ! command -v curl >/dev/null; then
	printf 'This check requires docker and curl on PATH.\n' >&2
	exit 2
fi

library_dir=$(cd "$(dirname "$library")" && pwd)
library="$library_dir/$(basename "$library")"
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
demo_config="$repo_root/downstream/waf/config/envoy-demo.yaml"
demo_rules="$repo_root/downstream/waf/config/istio/demo-rules.conf"
if [[ ! -f "$demo_config" ]]; then
	printf 'Envoy demo config not found: %s\n' "$demo_config" >&2
	exit 2
fi
if [[ ! -f "$demo_rules" ]]; then
	printf 'Envoy demo rules not found: %s\n' "$demo_rules" >&2
	exit 2
fi
tmp=$(mktemp -d)
container_name="built-on-envoy-waf-smoke-$$"
container_id=

cleanup() {
	status=$?
	if [[ -n "$container_id" ]]; then
		if ((status != 0)); then
			docker logs "$container_id" >&2 || true
		fi
		docker stop "$container_id" >/dev/null 2>&1 || true
	fi
	rm -rf "$tmp"
	exit "$status"
}
trap cleanup EXIT

container_id=$(docker run --pull=missing --rm --detach \
	--name "$container_name" \
	--publish 127.0.0.1::10000 \
	--env ENVOY_DYNAMIC_MODULES_SEARCH_PATH=/waf \
	--env GODEBUG=cgocheck=0 \
	--volume "$library:/waf/libcoraza_waf.so:ro" \
	--volume "$demo_config:/etc/envoy/envoy.yaml:ro" \
	--volume "$demo_rules:/etc/coraza/rules/demo-rules.conf:ro" \
	"$image" -c /etc/envoy/envoy.yaml --log-level warning)

published_port=
for _ in {1..30}; do
	published=$(docker port "$container_id" 10000/tcp 2>/dev/null || true)
	published_port=${published##*:}
	if [[ -n "$published_port" ]] && curl --silent --fail --max-time 2 --output /dev/null "http://127.0.0.1:$published_port/ready"; then
		break
	fi
	sleep 1
done
if [[ -z "$published_port" ]] || ! curl --silent --fail --max-time 2 --output /dev/null "http://127.0.0.1:$published_port/ready"; then
	printf 'Envoy did not become ready using %s.\n' "$image" >&2
	exit 1
fi

base_url="http://127.0.0.1:$published_port"
allow_status=$(curl --silent --show-error --max-time 10 --output "$tmp/allow.body" --write-out '%{http_code}' "$base_url/allow")
block_status=$(curl --silent --show-error --max-time 10 --output "$tmp/block.body" --write-out '%{http_code}' "$base_url/evilmonkey")

if [[ "$allow_status" != 200 || "$block_status" != 403 ]]; then
	printf 'Unexpected WAF responses: benign request=%s (expected 200), evilmonkey request=%s (expected 403).\n' \
		"$allow_status" "$block_status" >&2
	exit 1
fi

printf 'Envoy %s loaded the WAF module and enforced its rule: benign=%s, evilmonkey=%s.\n' \
	"$version" "$allow_status" "$block_status"
