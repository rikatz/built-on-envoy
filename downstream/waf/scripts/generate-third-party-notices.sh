#!/usr/bin/env bash
# Copyright 2026 the contributors to the Coraza WAF downstream build.
# SPDX-License-Identifier: Apache-2.0
# See the repository LICENSE.
set -euo pipefail

waf_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_dir="${1:-$waf_dir/THIRD_PARTY_NOTICES}"
: "${WAF_BUILD_TAGS:?set WAF_BUILD_TAGS to the production WAF build tags}"
: "${LICENSE_PLATFORMS:?set LICENSE_PLATFORMS to the production linux/os targets}"
: "${GO_VERSION:?set GO_VERSION to the Go version used by the production build}"

cd "$waf_dir"
actual_go_version="$(go env GOVERSION)"
actual_go_release="${actual_go_version%%-*}"
if [ "$actual_go_release" != "go${GO_VERSION}" ]; then
  echo "notice generation uses $actual_go_version, but the production build uses go${GO_VERSION}" >&2
  exit 1
fi

goroot="$(go env GOROOT)"
go_license=""
go_patents=""
for candidate in "$goroot/LICENSE" /usr/share/licenses/golang/LICENSE; do
  if [ -f "$candidate" ]; then go_license="$candidate"; break; fi
done
for candidate in "$goroot/PATENTS" /usr/share/licenses/golang/PATENTS; do
  if [ -f "$candidate" ]; then go_patents="$candidate"; break; fi
done
if [ -z "$go_license" ] || [ -z "$go_patents" ]; then
  echo "could not locate both LICENSE and PATENTS for Go ${GO_VERSION}" >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/bin"
go_licenses_source="$(go env GOMODCACHE)/github.com/google/go-licenses/v2@v2.0.1"
if [ -f "$go_licenses_source/go.mod" ]; then
  (cd "$go_licenses_source" && go build -mod=readonly -o "$tmp_dir/bin/go-licenses" .)
else
  GOBIN="$tmp_dir/bin" go install github.com/google/go-licenses/v2@v2.0.1
fi
sdk_version="$(go list -m -f '{{.Version}}' github.com/envoyproxy/envoy/source/extensions/dynamic_modules)"
envoy_repo_dir="$(go env GOMODCACHE)/github.com/envoyproxy/envoy@${sdk_version}"
if [ ! -f "$envoy_repo_dir/NOTICE" ]; then
  notice_module="$tmp_dir/envoy-source-module"
  mkdir -p "$notice_module"
  printf 'module waf-notice-source\ngo %s\n' "$GO_VERSION" > "$notice_module/go.mod"
  (cd "$notice_module" && go mod download "github.com/envoyproxy/envoy@${sdk_version}")
fi
if [ ! -f "$envoy_repo_dir/NOTICE" ]; then
  echo "could not locate the Envoy repository NOTICE for SDK $sdk_version at $envoy_repo_dir" >&2
  exit 1
