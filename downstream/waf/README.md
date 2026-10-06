# Coraza WAF dynamic module

This module registers the Composer Coraza WAF with Envoy. The WAF implementation remains in [`../../extensions/composer/waf`](../../extensions/composer/waf); `go.mod` replaces the Composer module with `../../extensions/composer` so builds use this checkout.

## Build

From the repository root:

```sh
make -C downstream/waf build
make -C downstream/waf check-third-party-notices
```

The library is written to `downstream/waf/build/libcoraza_waf.so`. To regenerate and review the license bundle after changing the Composer dependency or CRS data:

```sh
make -C downstream/waf generate-third-party-notices
make -C downstream/waf check-third-party-notices
```

Build the library-only OCI artifact with its own release version:

```sh
make -C downstream/waf build-docker-library \
  RELEASE_VERSION=YOUR_VERSION \
  ENVOY_VERSION=v1.38.0
```

`ENVOY_VERSION` declares the Envoy compatibility target. The dynamic-module SDK is pinned to an exact pseudo-version in `go.mod`; update both deliberately when selecting a different Envoy tag or an exact `main` commit. The WAF module's release version is independent from Composer's upstream manifest version.
`SOURCE_REPO` is optional; when supplied, it adds the OCI source label and a source-repository entry to `BUILD_PROVENANCE.txt`.
The Istio Gateway keeps its root filesystem read-only and mounts a disk-backed `emptyDir` at `/tmp` for Coraza's temporary request-body files. Coraza buffers up to its configured in-memory threshold, then spills larger bodies to this volume. The demo caps scratch space at 1 GiB; adjust that limit and Coraza's body limits for your expected request sizes and concurrency. The pod sets `fsGroup: 1337` so the proxy can write to the volume.

## Consume the library

The OCI artifact is a library-and-notices image, not an Envoy runtime image. Copy or mount `/libcoraza_waf.so` into an Envoy image and set `ENVOY_DYNAMIC_MODULES_SEARCH_PATH` to its directory and `GODEBUG=cgocheck=0`. Configure the dynamic module with `dynamic_module_config.name: coraza_waf` and the filter name `coraza-waf`.

When copying the library into another Envoy image, copy the entire `/usr/share/licenses/built-on-envoy/` directory from the artifact with it. That directory contains the upstream license, attribution, build provenance, and generated third-party notices.

Run the demo from the repository root with `make -C downstream/waf demo ENVOY_VERSION=v1.38.0`. It builds the library, starts the official `envoyproxy/envoy` container at the selected version with the checked-in [demo config](config/envoy-demo.yaml) and [demo rule](config/istio/demo-rules.conf), and checks that a benign request returns HTTP 200 while a request containing `evilmonkey` is blocked with HTTP 403. This does not build or publish an Envoy image.

## Istio Gateway API demo

`config/istio/` contains a Kubernetes Gateway API demo with an Istio-managed Gateway, an HTTPRoute, and the Gateway API `echo-basic` backend. It inserts the Coraza dynamic-module filter with an Istio `EnvoyFilter` and mounts the library from the library-only OCI artifact.

The cluster needs the Gateway API v1 CRDs and Istio Gateway API support. Istio merged [dynamic-module filter registration in istio/proxy](https://github.com/istio/proxy/pull/6955) in April 2026, so use an Istio proxy image whose build includes that change. The Gateway customization keeps the proxy image selected by Istio and sets the Go runtime options needed by this module. Edit the image volume `reference` in `config/istio/gateway-options.yaml` to point to the published WAF library artifact. Match the module build's Envoy version and dynamic-module ABI (`ENVOY_VERSION` and the pinned SDK); older Istio proxy images may need a compatible custom build. The open [Istio Dynamic Modules issue](https://github.com/istio/istio/issues/59839) tracks broader integration work.

This demo targets Kubernetes v1.35 or later, where `ImageVolume` is enabled by default (beta in v1.35 and stable in v1.36). Kubernetes v1.31–v1.34 can use image volumes when the version-appropriate `ImageVolume` feature gate is enabled on the required components and the container runtime supports image volumes. See the [Kubernetes image-volume documentation](https://kubernetes.io/docs/tasks/configure-pod-container/image-volumes/) and [feature-gate reference](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/).

Apply the Gateway parameters ConfigMap first, then the complete demo:

```sh
kubectl apply -f downstream/waf/config/istio/gateway-options.yaml
kubectl apply -k downstream/waf/config/istio
kubectl get gateway coraza-waf-demo
kubectl get deployment coraza-waf-demo-istio
```

The parameters ConfigMap is in the same namespace as the Gateway, as required by Istio. The generated gateway Service is `coraza-waf-demo-istio`. For a local check, port-forward it and send requests with the configured host:

```sh
kubectl port-forward service/coraza-waf-demo-istio 18080:80
curl -i -H 'Host: waf-demo.example.com' http://127.0.0.1:18080/
curl -i -H 'Host: waf-demo.example.com' http://127.0.0.1:18080/evilmonkey
```

The first request reaches the backend; the second is denied with HTTP 403 by the demo rule.

## Upstream changes

Use normal full upstream Git merges to keep this repository's history intact. For each merge, record the exact incorporated upstream commit in `downstream/waf/UPSTREAM_BASE`; keep downstream wrapper, packaging, and release changes in focused commits. See [the fork plan](docs/fork-plan.md) and [attribution](ATTRIBUTION.md).

RuleServer reload is future work and is not part of this module's current behavior; see the [planning document](docs/ruleserver-reload-plan.md).
