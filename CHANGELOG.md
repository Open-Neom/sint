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
