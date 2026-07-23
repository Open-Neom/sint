# Changelog - sint

## [1.5.0] - 2026-07-23

Navigation overhaul (Pillar N). All changes are additive and backwards
compatible: existing route tables, `Sint.toNamed('/path')`, `/:param`
routes, `SintPage` and middleware keep working identically.

### Feature 1 — Segment route index (O(k) matching)

`RouteParser` no longer scans the whole flat route list with a regex per
route for every cumulative path (O(segments × routes)). Routes are now
bucketed by their first segment type with the precedence
**literal > param with pattern > simple param > wildcard** (registration
order is preserved inside each bucket), and only candidate buckets are
regex-evaluated. The index rebuilds lazily and is invalidated on
add/remove (including external `routes` mutations via a length guard).
The dead experimental trie (`RouteTree`/`RouteMatcher`) stays untouched
and unused. Baseline in `test/benchmarks/BASELINE_1.4.0.md`.

Route matching (median µs/op, Dart VM JIT, 7 rounds × 1k ops):

| Benchmark                  | 1.4.0   | 1.5.0  | Δ        |
|----------------------------|--------:|-------:|---------:|
| literal match, last of 10  |  4.4390 | 3.6590 | −17.6 %  |
| param match, last of 10    |  7.3280 | 5.0290 | −31.4 %  |
| miss (unknown), 10         |  4.5190 | 1.5910 | −64.8 %  |
| literal match, last of 100 | 14.0920 | 3.3370 | −76.3 %  |
| param match, last of 100   | 25.7190 | 4.9490 | −80.8 %  |
| miss (unknown), 100        | 31.5970 | 1.5430 | −95.1 %  |

### Feature 2 — Extended route syntax

- **Pattern params**: `/user/:id(\d+)` only matches segments satisfying
  the custom constraint.
- **Wildcards**: `/docs/:path*` captures one or more remaining segments,
  `/` separators included.
- **Escaped separator (bug A4)**: the `.` in dotted params (`/file.:ext`)
  is now regex-escaped — it no longer matches any character.
- **Per-segment decoding (bug A2)**: path params are decoded with
  `Uri.decodeComponent` instead of `Uri.decodeQueryComponent` — a literal
  `+` stays a plus and `%2F` decodes to `/` after the segment split.
- **Duplicate route detection**: registering two routes that compile to
  the same pattern logs a warning via `Sint.log` (first-still-wins, no
  exception, backwards compatible).

### Feature 3 — pathParams / queryParams API

- `Sint.toNamed`, `Sint.offNamed` and `Sint.offAllNamed` accept optional
  `pathParams` and `queryParams`:
  `Sint.toNamed('/user/:id', pathParams: {'id': '42'}, queryParams: {'tab': 'posts'})`
  navigates to `/user/42?tab=posts` with correct per-segment encoding.
- `PageSettings.pathParams` / `PageSettings.queryParams` (plus
  `RouteDecoder`, `SintDelegate` and `Sint.pathParams` /
  `Sint.queryParams`) expose path and query parameters SEPARATELY.
  `Sint.parameters` keeps the legacy merged view unchanged.

### Web fixes

- **W1 — Browser back/forward**: `SintDelegate.setNewRoutePath` now diffs
  against the active stack: if the requested URL is already present it
  pops the entries above it (completing their completers through the
  normal pop path) instead of pushing a duplicate.
- **W2 — Public `SintUrlStrategy`**: `SintUrlStrategy.setPath()` /
  `SintUrlStrategy.setHash()` can be called in `main()` before `runApp()`;
  the delegate respects a pre-configured strategy.
- **W3 — State restoration**: `restoreRouteInformation` passes the route
  state instead of a hardcoded `null`, and `SintPage.copyWith` no longer
  loses `restorationId` (self-reference fixed).
- **`SintPage.copyWith` now propagates `preventDuplicateHandlingMode`**
  (latent since 1.3.1) — this activates the fixed
  `popUntilOriginalRoute` branch, now covered by an end-to-end test.