fi
mkdir -p "$tmp_dir/licenses"
{
  cat <<'EOF'
# Third-party notices

Generated from the final `.` C shared-library target with the production WAF build tags for every supported Linux target. The Go toolchain version is recorded separately because `go-licenses` does not report the standard library/runtime.
Each section lists an external Go module and its resolved version. `licenses/` contains the license files and any sibling NOTICE files required by the dependency; `go-licenses check` fails on missing or unknown licenses.

EOF
  for platform in ${LICENSE_PLATFORMS//,/ }; do
    os="${platform%/*}"
    arch="${platform#*/}"
    target_dir="$tmp_dir/$os-$arch"
    mkdir -p "$target_dir"
    printf '## Build target: `%s/%s`\n\n' "$os" "$arch"
    CGO_ENABLED=1 GOOS="$os" GOARCH="$arch" GOFLAGS="-mod=readonly -tags=$WAF_BUILD_TAGS" "$tmp_dir/bin/go-licenses" check . --ignore=github.com/networking-incubator/coraza-dynamic-module --ignore=github.com/tetratelabs/built-on-envoy/extensions/composer
    CGO_ENABLED=1 GOOS="$os" GOARCH="$arch" GOFLAGS="-mod=readonly -tags=$WAF_BUILD_TAGS" "$tmp_dir/bin/go-licenses" save . --ignore=github.com/networking-incubator/coraza-dynamic-module --ignore=github.com/tetratelabs/built-on-envoy/extensions/composer --save_path="$target_dir/licenses"
    CGO_ENABLED=1 GOOS="$os" GOARCH="$arch" GOFLAGS="-mod=readonly -tags=$WAF_BUILD_TAGS" go list -deps -f '{{if .Module}}{{.Module.Path}} {{.Module.Version}}{{end}}' . | awk '$1 != "" && $1 != "github.com/networking-incubator/coraza-dynamic-module" && $1 !~ /^github.com\/tetratelabs\/built-on-envoy\/extensions\/composer(\/|$)/' | LC_ALL=C sort -u > "$target_dir/modules.txt"
    while read -r module version; do
      [ -n "$module" ] || continue
      printf -- '- `%s` — `%s`\n' "$module" "$version"
    done < "$target_dir/modules.txt"
    chmod -R u+rwX "$tmp_dir/licenses"
    cp -R "$target_dir/licenses/." "$tmp_dir/licenses/"
    printf '\n'
  done
  go_output_dir="licenses/go-runtime/go${GO_VERSION}"
  install -D -m 0644 "$go_license" "$tmp_dir/$go_output_dir/LICENSE"
  install -D -m 0644 "$go_patents" "$tmp_dir/$go_output_dir/PATENTS"
  printf '\n## Go runtime and standard library — go%s\n\n' "$GO_VERSION"
  printf 'The final C shared library includes the Go runtime and standard library, which are not reported by go-licenses.\n\n'
  printf -- '- `%s/LICENSE` (BSD-style Go license)\n' "$go_output_dir"
  printf -- '- `%s/PATENTS` (Go additional IP rights grant)\n' "$go_output_dir"
  envoy_notice_dir="licenses/notices/envoy-dynamic-modules-sdk/$sdk_version"
  install -D -m 0644 "$envoy_repo_dir/NOTICE" "$tmp_dir/$envoy_notice_dir/NOTICE"
  printf '\n## Envoy dynamic modules SDK repository notice — %s\n\n' "$sdk_version"
  printf 'The SDK is part of the Envoy repository; its root NOTICE is included separately from the SDK module license:\n\n'
  printf -- '- `%s/NOTICE`\n' "$envoy_notice_dir"
} > "$tmp_dir/THIRD_PARTY_NOTICES.md"

crs_version="$(go list -m -f '{{.Version}}' github.com/corazawaf/coraza-coreruleset/v4)"
if ! grep -Fq "corazawaf/coraza-coreruleset/v4" "$tmp_dir/THIRD_PARTY_NOTICES.md" || ! grep -Fq "$crs_version" "$tmp_dir/THIRD_PARTY_NOTICES.md"; then
  echo "the standalone build license inventory does not include embedded Coraza CRS v$crs_version" >&2
  exit 1
fi

crs_dir="$(go list -m -f '{{.Dir}}' github.com/corazawaf/coraza-coreruleset/v4)"
crs_legal_files=()
while IFS= read -r legal_file; do
  crs_legal_files+=("$legal_file")
done < <(find "$crs_dir/rules" -type f \( -iname 'LICENSE*' -o -iname 'NOTICE*' \) -print | LC_ALL=C sort)
if [ "${#crs_legal_files[@]}" -eq 0 ]; then
  echo "no license or notice files found for embedded Coraza CRS data in $crs_dir/rules" >&2
  exit 1
fi

crs_output_dir="licenses/embedded-data/coraza-coreruleset/$crs_version"
for legal_file in "${crs_legal_files[@]}"; do
  relative_path="${legal_file#"$crs_dir/rules/"}"
  install -D -m 0644 "$legal_file" "$tmp_dir/$crs_output_dir/$relative_path"
  printf -- '- `%s/%s`\n' "$crs_output_dir" "$relative_path" >> "$tmp_dir/CRS_LICENSE_PATHS.md"
done
{
  printf '\n## Embedded OWASP CRS data — %s\n\n' "$crs_version"
  printf 'These license and notice files apply to the embedded rules data and are separate from the Go module license:\n'
  cat "$tmp_dir/CRS_LICENSE_PATHS.md"
} >> "$tmp_dir/THIRD_PARTY_NOTICES.md"

chmod -R a+rX "$tmp_dir/licenses"
mkdir -p "$output_dir"
rm -rf "$output_dir/licenses"
rm -f "$output_dir/THIRD_PARTY_NOTICES.md"
mv "$tmp_dir/licenses" "$output_dir/licenses"
mv "$tmp_dir/THIRD_PARTY_NOTICES.md" "$output_dir/THIRD_PARTY_NOTICES.md"
