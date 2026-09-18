# SINT Roadmap — 1.7.0: Adaptive SintApp

> **Current design direction:** [Adaptive SintApp with limited changes](https://github.com/Open-Neom/sint/blob/main/docs/roadmaps/sint-app-minimal.md).
> Reuse one SintRoot, select Cupertino on iOS and Material elsewhere, and add
> typed materialTheme/cupertinoTheme arguments with a legacy theme transition.
> Extracting a neutral entry point and separate adapters is no longer an initial
> requirement. Direct standalone dependencies would require Flutter >=3.44 /
> Dart >=3.12; the manifest has not changed. Earlier proposals below are retained
> as alternatives, not mandatory implementation steps.

> **2026-09-12 migration proposal:** [Material/Cupertino coexistence roadmap](https://github.com/Open-Neom/sint/blob/main/docs/roadmaps/design-systems-migration.md)
> defines opt-in standalone UI adapters, a shared runtime, SDK/platform/build
> validation, and staged deprecation of legacy design APIs. This is a planning
> document; no adapters or deprecation annotations have shipped from this work.
> The historical backlog below predates 1.6.2 and must be checked against the
> changelog before implementation; several items are already complete.

> **Initial preparation:** public API documentation now carries a planned
> deprecation notice. The [user migration guide](MIGRATION_DESIGN_SYSTEMS.md)
> distinguishes supported current usage from future adapter availability.
> Formal analyzer diagnostics remain gated on stable replacements.

> **Versioning philosophy:** The four pillars (State, Injection, Navigation,
> Translation) do not need breaking changes to evolve. The entire 1.x line is
> additive evolution — performance, web, XR, DevTools, codegen — preserving
> existing public contracts. Standalone design-system support can arrive through
> opt-in adapters in **1.7.0**. A future 2.0 product vision is a separate decision;
> this migration does not require it. Version numbers still express API
> compatibility: breaking public types require a major release regardless of
> the amount of innovation. Legacy UI removal requires its own documented
> migration and support criteria.

**Historical target for GetX-alias removal:** all 21+ neom_modules complete 2+
releases without deprecated symbols. This alone does not authorize removing
legacy Material/Cupertino APIs or establish compatibility for external users;
apply the dedicated migration roadmap's release gates as well.

---

## Earlier 1.7.0 proposal — neutral entry point and separate adapters

**Target:** add working, opt-in standalone Material/Cupertino integrations while
existing SINT applications keep their imports, public types and behavior.
The preparation notices and migration guide are ready locally; adapters and
the shared neutral entry point remain pending. This is a release target, not a
claim that 1.7.0 or its adapters have shipped.

1. **Protect current contracts.** Add a compilable legacy consumer fixture and
   record the standalone failure from issue #12. Cover public app constructors,
   theme methods, context extensions and directly used host/route contracts.
2. **Decouple the shared runtime from design libraries.** Introduce the proposed
   `sint/foundation.dart` entry point and neutral host/route contracts, preserving
   one canonical set of controllers, Rx types, DI registrations and translations.
   Keep legacy wrappers and deep imports source-compatible.
3. **Deliver standalone adapters.** Implement the proposed `sint_material_ui`
   first against issue #12, then `sint_cupertino_ui`, including themes, overlays,
   locales and transitions. These are separate packages with their own version
   numbers and SDK constraints; `sint` must not depend on them.
4. **Validate coexistence and migration.** Compile legacy and modern fixtures,
   exercise shared state/DI identity and lifecycle, and run the platform matrix
   and pilot applications in the detailed roadmap. Publish exact migration
   instructions alongside the released adapter APIs.
5. **Release when the feature works.** Keep documentation notices during
   development. Formal deprecation diagnostics require stable replacements and
   an announced support window; they are not a prerequisite for 1.7.0.

**Immediate implementation increment:** legacy compatibility fixtures plus a
neutral host/route seam and its first Material proof of concept. This proves that
SDK-specific configuration can be moved behind an adapter without changing
`ConfigData`, `Sint.rootController` or existing `SintPageRoute` return contracts.
Do not expose a supposedly neutral entry point that still imports design APIs
transitively. Advance to the public adapter only after that boundary is verified.

**Release gate:** the legacy fixture still works on the supported minimum SDK;
the standalone issue #12 scenario and associated public APIs work; both adapters
pass their documented validation; no duplicated state/DI runtime is introduced;
and migration instructions reference available APIs. The base package retains
Flutter >=3.32 / Dart >=3.8; new adapter minima are tested independently.
If a boundary cannot be preserved, redesign or defer that change instead of
including a silent breaking change in 1.7.0.

Benchmarks and DevTools below remain separate backlog candidates. They are not
required to ship this compatibility feature, and library separation alone is
not a performance claim. See the
[detailed migration roadmap](https://github.com/Open-Neom/sint/blob/main/docs/roadmaps/design-systems-migration.md)
and [Dart versioning guidance](https://dart.dev/tools/pub/versioning#semantic-versions).

---

## Horizon 1 — Technical backlog (1.6.0 – 1.7.0)

Identified during the 1.3.x–1.5.x audits; documented and deferred, never
forgotten.

### 1.6.0 candidates

- **O5a — Type-keyed injection registry.** Replace string keys
  (`S.toString() + tag`) with `Map<Type, Map<String?, _InstanceBuilderFactory>>`.
  Eliminates dart2js minified-name collision risk (real with 500+ controllers
  in web release) and speeds up `find` further. Crosses
  `RouterReportManager` and `registeredKeys` consumers in navigation — that is
  why it was kept out of 1.5.0. Top candidate.
- **P1 performance (from the 1.4.0 audit):**
  - Clean stale Obx dependencies between builds (phantom rebuilds in
    conditional UIs).
  - Conditional refresh in `RxList`/`RxMap` — the correct pattern already
    exists in `RxSet.add`; apply it to `remove`/`removeWhere`/`retainWhere`/
    `length` and `[]=`/`remove`.
  - Workers (`ever`/`once`/`debounce`/`interval`) on lightweight callbacks
    instead of `StreamController.broadcast` (~10× cheaper per worker).
- **Remaining leaks:** `bindStream` outside an Obx loses its disposer;
  `Notifier.append` without try/finally (corrupts global state if a builder
  throws); `SintListener` ignores callback changes in `didUpdateWidget`.
- **Silent-API fixes:** `Bind.spawn` produces a widget unable to resolve its
  controller; `Sint.put` with an existing key silently keeps the old
  instance; `ObxError` is neither `Error` nor `Exception`;
  `InstanceInfo.isCreate` null-safety.

### Historical 1.7.0 candidates — separate from the active migration scope

- **AOT benchmarks** (`dart compile exe` / `benchmark_harness`) so the
  harness measures release-mode performance, not only JIT.
- **Native & competitor baselines** in the benchmark suite:
  `ValueNotifier`/`ChangeNotifier`/raw `StreamController`, then
  Provider/Riverpod/BLoC — reproducible "SINT vs X" numbers as both
  telemetry and public evidence.
- **Dedupe `equality_mixin`** in favor of `package:collection`
  (smaller web bundle).
- **SINT DevTools extension** (stretch): live reactive state tree, DI
  registry, active routes, current locale. The instrumented engine
  (version counters, route index) makes this far cheaper than before.

---

## Horizon 2 — New features the ecosystem is already asking for (1.8.0 – 1.9.0)

SINT grows where no generic state manager can follow, because it knows the
Open Neom domain.

- **Navigation-scoped Rx containers** (1.8.0): reactive containers that
  auto-dispose with their route — closes the S ↔ N loop natively.
- **Optional `build_runner` codegen** (1.8.0): type-safe routes and
  generated DI registrations. Opt-in; the dynamic API stays untouched.
- **First-class Stream interop** (1.8.0): bidirectional `Stream` ↔ `Rx`
  bridge and platform channels, fixing the `bindStream` leaks by design.
- **Module-aware DI** (1.8.0): scopes aligned with `neom_modules/`
  boundaries + lazy module loading via Flutter deferred imports.
- **Build-time `.tr` key validation** (1.8.0): missing translation keys
  fail at compile time, not at runtime. RTL/LTR layout integration tied to
  locale changes.
- **SINT DevTools extension** (1.9.0, if not shipped in 1.7.0).
- **Native `sint_sentinel` integration** (1.9.0): the circuit breaker /
  rate limiter as a formal framework middleware.
- **VR/XR spatial routing** (1.9.0): `sint_vr` patterns absorbed on top of
  the segment route index — spatial navigation as a first-class Pillar N
  capability. Unique to SINT; no other Flutter framework has this on its
  horizon.
- **Flutter Web performance program** (continuous): bundle size, deferred
  loading, wasm readiness.

---

## Horizon 3 — Future major release: architecture and compatibility decisions

A major release can change the default design-system facade and address
inherited compatibility debt. Preserve the four pillars and provide a documented
path for existing consumers. Its product vision and schedule remain undecided.
The standalone integration target is 1.7.0; it does not automatically schedule a
major release or legacy removal. Follow the
[coexistence roadmap](https://github.com/Open-Neom/sint/blob/main/docs/roadmaps/design-systems-migration.md).

### Purge list

1. **Remove the entire legacy compatibility layer**: the `Get` alias,
   legacy typedefs (`GetPageBuilder`, `GetRouteAwarePageBuilder`), and all
   deprecated methods. Today they are global roots that survive conceptual
   tree-shaking and confuse new developers.
2. **Delete the dead trie** (`RouteTree`/`RouteMatcher`) — still exported
   in the public API, unused and buggy. Deprecated since 1.5.0's segment
   index made it permanently obsolete.
3. **Full internal key protocol redesign** (O5a deep): if the
   `registeredKeys` / string-key contract changes, that is breaking for
   direct consumers — 2.0.0 is the moment.
4. **`ObxError` becomes a real `Error`** and inherited semantic
   inconsistencies are cleaned up:
   - `Set.obs` copies while `List.obs`/`Map.obs` share the original
     reference → unify semantics.
   - `ListExtension.assign` appends instead of replacing on non-Rx lists.
   - Duplicate `Sint.put` silently keeps the old instance → explicit
     replace-or-throw.
5. **Rename typo files**: `obx_reacive_element.dart`, `benckmark_test.dart`
   (breaking for direct deep imports).
6. **Optional big decision — pure synchronous Rx**: a new workers API
   without streams would be the definitive performance leap, but changes
   public contracts. Evaluate against the purge cost.

### Release direction

| Release | Theme |
|---|---|
| 1.6.x | Existing release history; see CHANGELOG for completed work |
| **1.7.0** | **Opt-in standalone Material/Cupertino support with legacy compatibility** |
| 1.8.0 | Scoped Rx + codegen + Stream interop + module-aware DI |
| 1.9.0 | DevTools + Sentinel middleware + XR routing formalized |
| Future major | Product vision and breaking API decisions to be defined separately |

Every 1.x release keeps the discipline installed in 1.4.0: statistical
benchmark harness, before/after tables in the CHANGELOG, zero analyzer
warnings, and validation against at least three consumer modules before
publish.

---

*The structural advantage: SINT is sovereign and the whole ecosystem
consumes it through a single override — the pace of this roadmap is ours
to set.*