### Middleware fixes

- **M1**: `SintDelegate.runMiddleware` now honors `priority` like
  `MiddlewareRunner` — both pipelines share the same STABLE sort
  (declaration order preserved among equal priorities).
- **M4**: redirect cycles now hit a depth guard (5) with a clear
  `Redirect loop detected` error instead of looping/overflowing, in both
  the delegate pipeline and `PageRedirect`.

### Verification

`flutter test` 272/272 pass (240 from 1.4.0 + 32 new navigation tests);
`dart analyze` 0 errors, no new issues.

**Deferred to a future release**: Type-keyed injection registry
(`Map<Type, Map<String?, _InstanceBuilderFactory>>`) — the string keys of
`_getKey` are an internal protocol shared with `RouterReportManager` and
`registeredKeys` consumers in navigation; migrating them is a larger
cross-cutting change that was not worth destabilizing this release.


## [1.4.0] - 2026-07-23

Performance release — 5 P0 hot-path optimizations with before/after benchmarks
(`test/benchmarks/p0_benchmark_test.dart`, reusable harness in
`test/benchmarks/bench_harness.dart`, 1.3.1 baseline in
`test/benchmarks/BASELINE_1.3.1.md`). Internal changes only; zero public API changes.

- **O1 — No per-notification listener copy**: `ListNotifier._notifyUpdate()` no longer allocates `_updaters!.toList()` on every notification. It now iterates the listener list directly by index, guarded by a mutation version counter; a defensive copy is only paid for the remaining listeners when a reentrant add/remove is detected mid-iteration (`lib/state_manager/src/engine/list_notifier.dart`).
- **O2 — Direct `markNeedsBuild` in Obx**: `ObxReactiveElement.getUpdate()` no longer schedules a microtask per notification (N redundant microtasks per frame). `markNeedsBuild()` is idempotent and Flutter batches dirty elements into the next frame naturally (`lib/state_manager/src/ui/obx_reacive_element.dart`).
- **O3 — Lazy `_updatersGroupIds`**: every `ListNotifier` (each Rx + each controller) used to allocate an eager `HashMap` even when id-groups were never used. The map is now created with `??=` on first `addListenerId()`. Additionally, `dispose()` now disposes and clears the group notifiers, fixing a memory leak found in the audit (`lib/state_manager/src/engine/list_notifier.dart`).
- **O4 — Typed `Notifier.read`**: `void read(dynamic updaters)` → `void read(ListNotifier updaters)`, enabling static dispatch/inlining in AOT and dart2js (`lib/state_manager/src/engine/notifier.dart`).
- **O5 — Single-lookup `Sint.find` & friends**: `find`, `_initDependencies`, `_startController`, `_insert`, `_getDependency`, `markAsDirty`, `putOrFind` and `delete` each performed 2–5 map lookups of the same key; all now resolve the factory in a single lookup. Eager log string interpolation in `_startController` is now gated behind `Sint.isLogEnable` (`lib/injection/src/domain/extensions/injection_extension.dart`).

Before/after (median µs/op, Dart VM JIT, 7 rounds × 20k ops after 2k warmup):

| Benchmark                                | 1.3.1  | 1.4.0  | Δ       |
|------------------------------------------|-------:|-------:|--------:|
| Pure notification (RxInt, 1 listener)    | 0.0193 | 0.0101 | −47.7 % |
| Fan-out (0 listeners)                    | 0.0132 | 0.0077 | −41.7 % |
| Fan-out (1 listener)                     | 0.0188 | 0.0095 | −49.5 % |
| Fan-out (10 listeners)                   | 0.0682 | 0.0262 | −61.6 % |
| Fan-out (100 listeners)                  | 0.6452 | 0.2110 | −67.3 % |
| No listeners (empty path)                | 0.0149 | 0.0065 | −56.4 % |
| `Sint.find` (tagged)                     | 0.5555 | 0.3835 | −31.0 % |
| `SintController.update()` (1 listener)   | 0.0158 | 0.0070 | −55.7 % |

