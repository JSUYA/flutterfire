# Review audit (post-critique)

This document records the findings raised by the four review agents that
audited the pure-Dart rewrite and tracks which ones turned into code or
documentation changes in this branch.

## Reviewer outputs

- **Firebase Protocol Expert** — 10 protocol-level deviations (Storage
  multipart boundary, resumable 308, callable `result`/`data`, Int64
  boundary, SSE multi-line, Auth error map gaps, Storage HTTP→code
  mapping, Remote Config 304 dead branch, Installations header
  formats).
- **Tizen Platform Expert** — 7 BLOCKERs + 8 MAJORs (compile errors
  across RC/AI/tests/storage pubspec, `path_provider_tizen` missing,
  `common-6.0` / `tv-9.0` / `wearable` mismatch, `firebase_core_tizen`
  path override missing, LICENSE formatting, re-exported `@internal`
  surface).
- **FlutterFire Parity Reviewer** — 17 F (fatal compile) + W (contract
  violations) + M (missing overrides). Many were confirmed against the
  real platform-interface source; some (e.g. claims about
  `FirebaseAppInstallationsPlatform` / `DatabasePlatform` alternate
  names, or OnDisconnectPlatform's constructor shape) turned out to be
  incorrect when checked against v6/v0.3.1+1 / v8.1.9 of the
  respective platform_interface packages.
- **Critical Adversarial Reviewer** — 28 findings across 4 severity
  bands (compile, protocol, resource leaks, security, Tizen-platform).

## Findings applied (validated fixes)

Every commit below is in the branch log.

| Area               | Fix commit(s) | Finding source(s) |
|---|---|---|
| Storage pubspec invalid `http` dev_dep + unused `mime` | `5b2c0a5` | Protocol, Tizen, Critical |
| Installations `getToken` self-deadlock | `ca0a4ce` | Critical |
| Remote Config private-constructor compile error | `603e7aa` | Tizen, Critical |
| Database test `FirebaseDatabaseTizen.instance` miss | `6a8a1b0` | Tizen, Critical |
| AI `register()` eagerly called `Firebase.app()` | `97f023b` | Tizen, Critical |
| `tests/example` bad imports & `firebase_messaging` | `32fb4ab` | Tizen, Critical |
| Storage multipart used `sendJson` (Content-Type + JSON-encoded body) | `64fe44d` | Protocol, Critical |
| Storage resumable upload rejected HTTP 308 | `f709f21` | Protocol, Critical |
| Callable read `data` before `result`, dropped `error.details`, Int64 off-by-one | `604e1ac` | Protocol |
| AI SSE multi-line data events | `4c6c7ad` | Protocol |
| Auth error-code gaps (INVALID_LOGIN_CREDENTIALS + 2023 codes) | `02e7751` | Protocol, Critical |
| Remote Config UTF-16 `codeUnits` corruption | `6d24461` | Critical |
| Storage download sink leak on error | `1b0a8e3` | Critical |
| Remote Config dead 304 branch | `3e99130` | Protocol |
| Database `refFromURL` treated URL as path | `c4913c7` | Critical |
| Architecture doc claimed encrypted Hive (it isn't) | `bd70a41` | Critical |
| `path_provider_tizen` not declared | `3d3c5d5` | Tizen |
| Examples pinned `firebase_core_tizen: ^2.0.0` (unpublished) | `e12af12` | Tizen, Critical |
| Auth `ActionCodeInfo.data` type | `a1f8289` | Parity |
| Database `delegateFor` / `database` getter return type | `1f4c8df` | Parity |

## Findings deferred with rationale

The following findings were surfaced but deliberately left for a
follow-up iteration (or were rejected on verification):

- **`common-6.0` / `tv-9.0` / `wearable` alignment** — every manifest
  now declares `api-version="6.0"`, the recipe targets TV 9.0 (6.0+
  firmware), and example manifests carry the internet privilege.
  `flutter_plugin_tools`' default `--device-profile` for Tizen is not
  ours to change from this repo; documented in the migration PR.
- **LICENSE formatting & year** — the four pre-existing LICENSE files
  still carry the 2023 copyright and C++ SDK references. These files
  belong to the upstream flutter-tizen/plugins style sweep; keeping
  them as-is minimises noise in the rewrite PR.
- **Hive encryption** — documented explicitly (see `architecture.md`)
  rather than implemented in this round. Needs a Tizen-side secret
  store.
- **RT DB stream re-subscription / connection-lifecycle on TV standby**
  — captured in the architecture doc; real verification requires a
  physical device that this branch has not been run on.
- **Exposed `@internal` shared-runtime surface** — the
  `@internal`-annotated symbols are exported from
  `firebase_core_tizen`'s public library so sibling packages can
  import them without triggering `implementation_imports`. Moving
  them to a second lib file (`firebase_core_tizen/internal.dart`)
  would be the clean fix and is flagged for a follow-up.
- **Parity reviewer claims that did not hold**: the
  `FirebaseAppInstallationsPlatform` / `FirebaseInstallationsPlatform`
  name, `DatabasePlatform` alternate name, `OnDisconnectPlatform`
  two-arg super signature, and method-vs-getter claims around `root`
  were verified against the real v6/v0.3.1+1 / v8.1.9 sources and
  turned out to be wrong. Those commits were intentionally not made.
- **`firebase_ai` platform_interface parity** — `firebase_ai` has no
  federated platform_interface, so `FirebaseAiTizen` exposes a direct
  wrapper. README and architecture doc state this.

## What the next iteration owes

- Add a Tizen-side secret store → encrypted Hive box.
- Add mock-based wire-format tests for: Storage multipart (content-type
  rules), Storage resumable 308 path, Storage download cancellation,
  callable error.details round-trip, Remote Config 304 fallback, AI
  multi-line SSE.
- Run `flutter-tizen build tpk --release` on a physical TV device,
  measure the combined-harness TPK, and update `tpk_size_audit.md` with
  observed sizes.
- Split the shared runtime into a separate `firebase_core_tizen/
  internal.dart` library to truly hide `@internal` symbols.
