# Attribution

This repository is an unofficial derivative of [Tetrate's Built on Envoy](https://github.com/tetratelabs/built-on-envoy). It is not affiliated with or endorsed by Tetrate.

Built on Envoy and Composer are by Tetrate. The WAF is [Coraza](https://github.com/corazawaf/coraza), maintained by the Coraza contributors, and embeds the [OWASP Core Rule Set](https://coreruleset.org/). The Envoy dynamic-module SDK is from the [Envoy project](https://github.com/envoyproxy/envoy).

## Source history

- Initial source: Tetrate's Built on Envoy repository, Composer tag `extensions/composer/v0.12.0`.
- Initial commit: `0e3b8ced5ccbd493805cb2a301fc561a85f21c6d`, dated `2026-09-29T13:07:06Z`.
- The initial wrapper bootstrap was prototyped in the sibling checkout at commit `253693264a1d84e830b3e6fc6e9c7bbb1eaf873e`; this records implementation provenance only and is not the fork's upstream base.
- Current incorporated upstream commit: recorded in [`UPSTREAM_BASE`](UPSTREAM_BASE). Update it only after a full upstream merge has been reviewed and incorporated.
- The downstream module is under `downstream/waf/`; it imports the local Composer module with `replace ... => ../../extensions/composer`, preserving upstream package paths without copying the WAF implementation.
- The Envoy dynamic-module SDK is pinned in `downstream/waf/go.mod` to `v0.0.0-20260425100846-90594f45b3ed`; the current compatibility target is Envoy `v1.38.0`.

The upstream root `LICENSE` is Apache-2.0 and is preserved. No root `NOTICE` existed at the initial base. The Envoy SDK repository's applicable `NOTICE` is included separately in the generated third-party inventory.

## OCI attribution

The library-only image includes the root `LICENSE`, this file, `UPSTREAM_BASE`, a `BUILD_PROVENANCE.txt` with the built revision, release version, tree state and upstream revision, and the generated third-party notice inventory and license copies. The inventory covers the Go modules in the shared-library build, Go runtime, embedded CRS data, and Envoy repository notice. If `SOURCE_REPO` is supplied at build time, the image metadata and provenance also identify the fork source. Other image metadata identifies the built revision, fork release, upstream base and unofficial status. No standard OCI `licenses` label is set because the image contains software under multiple licenses; `io.built-on-envoy.project.license=Apache-2.0` describes this project's code only.

When copying `libcoraza_waf.so` into another Envoy image, copy the complete `/usr/share/licenses/built-on-envoy/` directory as well. The original upstream source headers and applicable notices must remain with redistributed source and binaries.
