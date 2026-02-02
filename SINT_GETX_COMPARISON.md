# SINT vs GetX — Comparison

## What is SINT?

SINT is a hard fork and Clean Architecture evolution of GetX (v5.0.0-rc). The name encodes its purpose:

    S — State Management
    I — Injection (Dependency Injection)
    N — Navigation
    T — Translation

After 8 years of accumulated code in GetX's repository — much of it unused, unmaintained, and outside the scope of state management — SINT was created to strip away everything that does not serve these four pillars. No HTTP client, no animations, no string validators, no generic widget extensions. The result is a focused, maintainable foundation built with Clean Architecture principles.

**Version 1.0.0** represents the first stable release: a clean, purpose-driven framework ready for production and pub.dev publication.

---

## By the Numbers

| Metric | GetX (original) | SINT 1.0.0 | Delta |
|---|---|---|---|
| Dart files in `lib/` | 134 | 128 | **-6 files** |
| Lines of code in `lib/` | 20,615 | 12,849 | **-7,766 LOC** |
| Top-level modules | 9+ | 5 | **-4+ modules** |
| Code reduction | — | — | **~37.7%** |
| Documentation languages | 16 (inconsistent) | 12 (complete) | Standardized |
| Docs per language | 3 (old structure) | 4 (1 per pillar) | Aligned to pillars |

Nearly 40% of GetX's codebase has been removed or restructured. What remains is exclusively dedicated to **S + I + N + T**.

---

## Clean Architecture Restructuring

SINT 1.0.0 reorganizes the entire codebase following Clean Architecture principles. Each module follows a consistent internal structure:

```
module/
  src/
    domain/
      enums/
      extensions/
      interfaces/
      mixins/
      models/
      typedefs/
    engine/        (business logic)
    ui/            (widgets, visual components)
    utils/         (module-specific utilities)
```

This contrasts with GetX's flat file organization where domain logic, UI, and utilities were mixed together.

### Architecture Comparison

| Aspect | GetX | SINT 1.0.0 |
|---|---|---|
| Entry point | `get.dart` exports 9 modules | `sint.dart` exports 5 modules |
| Module naming | `get_state_manager/`, `get_instance/`, `get_rx/` | `state_manager/`, `injection/`, `core/` |
| Internal structure | Flat file layout | Clean Architecture (domain/engine/ui) |
| Reactive types | Split across `get_rx/` and `get_state_manager/` | Consolidated in `core/` |
| Translations | Buried inside `get_utils/` | Dedicated `translation/` module |
| Platform detection | Inside `get_utils/` | Moved to `navigation/` where it is consumed |
| HTTP/WebSocket | Bundled in package | Removed — not a state management concern |
| Animations | Bundled in package | Removed — not a state management concern |
| Barrel exports | Scattered re-exports | 5 clean barrel files, one per module |

---

## Module Comparison

### GetX (9 modules + utility files)

| Module | Files | LOC | Purpose |
|---|---|---|---|
| `get_navigation/` | 36 | 8,323 | Routing, middleware, GetMaterialApp |
| `get_connect/` | 27 | 3,417 | HTTP client, WebSocket, GraphQL |
| `get_rx/` | 14 | 2,961 | Reactive types (Rx, RxList, RxMap...) |
| `get_state_manager/` | 13 | 2,455 | GetxController, GetBuilder, Obx |
| `get_utils/` | 21 | 1,870 | String validators, extensions, i18n, platform |
| `get_animations/` | 4 | 736 | Widget animations (.fadeIn, .bounce...) |
| `get_instance/` | 4 | 722 | Dependency injection (Get.put, Get.find) |
| `get_core/` | 7 | 72 | Core interfaces, logging |
| `get_common/` | 1 | 10 | Reset utilities |
| Other files | 7 | 49 | Barrel exports, convenience re-exports |
| **Total** | **134** | **20,615** | |

### SINT 1.0.0 (5 modules)

