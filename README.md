# SINT

<p align="center">
  <img src="https://raw.githubusercontent.com/Open-Neom/sint/main/assets/SINT%20-%20Logo%20-%202026.png" alt="SINT Framework" width="280"/>
</p>

**State, Injection, Navigation, Translation — The Four Pillars of High-Fidelity Flutter Infrastructure.**

[![pub package](https://img.shields.io/pub/v/sint.svg?label=sint&color=blue)](https://pub.dev/packages/sint)

<div align="center">

**Languages:**

[![English](https://img.shields.io/badge/Language-English-blueviolet?style=for-the-badge)](#)
[![Spanish](https://img.shields.io/badge/Language-Spanish-blueviolet?style=for-the-badge)](documentation/es_ES/README.md)
[![Arabic](https://img.shields.io/badge/Language-Arabic-blueviolet?style=for-the-badge)](documentation/ar_EG/README.md)
[![French](https://img.shields.io/badge/Language-French-blueviolet?style=for-the-badge)](documentation/fr_FR/README.md)
[![Portuguese](https://img.shields.io/badge/Language-Portuguese-blueviolet?style=for-the-badge)](documentation/pt_BR/README.md)
[![Russian](https://img.shields.io/badge/Language-Russian-blueviolet?style=for-the-badge)](documentation/ru_RU/README.md)
[![Japanese](https://img.shields.io/badge/Language-Japanese-blueviolet?style=for-the-badge)](documentation/ja_JP/README.md)
[![Chinese](https://img.shields.io/badge/Language-Chinese-blueviolet?style=for-the-badge)](documentation/zh_CN/README.md)
[![Korean](https://img.shields.io/badge/Language-Korean-blueviolet?style=for-the-badge)](documentation/kr_KO/README.md)
[![Indonesian](https://img.shields.io/badge/Language-Indonesian-blueviolet?style=for-the-badge)](documentation/id_ID/README.md)
[![Turkish](https://img.shields.io/badge/Language-Turkish-blueviolet?style=for-the-badge)](documentation/tr_TR/README.md)
[![Vietnamese](https://img.shields.io/badge/Language-Vietnamese-blueviolet?style=for-the-badge)](documentation/vi_VI/README.md)

</div>

---

- [About SINT](#about-sint)
- [Material and Cupertino Migration Notice](#material-and-cupertino-migration-notice)
- [1.7.0 Development Preview](#170-development-preview)
- [What's New in 1.6.2](#whats-new-in-162)
- [What's New in 1.6.1](#whats-new-in-161)
- [What's New in 1.6.0](#whats-new-in-160)
- [What's New in 1.5.0](#whats-new-in-150)
- [What's New in 1.4.0](#whats-new-in-140)
- [What's New in 1.3.1](#whats-new-in-131)
- [What's New in 1.3.0](#whats-new-in-130)
- [What's New in 1.2.0](#whats-new-in-120)
- [What's New in 1.1.0](#whats-new-in-110)
- [Installing](#installing)
- [The Four Pillars](#the-four-pillars)
  - [State Management (S)](#state-management-s)
  - [Injection (I)](#injection-i)
  - [Navigation (N)](#navigation-n)
  - [Translation (T)](#translation-t)
- [Flutter Web & Deep Links](#flutter-web--deep-links)
- [Counter App with SINT](#counter-app-with-sint)
- [Migration from GetX](#migration-from-getx)
- [Origin & Philosophy](#origin--philosophy)

---

## About SINT

SINT is an architectural evolution of GetX (v5.0.0-rc), built as a focused framework around four pillars only:

| Pillar | Responsibility |
|---|---|
| **S** — State Management | `SintController`, `SintBuilder`, `Obx`, `.obs`, Rx types, Workers, `SintStatus`, `SintListener` |
| **I** — Injection | `Sint.put`, `Sint.find`, `Sint.lazyPut`, `Sint.putAsync`, Bindings, SmartManagement |
| **N** — Navigation | `SintPage`, `Sint.toNamed`, `Sint.toInitial`, `routeParam`, `pathParam`, `queryParam`, `pathParams`/`queryParams` API, pattern params & wildcards, O(k) route index, middleware, `SintMaterialApp`, `SintSnackBarStyle`, `SintUrlStrategy`, web-safe `back()` |
| **T** — Translation | `.tr` extension, `Translations` class, locale management, `loadTranslations`, `PathTranslator`, `translateEndpoints` |

Everything outside these four pillars has been removed: no HTTP client, no animations, no string validators, no generic utilities. The result is **37.7% less code** than GetX — 12,849 LOC vs 20,615 LOC.

**Key principles:**

- **PERFORMANCE:** Direct synchronous notifications for widgets; lazy asynchronous streams for `listen` and workers. Measure both paths separately.
- **PRODUCTIVITY:** Simple syntax. One import: `import 'package:sint/sint.dart';`
- **ORGANIZATION:** Clean Architecture structure. 5 modules, each mapping to a pillar.

---

## Material and Cupertino Migration Notice

> **Local development preview: SINT 1.7.0-dev.1.**
> `SintApp` provides standalone Material/Cupertino hosts in the current source.
> This is development status, not a claim that a stable release is published.
> This version requires **Flutter >=3.44.0 / Dart >=3.12.0**, including when
> using the legacy application classes.

`SintApp` selects Cupertino on iOS and Material on other target platforms. Set
`design: SintDesign.material` or `SintDesign.cupertino` to override that choice.
On web, automatic selection follows the browser's target platform. Configure
`materialTheme` with `material_ui.ThemeData` and `cupertinoTheme` with
`cupertino_ui.CupertinoThemeData`; a platform check does not convert these types.

The existing `SintMaterialApp` and `SintCupertinoApp` keep their SDK types.
`SintApp(theme: sdkTheme)` temporarily uses the legacy Material host and emits
a targeted `@Deprecated` analyzer diagnostic directing users to the new theme
arguments. Do not combine that legacy parameter with standalone themes. There
is no announced removal date. State, injection and translation are unaffected.

The [migration guide](MIGRATION_DESIGN_SYSTEMS.md) documents current imports,
working API shapes, theme operations, compatibility bridges and validation
requirements. Separate adapter packages are not required by this implementation.
Flutter's SDK-library migration schedule is separate from SINT's support policy;
see the [Flutter announcement](https://flutter.dev/blog/whats-new-in-flutter-3-47).

## 1.7.0 Development Preview

- `SintApp` and `SintApp.router` share the existing SINT root, registry and router
  while choosing a standalone design-system host.
- Typed Material/Cupertino theme configuration, queries and runtime theme setters
  coexist with legacy APIs; automatic host selection does not rewrite page widgets.
- Temporary legacy compatibility bridges are enabled by default for gradual
  migration. Their theme mapping does not convert public types or every component
  theme. Validate package subtrees before opting out.
- The SDK requirement rises from the 1.6.2 baseline of Flutter 3.32 / Dart 3.8 to
  Flutter 3.44 / Dart 3.12 because the standalone packages are direct dependencies.
- Pilot validation targets Cyberneom and Giglab on Android, macOS and web. A
  successful widget test or analyzer run does not by itself establish successful
  native/web application builds or runtime behavior.

The following version sections describe historical releases and their own SDK
requirements, not the requirement of this development preview.

## What's New in 1.6.2

**Focus: correctness under listener mutation, overlapping route lifecycles, and reproducible measurement.**

- Listener removal during dispatch no longer skips unrelated callbacks or throws. Additions wait for the next notification; each disposer owns exactly one registration.
- Streams reconnect after the last subscriber cancels. Closing an Rx releases its upstream `bindStream` subscriptions. `SintListener` handles callback changes and distinct Rx objects with equal values.
- Collection assignments snapshot lazy/self-referencing iterables before mutation and notify once, only when needed.
- DI uses type identity throughout registration, lookup and disposal. Route ownership captures each registration generation, so an old route cannot close its replacement. Disposing M dependencies now performs O(M) registry work, excluding application lifecycle callbacks.
- Nested routes register each descendant once; matching and URL generation share a tokenizer for optional/dotted parameters, patterns, wildcards and literal escaping. Path parameters are separate from query parameters.
- Benchmarks validate their results, retain raw samples and report **batch means**, not individual-operation p95 latency. See [benchmark methodology](test/benchmarks/README.md).

Compatibility notes:

- Requires **Flutter >=3.32 / Dart >=3.8**, aligning the declared floor with APIs and development dependencies already used by the package.
- `RouteParser` snapshots its constructor list. Change routes through `parser.routes`, `registeredRoutes`, or add/remove APIs; later edits to the original input list are not observed. Mutations through the exposed list invalidate the index even when its length stays the same.
- Traditional DI string keys remain usable when unambiguous. `registeredKeys` returns opaque handles for collisions; use those handles or typed APIs. Ambiguous legacy `delete(key:)`, `reload(key:)` and `markAsDirty(key:)` calls throw `StateError` instead of modifying the wrong registration. Treat keys as opaque, not type-name prefixes.

## What's New in 1.6.1

**Focus: Direct DI entry removal, collection assignment hardening, and engine hygiene.**

- **Direct DI entry removal (Pillar I):** Stored the reified generic type for direct registry removal. This did not eliminate the route manager's repeated list scans; total route cleanup remained quadratic until 1.6.2.
- **Conditional `assign` & `assignAll` (Pillar S):** `RxList.assign` and `RxList.assignAll` now verify existing length and items before notifying, avoiding UI rebuild cascades when incoming collections are identical.
- **Collection Hardening:** Fixed `ListExtension.assign`/`assignAll` on standard lists to clear prior to insertion, and added conditional refresh to `RxSet`.
- **Engine Hygiene:** Added `sint_builder.dart` and `obx_reactive_element.dart` with correct naming conventions while keeping backwards-compatible legacy re-exports.

Historical timing tables are retained in the changelog as unverified historical reports, not current performance guarantees. The old "Depth: 10" test performed a flat tagged lookup, not recursive dependency resolution.

---

## What's New in 1.6.0

**Focus: Type-Keyed Injection (O5a) & Reactive Engine Overhaul — O(1) type-identity dependency lookup, conditional refresh on collections, Obx stale subscription cleanup, and synapse state hardening.**

### Type-Keyed Injection Registry (O5a)

Dependency injection introduced a two-tiered Type-indexed registry (`Map<Type, Map<String?, _InstanceBuilderFactory>>`), avoiding type-name string concatenation on `Sint.find<T>()`. The remaining legacy string-key registration/disposal collisions were fixed in 1.6.2; a native benchmark does not establish web/Wasm performance.

The original seven-sample harness measured batch averages. Its "p95" label did not represent individual-operation tail latency and should not be used as such.

### Collection Conditional Refresh (Pillar S)

`RxList` and `RxMap` now perform dirty checks before firing reactive notifications. Operations like `[]=`, `remove`, `removeWhere`, `retainWhere`, `clear`, and `length=` only notify observers when elements or size truly change, avoiding redundant widget rebuilds.

### Obx Rebuild Hygiene & Synapse Hardening

`ObxReactiveElement.build()` now disposes subscriptions from the previous frame before tracking active observables, eliminating phantom rebuilds when UI branches change. `Notifier.append` is protected with `try ... finally` to ensure synapse state integrity during builder exceptions.

---

## What's New in 1.5.0

**Focus: Navigation overhaul — O(k) route matching, extended route syntax, pathParams/queryParams API and real browser-history sync. All additive and backwards compatible.**

### Segment Route Index (O(k) matching)

Route matching no longer scans the full route table with one regex per route. Routes are indexed by their first segment type with the precedence **literal > param with pattern > simple param > wildcard** (registration order preserved inside each bucket):

| Benchmark (median µs/op) | 1.4.0 | 1.5.0 | Δ |
|---|--:|--:|--:|
| Param match, last of 10 routes | 7.33 | 5.03 | −31.4% |
| Literal match, last of 100 routes | 14.09 | 3.34 | **−76.3%** |
| Param match, last of 100 routes | 25.72 | 4.95 | **−80.8%** |
| Unknown route (miss), 100 routes | 31.60 | 1.54 | **−95.1%** |

The first-segment index reduces the candidates examined, but cost still depends on bucket size. A table of routes sharing `/api/...` can require scanning the whole bucket; matching is not independent of route count. The historical table above covers distinct-prefix workloads only.

### Extended Route Syntax

```dart
sintPages: [
  SintPage(name: '/user/:id(\\d+)', page: () => UserDetail()),  // pattern param: digits only
  SintPage(name: '/docs/:path*', page: () => DocsViewer()),     // wildcard: captures /docs/a/b/c
  SintPage(name: '/user/:id?', page: () => Profile()),          // optional param
]
```

Plus three correctness fixes for slugs: `+` in a path param stays a plus (no longer decoded as a space), `%2F` decodes correctly per segment, dotted params like `/file.:ext` escape the separator, and duplicate route registrations log a warning (first-still-wins).

### pathParams / queryParams API

```dart
// Navigate with structured parameters — correct encoding included
Sint.toNamed('/user/:id',
  pathParams: {'id': '42'},
  queryParams: {'tab': 'posts'},
);
// → /user/42?tab=posts

// Read them separately
String? id  = Sint.pathParams['id'];      // path parameters only
String? tab = Sint.queryParams['tab'];    // query parameters only
// Sint.parameters keeps the legacy merged view unchanged
```

### Web: Browser History Sync & State Restoration

- **Back/forward buttons**: `setNewRoutePath` now diffs the requested URL against the active stack — navigating back to a URL already in the stack pops the entries above it instead of pushing a duplicate.
- **Public URL strategy**: call `SintUrlStrategy.setPath()` (or `setHash()`) in `main()` before `runApp()` — no more late, silently-failing configuration inside the delegate.
- **State restoration**: route state is now passed through `restoreRouteInformation`, and `SintPage.copyWith` no longer loses `restorationId` or `preventDuplicateHandlingMode`.
- **Middleware**: both pipelines honor `priority` with a stable sort, and redirect cycles now fail fast with a clear `Redirect loop detected` error instead of a stack overflow.

See [CHANGELOG.md](CHANGELOG.md) for the full list of changes.

---

## What's New in 1.4.0

**Focus: Hot-path performance — 5 internal optimizations, zero API changes, measured before/after.**

| Benchmark (median µs/op) | 1.3.1 | 1.4.0 | Δ |
|---|--:|--:|--:|
| Reactive `.obs` notification (1 listener) | 0.0193 | 0.0101 | **−47.7%** |
| Fan-out (100 listeners) | 0.6452 | 0.2110 | **−67.3%** |
| Assignment without listeners | 0.0149 | 0.0065 | **−56.4%** |
| `Sint.find` (tagged) | 0.5555 | 0.3835 | **−31.0%** |
| `SintController.update()` | 0.0158 | 0.0070 | **−55.7%** |

- **No per-notification listener copy** — direct iteration was introduced here; 1.6.2 replaces its unsafe mutation-counter logic with per-registration entries and deferred compaction.
- **Direct `markNeedsBuild` in Obx** — no more one-microtask-per-notification; Flutter batches rebuilds into the frame naturally.
- **Lazy `_updatersGroupIds`** — every Rx and controller used to allocate an eager `HashMap`; now created on first use (and `dispose()` clears groups, fixing a memory leak).
- **Typed `Notifier.read`** — enables static dispatch/inlining in AOT and dart2js (Flutter Web).
- **Single-lookup `Sint.find`** — from 4–5 map lookups per call down to one, across `find`, `put`, `delete` and friends.

The original harness used warmup and seven rounds. Its historical numbers above are unverified across environments; 1.6.2 adds raw artifacts, workload validation and explicit batch-average labels.

---

## What's New in 1.3.1

**Focus: Stability — 7 high-severity hotfixes, each with regression tests.**

- `Rx<double?>` subtraction operator was adding instead of subtracting — silent data corruption fixed.
- `debounce`/`interval` worker timers are now cancelled in `onClose()` — no more callbacks firing on disposed controllers.
- `SintQueue` no longer freezes when a job throws an `Error` (not just `Exception`), and `cancelAllJobs()` completes pending futures instead of leaving them hanging.
- `popUntilOriginalRoute` inverted condition fixed; `offAllNamed`/`offNamedUntil` now complete navigation futures; `removeLastHistory` infinite recursion fixed; optional route params (`/user/:id?` + URL `/user`) no longer crash.

---

## What's New in 1.3.0

**Focus: Vanity URLs & Slug Resolution — the missing web piece.**

### Vanity / Slug URL Resolution

Single-segment vanity URLs now route correctly through `unknownRoute`:

```dart
SintMaterialApp(
  initialRoute: '/',
  unknownRoute: SintPage(name: '/not-found', page: () => SlugResolverPage()),
  sintPages: [
    SintPage(name: '/', page: () => HomePage()),
    SintPage(name: '/book/:bookId', page: () => BookDetail()),
  ],
)

// User visits: https://myapp.com/serzenmontoya
// Before 1.3.0: silently redirected to HomePage (GetX bug)
// After 1.3.0:  routes to SlugResolverPage with original URL preserved
```

**The problem (inherited from GetX):** Any URL starting with `/` matched the root route `/`, so `unknownRoute` never triggered for paths like `/serzenmontoya`. GetX documents this as: *"any string that starts with '/' will correspond to the '/' route"*. SINT 1.3.0 fixes this.

### URL-Preserving unknownRoute

When `unknownRoute` fires, `Sint.currentRoute` now returns the **original requested URL** — not `/not-found`:

```dart
// In your SlugResolverPage
final currentRoute = Sint.currentRoute;  // '/serzenmontoya' ✓ (not '/not-found')
final slug = currentRoute.replaceFirst('/', '').split('/').first;

// Resolve the slug against your backend
final match = await MySlugRouter.resolve(slug);
if (match != null) {
  Sint.offAllNamed(match.targetRoute);
}
```

This enables **catch-all resolver pages** that read the original slug and perform async lookups (Firestore, API, etc.) to identify the content type and navigate to the correct page.

See [CHANGELOG.md](CHANGELOG.md) for the full list of changes.

---

## What's New in 1.2.0

**Focus: Flutter Web, Deep Links & i18n URL Routing — without breaking mobile.**

### RESTful Route Parameters

Spring Boot-inspired parameter extraction that works identically on mobile and web:

```dart
// Define routes with path parameters (same as before)
SintPage(name: '/book/:bookId', page: () => BookDetail()),
SintPage(name: '/shop/product/:productId', page: () => ProductPage()),

// Navigate (works on all platforms)
Sint.toNamed('/book/abc123');
Sint.toNamed('/shop/product/42?color=red&size=lg');

// Extract parameters — clean API, no manual parsing
String? bookId    = Sint.routeParam;                       // 'abc123'
String? productId = Sint.pathParam('productId');           // '42'
String? color     = Sint.queryParam('color');              // 'red'
String  size      = Sint.queryParamOrDefault('size', 'm'); // 'lg'
```

| Method | Equivalent (Spring Boot) | Description |
|--------|--------------------------|-------------|
| `Sint.routeParam` | `@PathVariable` | First path parameter value |
| `Sint.pathParam('id')` | `@PathVariable("id")` | Named path parameter |
| `Sint.queryParam('q')` | `@RequestParam` | Query string parameter |
| `Sint.queryParamOrDefault('sort', 'asc')` | `@RequestParam(defaultValue)` | Query with fallback |

All four methods support `SintTestMode` for unit testing without a running app.

### i18n URL Routing (translateEndpoints)

Localized URLs in the browser address bar — zero configuration beyond what you already have:

```dart
SintMaterialApp(
  translateEndpoints: true,  // Enable URL localization
  translationsKeys: AppTranslations.keys,
  locale: Locale('es'),
  sintPages: [
    SintPage(name: '/book/:bookId', page: () => BookDetail()),
    SintPage(name: '/event/:eventId', page: () => EventDetail()),
  ],
)
```

Your existing translations automatically power the URL routing:

```dart
// In your translations file — no extra config needed
'es': { 'book': 'libro', 'event': 'evento', ... }
'fr': { 'book': 'livre', 'event': 'evenement', ... }
'de': { 'book': 'buch', 'event': 'veranstaltung', ... }
```

Result:

| Locale | Browser URL | Internal Route |
|--------|-------------|----------------|
| EN | `/book/abc123` | `/book/abc123` |
| ES | `/libro/abc123` | `/book/abc123` |
| FR | `/livre/abc123` | `/book/abc123` |
| DE | `/buch/abc123` | `/book/abc123` |

**How it works:**

1. `PathTranslator` is built automatically from your registered routes + translations
2. Incoming URLs are canonicalized before route matching (`/libro/x` → `/book/x`)
3. Outgoing URLs are localized for the browser bar (`/book/x` → `/libro/x`)
4. Diacritics are normalized automatically (`Publicación` → `publicacion`)
5. On mobile, `translateEndpoints` has zero overhead — path translation only activates for web URL parsing

### Global Snackbar Theming

Define snackbar appearance once, apply everywhere:

```dart
SintMaterialApp(
  snackBarStyle: SintSnackBarStyle(
    backgroundColor: Colors.grey[900],
    colorText: Colors.white,
    borderRadius: 12,
    margin: EdgeInsets.all(16),
    snackPosition: SnackPosition.bottom,
    duration: Duration(seconds: 3),
  ),
)

// All snackbar calls inherit the global style
Sint.snackbar('Title', 'Message');
// Call-site params still override when needed
Sint.snackbar('Error', 'Failed', backgroundColor: Colors.red);
```

Three-level cascade: **call-site > global style > hardcoded defaults**.

See [CHANGELOG.md](CHANGELOG.md) for the full list of changes.

---

## What's New in 1.1.0

### Reactive Workers

Auto-cancelling reactive listeners on `SintController`:

```dart
class SearchController extends SintController {
  final query = ''.obs;

  @override
  void onInit() {
    super.onInit();
    debounce(query, (q) => fetchResults(q));       // Wait 400ms after typing stops
    once(query, (_) => analytics.track('search'));  // Fire once, then auto-cancel
    ever(query, (q) => print('Query: $q'));         // Every change
    interval(query, (q) => save(q));                // Max once per second
  }
}
// All subscriptions auto-cancel on onClose(). Zero cleanup code.
```

### SintStatus Pattern Matching

Exhaustive `.when()` and `.maybeWhen()` on `SintStatus<T>`:

```dart
final status = SintStatus<User>.loading().obs;

Obx(() => status.value.when(
  loading: () => CircularProgressIndicator(),
  success: (user) => Text(user.name),
  error: (err) => Text('$err'),
  empty: () => Text('No data'),
));

// Convenience: status.value.isLoading, .dataOrNull, .errorOrNull
```

### SintListener

React to state without rebuilding (like BLoC's `BlocListener`):

```dart
SintListener<String>(
  rx: controller.errorMsg,
  listener: (msg) => Sint.snackbar(msg),
  child: MyPage(),
)
```

### Async DI

```dart
await Sint.putAsync<SharedPreferences>(
  () => SharedPreferences.getInstance(),
);
final prefs = Sint.find<SharedPreferences>();
```

### Hard Reset Navigation

```dart
Sint.toInitial();                                    // Full reset
Sint.toInitial(keep: {AuthController});              // Keep auth alive
```

### Lazy Translation Loading

```dart
await Sint.loadTranslations(() async {
  final json = await rootBundle.loadString('assets/i18n/shop_es.json');
  return {'es': Map<String, String>.from(jsonDecode(json))};
});
```

See [CHANGELOG.md](CHANGELOG.md) for the full list of changes.

---

## Installing

Add SINT to your `pubspec.yaml`:

```yaml
dependencies:
  sint: ^1.6.2
```

Import it:

```dart
import 'package:sint/sint.dart';
```

---

## High-Fidelity Performance (Benchmarks)

See [benchmark methodology](test/benchmarks/README.md) for the serial runner, raw JSON artifacts and comparison tool, and [the performance app](performance/README.md) for profile/release frame measurements.

The suite distinguishes synchronous listener dispatch from asynchronous stream delivery; covers DI lookup and route disposal separately; and tests both distinct and shared route prefixes. Every workload asserts its observable outcome. Reported microbenchmark statistics describe means of timed batches, not frame times or per-operation tail latency.

CI separates correctness/coverage from serial benchmarks. Timing regressions require comparable machine, SDK, harness and execution-mode metadata plus an explicit budget; shared-runner noise is not a reliable universal pass/fail threshold. No comparative BLoC speed claim is made without an equivalent, executable benchmark.

---

## The Four Pillars

<p align="center">
  <img src="https://raw.githubusercontent.com/Open-Neom/sint/main/assets/SINT%20-%20Framework%20-%202026.png" alt="SINT — The Four Pillars" width="700"/>
</p>

### State Management (S)

Two approaches: **Reactive** (`.obs` + `Obx`) and **Simple** (`SintBuilder`).

```dart
// Reactive
var count = 0.obs;
Obx(() => Text('${count.value}'));

// Simple
SintBuilder<Controller>(
  builder: (_) => Text('${_.counter}'),
)
```

**Workers** for reactive side effects:

```dart
ever(rx, callback);       // Every change
once(rx, callback);       // First change only
debounce(rx, callback);   // After pause (400ms default)
interval(rx, callback);   // Max once per duration (1s default)
```

**SintStatus** for async state:

```dart
status.value.when(
  loading: () => spinner,
  success: (data) => content(data),
  error: (err) => errorView(err),
  empty: () => emptyView,
);
```

[Full documentation](documentation/en_US/state_management.md)

### Injection (I)

Dependency injection without context:

```dart
Sint.put(AuthController());
Sint.lazyPut(() => ApiService());
await Sint.putAsync(() => SharedPreferences.getInstance());

final controller = Sint.find<AuthController>();
```

[Full documentation](documentation/en_US/injection_management.md)

### Navigation (N)

Route management without context — O(k) route matching, optimized for web deep links and mobile alike:

```dart
SintMaterialApp(
  initialRoute: '/',
  translateEndpoints: true,                          // i18n URLs (web)
  snackBarStyle: SintSnackBarStyle(...),              // Global theming
  sintPages: [
    SintPage(name: '/', page: () => Home()),
    SintPage(name: '/book/:bookId', page: () => BookDetail()),
    SintPage(name: '/user/:id(\\d+)', page: () => UserDetail()), // pattern param
    SintPage(name: '/docs/:path*', page: () => DocsViewer()),    // wildcard
    SintPage(name: '/search', page: () => Search()),
  ],
)

// Navigation
Sint.toNamed('/book/abc123?ref=home');
Sint.toNamed('/user/:id',
  pathParams: {'id': '42'},
  queryParams: {'tab': 'posts'},
);                                                   // → /user/42?tab=posts
Sint.back();                                         // Web-safe
Sint.toInitial();                                    // Hard reset to home
Sint.toInitial(keep: {AuthController});              // Keep specific controllers

// RESTful parameter extraction
String? id   = Sint.routeParam;                      // 'abc123'
String? id   = Sint.pathParam('bookId');              // 'abc123'
String? ref  = Sint.queryParam('ref');                // 'home'
String  sort = Sint.queryParamOrDefault('sort', 'a'); // 'a' (default)

// Path and query parameters, separated
String? uid  = Sint.pathParams['id'];                 // path params only
String? tab  = Sint.queryParams['tab'];               // query params only

// Snackbar with global style
Sint.snackbar('Title', 'Message');
```

Route syntax precedence: **literal > param with pattern > simple param > wildcard** (registration order preserved within each kind).

[Full documentation](documentation/en_US/navigation_management.md)

### Translation (T)

Internationalization with `.tr` — now powers URL routing too:

```dart
Text('hello'.tr);
Text('welcome'.trParams({'name': 'Serzen'}));
Sint.updateLocale(Locale('es', 'ES'));

// Lazy loading per module
await Sint.loadTranslations(() async {
  final json = await rootBundle.loadString('assets/i18n/shop.json');
  return {'es': Map<String, String>.from(jsonDecode(json))};
});

// URL path translation (automatic when translateEndpoints: true)
// Your translation keys double as URL segment mappings:
//   'book' → 'libro' (ES), 'livre' (FR), 'buch' (DE)
//
// PathTranslator handles:
//   canonicalizePath('/libro/abc')  → '/book/abc'   (incoming)
//   localizePath('/book/abc', 'es') → '/libro/abc'  (outgoing)
```

[Full documentation](documentation/en_US/translation_management.md)

---

## Flutter Web & Deep Links

SINT is designed with a **web-first, mobile-safe** philosophy. Every feature works identically across platforms, but web gets extra optimizations:

| Feature | Web Behavior | Mobile Behavior |
|---------|-------------|-----------------|
| `Sint.back()` | No-op if no internal history (browser arrows handle it) | Standard `Navigator.pop()` |
| `Sint.routeParam` | Extracted from browser URL path | Extracted from route arguments |
| `Sint.queryParam()` | Extracted from URL query string `?key=value` | Extracted from route arguments |
| `translateEndpoints` | Localizes browser URL bar + canonicalizes incoming URLs | No overhead — flag is ignored |
| Vanity / slug URLs | `unknownRoute` fires correctly for `/slug` paths; original URL preserved | Same behavior via deep links |
| Browser back/forward | Synced with internal stack — revisiting a URL pops to it instead of duplicating | Standard stack behavior |
| URL strategy | `SintUrlStrategy.setPath()` / `setHash()` in `main()` before `runApp()` | Ignored (no browser URL) |
| State restoration | Route state passed through `restoreRouteInformation` | Same |
| `Sint.showBackButton` | `false` (browser has native arrows) | `true` |
| Default transition | `Transition.fade` (GPU-light for web canvas) | Platform default (Cupertino/Material) |
| Scroll behavior | Drag enabled for touch, mouse, and trackpad | Platform default |
| `SintSnackBarStyle` | Same styling across web and mobile | Same styling across web and mobile |

### Deep Link Example (Web + Mobile)

```dart
// 1. Define routes with parameters
SintMaterialApp(
  initialRoute: '/',
  translateEndpoints: true,
  translationsKeys: AppTranslations.keys,
  locale: Locale('es'),
  sintPages: [
    SintPage(name: '/', page: () => HomePage()),
    SintPage(name: '/book/:bookId', page: () => BookDetail()),
    SintPage(name: '/profile/:userId', page: () => ProfilePage()),
  ],
)

// 2. In your controller — same code works everywhere
class BookDetailController extends SintController {
  late final String bookId;

  @override
  void onInit() {
    super.onInit();
    // Works from: browser URL, deep link, or Sint.toNamed()
    bookId = Sint.routeParam ?? '';
    loadBook(bookId);
  }
}
```

**On web:** User visits `https://myapp.com/libro/abc123` →
SINT canonicalizes to `/book/abc123` → routes to `BookDetail` →
`Sint.routeParam` returns `'abc123'` → browser shows `/libro/abc123`.

**On mobile:** `Sint.toNamed('/book/abc123')` →
routes to `BookDetail` → `Sint.routeParam` returns `'abc123'`.

**Same controller. Same routes. Same parameters. Zero platform checks.**

---

## Counter App with SINT

```dart
void main() => runApp(SintMaterialApp(
  initialRoute: '/',
  sintPages: [
    SintPage(name: '/', page: () => Home()),
    SintPage(name: '/other', page: () => Other()),
  ],
));

class Controller extends SintController {
  var count = 0.obs;
  increment() => count++;
}

class Home extends StatelessWidget {
  @override
  Widget build(context) {
    final c = Sint.put(Controller());
    return Scaffold(
      appBar: AppBar(title: Obx(() => Text("Clicks: ${c.count}"))),
      body: Center(
        child: ElevatedButton(
          child: Text("Go to Other"),
          onPressed: () => Sint.toNamed('/other'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: c.increment,
      ),
    );
  }
}

class Other extends StatelessWidget {
  final Controller c = Sint.find();
  @override
  Widget build(context) {
    return Scaffold(body: Center(child: Text("${c.count}")));
  }
}
```

---

## Migration from GetX

1. Replace `get:` with `sint:` in `pubspec.yaml`
2. Replace `import 'package:get/get.dart'` with `import 'package:sint/sint.dart'`
3. Your existing `Get.` calls work — gradually replace with `Sint.` to remove deprecation warnings
4. `GetMaterialApp` → `SintMaterialApp`
5. `GetPage` → `SintPage`

---

## Origin & Philosophy

SINT is a hard fork of GetX v5.0.0-rc. After 8 years of accumulated code, GetX's repository became inactive and carried significant unused weight. SINT strips away everything that does not serve the four pillars, resulting in a clean, maintainable foundation built with Clean Architecture principles.

**GetX:** "Do everything."
**SINT:** "Do the right things."

**S + I + N + T** — State, Injection, Navigation, Translation. Nothing more, nothing less.

---

## License

SINT is released under the [MIT License](LICENSE).

Part of the [Open Neom](https://github.com/Open-Neom) ecosystem.
