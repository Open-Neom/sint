# SINT Roadmap — Toward 2.0.0: The Legacy Purge

> **Versioning philosophy:** The four pillars (State, Injection, Navigation,
> Translation) do not need breaking changes to evolve. The entire 1.x line is
> additive evolution — performance, web, XR, DevTools, codegen — with zero
> breaking changes. **2.0.0 is not a reinvention; it is a single purge event**
> that removes the inherited GetX debt we keep today only for backwards
> compatibility.

**Trigger criterion for 2.0.0:** when all 21+ neom_modules have gone 2+
releases without using a single deprecated symbol, the purge becomes free.
That is the day 2.0.0 ships.

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

### 1.7.0 candidates

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

## Horizon 3 — SINT 2.0.0: The Legacy Purge

A single breaking release that cuts the inherited GetX debt. No
reinvention — the pillars, APIs and mental model stay exactly as the
ecosystem already knows them.

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

### Suggested cadence

| Release | Theme |
|---|---|
| 1.6.0 | O5a Type-keyed registry + P1 performance backlog |
| 1.7.0 | AOT benchmarks + competitor baselines (+ DevTools stretch) |
| 1.8.0 | Scoped Rx + codegen + Stream interop + module-aware DI |
| 1.9.0 | DevTools + Sentinel middleware + XR routing formalized |
| **2.0.0** | **Legacy Purge** — when the trigger criterion is met |

Every 1.x release keeps the discipline installed in 1.4.0: statistical
benchmark harness, before/after tables in the CHANGELOG, zero analyzer
warnings, and validation against at least three consumer modules before
publish.

---

*The structural advantage: SINT is sovereign and the whole ecosystem
consumes it through a single override — the pace of this roadmap is ours
to set.*