| Module | Pillar | Files | LOC | Purpose |
|---|---|---|---|---|
| `navigation/` | **N** | 77 | 8,108 | Routing, middleware, SintMaterialApp, platform detection |
| `core/` | Core | 19 | 2,531 | Core interfaces, reactive types (Rx), logging |
| `injection/` | **I** | 12 | 1,161 | Dependency injection (Sint.put, Sint.find, Sint.lazyPut) |
| `state_manager/` | **S** | 13 | 891 | SintController, SintBuilder, Obx, Workers |
| `translation/` | **T** | 6 | 148 | .tr extension, Translations class, i18n |
| `sint.dart` | Barrel | 1 | 10 | Single entry point |
| **Total** | | **128** | **12,849** | |

---

## What Was Removed (8 Years of Unused Code)

GetX accumulated features over 8 years that were never used by the majority of projects depending on it. SINT removes all of them:

| Removed module | Files | LOC | Reason |
|---|---|---|---|
| `get_connect/` | 27 | 3,417 | HTTP client/WebSocket/GraphQL — outside the four pillars. HTTP communication belongs in dedicated packages. |
| `get_animations/` | 4 | 736 | Widget animations — outside the four pillars. Animation belongs in dedicated packages (e.g., `neom_animation`). |
| `get_utils/` (partial) | ~15 | ~1,670 | String validators, context extensions, widget extensions, equality, queue, optimized_listview — generic utilities that overlap with other packages or are unused. |
| `get_common/` | 1 | 10 | Reset utilities — absorbed into `core/`. |
| Miscellaneous barrel files | 7 | 49 | `instance_manager.dart`, `route_manager.dart`, `state_manager.dart`, `utils.dart`, `src/`, `get_connect.dart` — consolidated into clean module structure. |

### What Was Kept from `get_utils/`

The `.tr` String extension and `Translations` class were moved into the new `translation/` module. Platform detection was moved into `navigation/`. Everything else was removed.

---

## Tests

| Test suite | GetX | SINT 1.0.0 |
|---|---|---|
| `animations/` | Present | Removed (module deleted) |
| `benchmarks/` | Present | Present |
| `injection/` | Present (as `instance/`) | Present |
| `navigation/` | Present | Present |
| `state_manager/` | Present | Present |
| `translation/` | Present (as `internationalization/`) | Present |
| `utils/` | Present | Removed (module pruned) |
| `rx/` | Present | Absorbed into other suites |
| **Total test files** | 30 | 19 |

Core test suites remain intact. Tests for removed modules were intentionally dropped.

### Test Roadmap per Pillar

Tests will be expanded in future versions, organized by pillar:

**State Management (S)**
- Reactive rebuild frequency profiling
- Scoped Rx container auto-disposal
- Workers lifecycle tests (ever, once, debounce, interval)
- StateMixin state transition tests

**Injection (I)**
- `put` → `find` → `delete` lifecycle tests
- `fenix` recreation tests
- Tag-based instance isolation
- Bindings auto-disposal on route change

**Navigation (N)**
- Middleware chain priority ordering
- Named route parameter parsing
- Transition animation verification
- SnackBar/Dialog/BottomSheet lifecycle

**Translation (T)**
- Missing key fallback behavior
- Parameter substitution accuracy
- Locale change reactivity
- Plural form handling across languages

---

## Documentation

SINT 1.0.0 ships with complete documentation in 12 languages, organized by pillar:

| Language | Folder | Files |
|---|---|---|
| English | `documentation/en_US/` | 4 + README |
| Spanish | `documentation/es_ES/` | 4 + README |
| Arabic | `documentation/ar_EG/` | 4 + README |
| French | `documentation/fr_FR/` | 4 + README |
| Portuguese (BR) | `documentation/pt_BR/` | 4 + README |
| Russian | `documentation/ru_RU/` | 4 + README |
| Japanese | `documentation/ja_JP/` | 4 + README |
| Chinese (Simplified) | `documentation/zh_CN/` | 4 + README |
| Korean | `documentation/kr_KO/` | 4 + README |
| Indonesian | `documentation/id_ID/` | 4 + README |
| Turkish | `documentation/tr_TR/` | 4 + README |
| Vietnamese | `documentation/vi_VI/` | 4 + README |

