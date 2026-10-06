# Fork and release workflow

Keep the complete Built on Envoy source history in the root repository. The WAF module and its packaging live in `downstream/waf/`; the module imports the Composer WAF from `extensions/composer/waf` using a local Go `replace`.

## Source and build

- Keep the module path and local `replace` in `downstream/waf/go.mod` so builds use the WAF source from this checkout without copying upstream code.
- Keep the Envoy dynamic-module SDK pinned to an exact pseudo-version from a compatible Envoy tag or exact `main` commit. The generated third-party inventory records the SDK module version; set the Envoy compatibility target explicitly for each artifact build.
- Keep this fork's `RELEASE_VERSION` independent of Composer's manifest version. `SOURCE_REPO` is optional and adds source URL attribution to the OCI artifact when supplied.
- Keep the full license and provenance directory in the artifact. Redistributors copying the `.so` must copy the whole directory too.

## Normal upstream merges

1. Fetch Tetrate's upstream refs and select a tag or `main` commit.
2. Merge that commit normally, preserving the full upstream history; do not path-filter or prune upstream files.
3. Review conflicts and keep downstream wrapper, packaging, and release changes in focused commits.
4. After the merge is incorporated, write its exact upstream commit SHA to `downstream/waf/UPSTREAM_BASE` and update attribution if needed.
5. Rebuild the WAF and OCI artifact, then check that the bundled notices and provenance identify the same sources and revisions.

The initial `UPSTREAM_BASE` is the Composer `v0.12.0` tag commit listed in [ATTRIBUTION.md](../ATTRIBUTION.md). Future values identify the latest full upstream commit incorporated, not this fork's release version.

RuleServer reload is outside this migration and remains future work; this plan does not define its API or behavior.