Verified: `flutter test` 238/238 pass (234 existing + 4 new benchmark tests);
`dart analyze` 0 errors, no new issues.


## [1.3.1] - 2026-07-22

Hotfix release — 7 high-severity fixes from the 1.3.0 audit.

- **RxnDouble subtraction**: `RxnDoubleExt.operator -` was adding instead of subtracting (`value = value! + other` → `value = value! - other`).
- **Worker timers on dispose**: `debounce` and `interval` timers are now tracked per controller and cancelled in `onClose()`, so pending callbacks never fire on an already-disposed controller.
- **SintQueue resilience**: A job throwing an `Error` (e.g. `TypeError`, not just `Exception`) no longer freezes the queue forever — the completer always completes with the error and `_active` is always released. `cancelAllJobs()` now completes pending futures with `StateError('Job cancelled')` instead of leaving them hanging.
- **popUntilOriginalRoute**: Fixed inverted condition (`==` → `!=`) that popped the original route itself instead of popping until it became current.
- **offAllNamed / offNamedUntil**: Removed pages now complete their route completers through the standard pop path, instead of leaving the original navigation futures hanging forever.
- **removeLastHistory**: Fixed unconditional self-recursion (stack overflow); it now delegates to the platform implementation (no-op where browser history does not exist).
- **Optional route params**: Routes like `/user/:id?` no longer crash with a null-assert when the optional param is absent (URL `/user`). The path separator is now part of the optional regex group and absent match groups are skipped during parameter parsing.


## Maintenance Notes — 2026-07-09 (unversioned)

Historical entries that were recorded under a duplicated/incorrect version
heading; kept here for traceability.

- Optimize transitions and layout configurations in sint_root.dart.
- Stability and compatibility updates.


## [1.3.0] - 2026-03-11

Vanity URLs & Slug Resolution — The Missing Web Piece.

### Pillar N (Navigation)

- **Vanity / Slug URL Resolution**: Fixed a long-standing GetX limitation where `unknownRoute` never triggered for single-segment URLs like `/serzenmontoya`. The root cause: `RouteParser.matchRoute()` builds cumulative paths (`['/', '/serzenmontoya']`), and since `/` always matches the root route, the tree was never empty — so `unknownRoute` was silently bypassed. SINT now detects when only a parent segment matched but the full URL did not, and correctly returns an empty tree to trigger `unknownRoute`.
- **URL-Preserving `unknownRoute`**: When an unregistered URL triggers `unknownRoute`, SINT now preserves the original URL in the route stack. `Sint.currentRoute` returns the actual requested path (e.g. `/serzenmontoya`) instead of `/not-found`. This enables catch-all resolver pages (like `SlugResolverPage`) to read the original slug and resolve it to the correct content via async lookups.

**Why this matters:** Vanity URLs (`cyberneom.xyz/serzenmontoya`, `cyberneom.xyz/events/burning-your-mind`) are essential for shareable, human-friendly links on the web. Before this fix, these URLs silently redirected to the home page. Now, they correctly route through `unknownRoute` where a resolver page can perform parallel Firestore queries to identify the content type and navigate accordingly.

**GetX comparison:** GetX explicitly documents this as a known limitation: *"any string that starts with '/' will correspond to the '/' route"*. SINT 1.3.0 solves this without breaking existing route matching.

```dart
// Register a catch-all resolver as unknownRoute
SintMaterialApp(
  initialRoute: '/',
  unknownRoute: SintPage(name: '/not-found', page: () => SlugResolverPage()),
  sintPages: [
    SintPage(name: '/', page: () => HomePage()),
    SintPage(name: '/book/:bookId', page: () => BookDetail()),
    // ... registered routes
  ],
)

// In SlugResolverPage — read the original vanity URL
final slug = Sint.currentRoute.replaceFirst('/', '');
// → 'serzenmontoya' (not '/not-found')

// Resolve the slug against your data layer
final match = await SlugRouter.resolve(slug);
// → profile, item, event, band, post, etc.
```

