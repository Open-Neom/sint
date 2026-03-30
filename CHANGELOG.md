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