Each language folder contains:
- `state_management.md` — State Management pillar documentation
- `injection_management.md` — Injection pillar documentation
- `navigation_management.md` — Navigation pillar documentation
- `translation_management.md` — Translation pillar documentation
- `README.md` — Full framework overview in that language

---

## Roadmap

### Phase 1 — Ecosystem Migration (Completed)

- ~~Migrate all `.dart` imports from `package:get/get.dart` to `package:sint/sint.dart`~~
- ~~Update all `pubspec_overrides.yaml` across 21+ modules~~
- ~~Validate `flutter pub get` passes on all modules~~
- ~~Restructure all barrel exports~~
- ~~Generate documentation in 12 languages~~

### Phase 2 — pub.dev Publication (Current)

- Publish `sint: 1.0.0` to pub.dev
- Remove `dependency_overrides` hack — apps depend on published sint
- Evaluate and adapt commented-out tests

### Phase 3 — Pillar-Specific Evolution

#### State Management (S)
- Reactive performance profiling for `.obs` rebuild frequency
- Scoped `Rx` containers that auto-dispose with navigation scopes
- Stream interop with Dart `Stream`/`StreamController` and platform channels

#### Injection (I)
- Module-aware DI scopes aligned with `neom_modules/` boundaries
- Lazy module loading with Flutter deferred imports
- Simplified mock injection for unit testing across 21+ modules

#### Navigation (N)
- VR/XR/AR spatial routing via SintPage and middleware extensions
- Deep link standardization across Cyberneom, EMXI, and Gigmeout
- Route analytics feeding into `neom_analytics`
- Nested navigation improvements for tab-based flows

#### Translation (T)
- Dynamic per-module translation loading on demand
- Build-time validation of `.tr` keys across all locales
- RTL/LTR layout integration tied to locale changes

#### Cross-Pillar
- SINT DevTools extension: real-time state tree, DI registry, active routes, current locale
- Optional `build_runner` code generation for type-safe routes and DI registrations
- Flutter Web performance optimization for Open Neom's browser-based platform

---

## Benefits Summary

| Benefit | Impact |
|---|---|
| **37.7% less code** | 7,766 fewer lines to compile, ship, maintain, and debug |
| **8 years of cleanup** | Removed all accumulated unused code from GetX's history |
| **Clean Architecture** | Every module follows domain/engine/ui structure |
| **5 modules instead of 9+** | Clear mental model — every module maps to a pillar |
| **Purpose-driven naming** | `state_manager/`, `injection/`, `navigation/`, `translation/` — self-documenting |
| **No dead weight** | No HTTP client, no animations, no string validators cluttering the package |
| **Easier onboarding** | New developers understand the scope immediately: S + I + N + T |
| **Faster builds** | Less code compiled into final apps, especially relevant for Flutter Web |
| **Sovereign control** | No dependency on inactive GetX repository — full control over patches and evolution |
| **Clean test suites** | Tests match the actual package scope — no orphaned test files |
| **12-language documentation** | Complete docs aligned to the four pillars, ready for global adoption |
| **Foundation for specialization** | Lean core enables VR/XR routing, module-aware DI, and reactive profiling |

---

## Philosophy

GetX was built as a "do everything" framework. After 8 years, that philosophy resulted in 20,615 lines of code where much of it served no one.

SINT 1.0.0 is built as a "do the right things" framework. Every file, every export, every line of code serves one of four pillars.

**S + I + N + T** — State, Injection, Navigation, Translation. The four pillars. Nothing more, nothing less.