---

## [1.2.2] - 2026-02-28

- **CHANGELOG sync**: Turns out an AI that manages State, Injection, Navigation & Translation still can't manage to update the CHANGELOG *before* hitting publish. Lesson learned. Version and CHANGELOG now walk into pub.dev together, holding hands. It won't happen again. Probably.

---

## [1.2.1] - 2026-02-28

- **README images**: Switched to absolute GitHub raw URLs so images render correctly on pub.dev (`.pubignore` excludes PNGs from the package).

---

## [1.2.0] - 2026-02-28

RESTful Navigation & i18n URL Routing.

133 lines of new code. Zero new dependencies. Pillars N and T upgraded.

### Pillar N (Navigation)

- **RESTful Route Parameters** (Spring Boot-inspired API):
  - `Sint.routeParam` — Primary path parameter value. For route `/book/:bookId` navigated as `/book/abc123`, returns `'abc123'`. Equivalent to Spring Boot's `@PathVariable`.
  - `Sint.pathParam('bookId')` — Named path parameter. Equivalent to `@PathVariable("bookId")`.
  - `Sint.queryParam('page')` — Query parameter from URL. Equivalent to `@RequestParam`.
  - `Sint.queryParamOrDefault('sort', 'recent')` — Query parameter with fallback. Equivalent to `@RequestParam(defaultValue = "recent")`.
  - Full test mode support via `SintTestMode`.
- **`translateEndpoints` flag**: New parameter on `SintMaterialApp` and `ConfigData` that enables automatic i18n URL routing. When `true`, SINT builds a `PathTranslator` from registered translations and routes.
- **`setUrlStrategy()` resilience**: Wrapped in try-catch to handle "URL strategy already set" when the Flutter engine is already initialized — prevents web startup crashes on hot restart.

### Pillar T (Translation)

- **`PathTranslator`** — New class for internationalized URL routing:
  - `canonicalizePath()` — Converts localized URLs to canonical English before route matching. e.g. `/libro/abc123` → `/book/abc123`.
  - `localizePath()` — Converts canonical URLs to the current locale for the browser URL bar. e.g. `/book/abc123` → `/libro/abc123` (ES) or `/livre/abc123` (FR).
  - `extractSegments()` — Automatically extracts static route segments from registered `SintPage` names (skips `:param` segments).
  - Built-in diacritics normalization (`Publicación` → `publicacion`) for clean URLs.
  - Zero-config: built automatically from existing app translations when `translateEndpoints: true`. No external localization file needed.
- **`Sint.pathTranslator`** — Getter/setter on the `SintInterface` to access the URL translator. Stored in `IntlHost` and cleaned up on `SintRoot.onClose()`.
- **`SintInformationParser` integration** — Automatic canonicalization on `parseRouteInformation()` and localization on `restoreRouteInformation()`. Browser URL bar shows localized paths; internal routing uses canonical English.

### Housekeeping

- **Example app**: Added `example/main.dart` demonstrating all four SINT pillars (State, Injection, Navigation, Translation) in a counter app. Targets 160/160 pub points.
- **TickerMode.of deprecation**: Suppressed for cross-SDK compatibility in `RxTickerProviderMixin`.

---

## [1.1.0] - 2026-02-26

The Four Pillars Evolve — Workers, Pattern Matching, Async DI & Web-Safe Navigation.

175 lines of new code. Zero new dependencies. All four pillars upgraded.

### Pillar S (State Management)

- **Reactive Workers**: Added `ever()`, `once()`, `debounce()`, and `interval()` to `SintController`. Built on top of the existing `Rx.listen()` engine with automatic lifecycle management — all subscriptions auto-cancel on `onClose()`.
- **SintStatus Pattern Matching**: Added `.when()` and `.maybeWhen()` exhaustive pattern matching to `SintStatus<T>`, plus convenience getters (`.isLoading`, `.isSuccess`, `.isError`, `.isEmpty`, `.dataOrNull`, `.errorOrNull`). Inspired by Riverpod's `AsyncValue`.
- **SintListener Widget**: New widget that listens to `Rx` changes and executes a callback without rebuilding the widget tree. Equivalent to BLoC's `BlocListener` — ideal for side effects like snackbars, navigation triggers, and logging.

