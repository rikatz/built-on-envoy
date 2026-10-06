# Third-party notices

Generated from the final `.` C shared-library target with the production WAF build tags for every supported Linux target. The Go toolchain version is recorded separately because `go-licenses` does not report the standard library/runtime.
Each section lists an external Go module and its resolved version. `licenses/` contains the license files and any sibling NOTICE files required by the dependency; `go-licenses check` fails on missing or unknown licenses.

## Build target: `linux/amd64`

- `github.com/corazawaf/coraza-coreruleset/v4` — `v4.25.0`
- `github.com/corazawaf/coraza/v3` — `v3.7.0`
- `github.com/corazawaf/libinjection-go` — `v0.3.2`
- `github.com/envoyproxy/envoy/source/extensions/dynamic_modules` — `v0.0.0-20260425100846-90594f45b3ed`
- `github.com/goccy/go-json` — `v0.10.6`
- `github.com/goccy/go-yaml` — `v1.18.0`
- `github.com/gotnospirit/makeplural` — `v0.0.0-20180622080156-a5f48d94d976`
- `github.com/gotnospirit/messageformat` — `v0.0.0-20221001023931-dfe49f1eb092`
- `github.com/jcchavezs/mergefs` — `v0.1.1`
- `github.com/kaptinlin/go-i18n` — `v0.1.4`
- `github.com/kaptinlin/jsonschema` — `v0.4.6`
- `github.com/petar-dambovaliev/aho-corasick` — `v0.0.0-20250424160509-463d218d4745`
- `github.com/tidwall/gjson` — `v1.18.0`
- `github.com/tidwall/match` — `v1.1.1`
- `github.com/tidwall/pretty` — `v1.2.1`
- `github.com/valllabh/ocsf-schema-golang` — `v1.0.3`
- `go.uber.org/multierr` — `v1.11.0`
- `go.uber.org/zap` — `v1.28.0`
- `golang.org/x/net` — `v0.58.0`
- `golang.org/x/sync` — `v0.23.0`
- `golang.org/x/text` — `v0.42.0`
- `google.golang.org/protobuf` — `v1.36.12`
- `rsc.io/binaryregexp` — `v0.2.0`

## Build target: `linux/arm64`

- `github.com/corazawaf/coraza-coreruleset/v4` — `v4.25.0`
- `github.com/corazawaf/coraza/v3` — `v3.7.0`
- `github.com/corazawaf/libinjection-go` — `v0.3.2`
- `github.com/envoyproxy/envoy/source/extensions/dynamic_modules` — `v0.0.0-20260425100846-90594f45b3ed`
- `github.com/goccy/go-json` — `v0.10.6`
- `github.com/goccy/go-yaml` — `v1.18.0`
- `github.com/gotnospirit/makeplural` — `v0.0.0-20180622080156-a5f48d94d976`
- `github.com/gotnospirit/messageformat` — `v0.0.0-20221001023931-dfe49f1eb092`
- `github.com/jcchavezs/mergefs` — `v0.1.1`
- `github.com/kaptinlin/go-i18n` — `v0.1.4`
- `github.com/kaptinlin/jsonschema` — `v0.4.6`
- `github.com/petar-dambovaliev/aho-corasick` — `v0.0.0-20250424160509-463d218d4745`
- `github.com/tidwall/gjson` — `v1.18.0`
- `github.com/tidwall/match` — `v1.1.1`
- `github.com/tidwall/pretty` — `v1.2.1`
- `github.com/valllabh/ocsf-schema-golang` — `v1.0.3`
- `go.uber.org/multierr` — `v1.11.0`
- `go.uber.org/zap` — `v1.28.0`
- `golang.org/x/net` — `v0.58.0`
- `golang.org/x/sync` — `v0.23.0`
- `golang.org/x/text` — `v0.42.0`
- `google.golang.org/protobuf` — `v1.36.12`
- `rsc.io/binaryregexp` — `v0.2.0`


## Go runtime and standard library — go1.27.1

The final C shared library includes the Go runtime and standard library, which are not reported by go-licenses.

- `licenses/go-runtime/go1.27.1/LICENSE` (BSD-style Go license)
- `licenses/go-runtime/go1.27.1/PATENTS` (Go additional IP rights grant)

## Envoy dynamic modules SDK repository notice — v0.0.0-20260425100846-90594f45b3ed

The SDK is part of the Envoy repository; its root NOTICE is included separately from the SDK module license:

- `licenses/notices/envoy-dynamic-modules-sdk/v0.0.0-20260425100846-90594f45b3ed/NOTICE`

## Embedded OWASP CRS data — v4.25.0

These license and notice files apply to the embedded rules data and are separate from the Go module license:
- `licenses/embedded-data/coraza-coreruleset/v4.25.0/LICENSE`