### Pillar I (Injection)

- **`putAsync<S>()`**: Async dependency registration for services that require `Future`-based initialization (SharedPreferences, databases, HTTP clients). Equivalent to GetIt's `registerSingletonAsync`.
- **`InjectionExtension.registeredKeys`**: Exposed registered dependency keys for internal selective cleanup operations.

### Pillar N (Navigation)

- **`SintSnackBarStyle`**: Global snackbar styling via `SintMaterialApp(snackBarStyle: ...)`. Defines default visual properties (colors, margins, durations, position, etc.) that apply to every `Sint.snackbar()` call. Three-level cascade: call-site parameters > global style > hardcoded defaults.
- **Web-Safe `back()`**: Integrated web-aware logic directly into `Sint.back()`. On web, if there's no internal navigation history to pop, it gracefully does nothing instead of crashing — the browser's back/forward arrows handle it.
- **`toInitial()` Hard Reset**: Performs a full app reset — deletes all non-permanent controllers (`onClose()` called on each), then reloads `initialRoute` from scratch. Supports selective preservation via `keep` parameter: `Sint.toInitial(keep: {AuthController})`.
- **`Sint.isWeb`**: Platform detection shortcut.
- **`Sint.showBackButton`**: Returns `false` on web (browser has native arrows), `true` on mobile.
- **Web Fade Transition**: Default `Transition.fade` on web for GPU-light performance (vs heavy Cupertino/Zoom).
- **Web Scroll Behavior**: Enabled drag scrolling for touch, mouse, and trackpad on web by default.
- **Deprecated `webBack()`**: Logic merged into `back()`. Use `Sint.back()` directly.
- **Deprecated `home` property**: In `SintMaterialApp`, `ConfigData`, and `SintRoot`. Use `initialRoute` + `sintPages` instead.

### Pillar T (Translation)

- **`loadTranslations()`**: Async lazy-loading of translations per module/feature. Merges with existing translations without replacing them — built on top of the existing `appendTranslations()` engine.

### Performance (v1.1.0 Benchmarks)

| Pillar | Operation | Avg Time |
|--------|-----------|----------|
| S | Reactive `.obs` update | 0.09 us/op |
| S | Simple `update()` | 0.11 us/op |
| I | `find()` with 10 tags | 1.34 us/find |
| T | `trParams()` interpolation | 2.65 us/op |

---

## [1.0.0] - 2026-02-01

The Birth of SINT (Initial Stable Release).
SINT 1.0.0 is a hard fork and Clean Architecture evolution of GetX (v5.0.0-rc). This version marks the transition from a "do-everything" framework to a "do the right things" infrastructure, focused exclusively on four pillars: State, Injection, Navigation, and Translation.

### Key Architectural Changes

- Massive Code Pruning: Removed 7,766 lines of code (~37.7%) by stripping away non-core features like the HTTP client, animations, and unused string validators.
- Clean Architecture Restructuring: Reorganized the entire codebase into a modular domain/engine/ui structure for every pillar, replacing the legacy flat-file layout.
- Pillar Consolidation: Unified the framework into 5 core modules (core, injection, navigation, state_manager, translation) instead of the original 9+ scattered directories.
- Reactive Sovereignty: Consolidated all reactive types (Rx) into the core/ module and moved platform detection into the navigation/ module where it is actually consumed.

### Compatibility & Migration

- Legacy Bridge: Included a deprecated Get alias to allow a seamless migration for existing apps.
- Single Entry Point: All pillars are now accessible through a single, clean import: `package:sint/sint.dart`.

### Documentation & Global Ready

- Standardized Documentation: Shipped with complete guides for each of the four pillars in 12 languages, ensuring global adoption across the Open Neom ecosystem.
