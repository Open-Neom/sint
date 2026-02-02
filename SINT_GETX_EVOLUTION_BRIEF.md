# Technical Brief: Evolution from GetX to SINT

## 1. Context & Vision

- **Stakeholder:** Serzen (Founder & Architect of SRZNVERSO)
- **Origin:** GetX v5.0.0-rc — an open-source Flutter framework with state management, dependency injection, routing, HTTP, animations, and utilities
- **Problem:** GetX's original repository became inactive. Over 8 years, the "do everything" approach accumulated unused code, introduced maintenance overhead, and made the package harder to understand, extend, and keep aligned with Flutter SDK updates.
- **Solution:** Fork GetX and evolve it into SINT — a focused framework built around four pillars only, restructured with Clean Architecture principles.

## 2. What SINT Stands For

| Letter | Pillar | Responsibility |
|---|---|---|
| **S** | State Management | `SintController`, `SintBuilder`, `Obx`, `.obs`, `Rx` types, Workers |
| **I** | Injection | `Sint.put`, `Sint.find`, `Sint.lazyPut`, Bindings |
| **N** | Navigation | `SintPage`, `Sint.toNamed`, middleware, `SintMaterialApp`, platform detection |
| **T** | Translation | `.tr` extension, `Translations` class, locale management |

Everything outside these four pillars has been removed.

## 3. Scale of the Evolution

| Metric | GetX | SINT 1.0.0 | Change |
|---|---|---|---|
| Files | 134 | 128 | -6 |
| Lines of code | 20,615 | 12,849 | **-7,766 (-37.7%)** |
| Modules | 9+ | 5 | -4+ |
| Test files | 30 | 19 | -11 |
| Documentation languages | 16 (inconsistent) | 12 (complete, pillar-aligned) | Standardized |

## 4. What Was Removed and Why

### `get_connect/` (27 files, 3,417 LOC)
HTTP client, WebSocket, and GraphQL support. Not used in any of the 21+ neom_modules or the apps (Cyberneom, EMXI, Gigmeout). HTTP communication is handled by dedicated packages elsewhere in the ecosystem. An HTTP client is not a state management concern.

### `get_animations/` (4 files, 736 LOC)
Widget animation extensions (`.fadeIn()`, `.bounce()`, `.spin()`). Not used across the ecosystem. Animation belongs in a dedicated package (e.g., `neom_animation`), not inside a state management library.

### `get_utils/` (majority removed, ~1,670 LOC)
String validators, context extensions, widget extensions, equality utilities, queue utilities, optimized ListView. These overlap with `neom_commons` or are unused. The `.tr` extension and `Translations` class were preserved and moved to the new `translation/` module. Platform detection was moved to `navigation/`.

### Miscellaneous files (~59 LOC)
`get_common/`, barrel re-exports (`instance_manager.dart`, `route_manager.dart`, `state_manager.dart`, `utils.dart`, `src/`). Absorbed into the clean five-module structure.

## 5. Clean Architecture Restructuring

GetX organized code by internal technical concern (`get_rx/`, `get_instance/`, `get_core/`). SINT reorganizes code by developer-facing pillar, with each module following Clean Architecture internally:

```
getx/lib/                          sint/lib/
  get.dart                           sint.dart
  get_animations/    [REMOVED]
  get_common/        [ABSORBED]      core/
  get_connect/       [REMOVED]         src/domain/ (interfaces, enums, models, extensions)
  get_core/          ──────────>       src/ (sint_main, sint_engine, sint_queue)
  get_instance/      ──────────>     injection/
  get_navigation/    ──────────>       src/domain/ (interfaces, models, typedefs)
  get_rx/            ──────────>       src/ui/ (bind_element, binder)
  get_state_manager/ ──────────>     navigation/
  get_utils/         [SPLIT]           src/domain/ (enums, extensions, interfaces, mixins, models)
                                       src/router/ (page, delegate, matcher, parser)
                                       src/ui/ (bottomsheet, dialog, snackbar, transitions)
                                     state_manager/
                                       src/domain/ (mixins, typedefs)
                                       src/engine/ (controller, builder, notifier)
                                       src/ui/ (obx_widget)
                                     translation/
                                       src/domain/ (extensions, interfaces, models)
                                       src/utils/
```

Key structural changes:
- **Clean Architecture per module**: domain/engine/ui separation in every module
- **Reactive types** (`Rx`, `RxList`, `RxMap`, `RxBool`) consolidated into `core/` instead of being split across `get_rx/` and `get_state_manager/`
- **Translations** elevated from being buried in `get_utils/` to a first-class `translation/` module
- **Platform detection** moved from `get_utils/` to `navigation/` where it is actually consumed
- **Single entry point**: `import 'package:sint/sint.dart'` gives you everything
- **5 clean barrel files**: one per module, with organized export sections

## 6. Ecosystem Impact

SINT serves as the base infrastructure for the Open Neom ecosystem:

- **21+ neom_modules** share SINT as their common state management, DI, navigation, and translation layer
- **3 apps** (Cyberneom, EMXI, Gigmeout) use SINT through their modules
- **Multirepo architecture** with `neom_modules/` — each module can be cloned and developed independently, but all share the same SINT foundation
- **`pubspec_overrides.yaml`** in each module points `sint:` to `../sint` during development
- **458+ dart files** migrated from `package:get/get.dart` to `package:sint/sint.dart`
- **48/49 modules** pass `flutter pub get` successfully (1 disk space issue, not code related)

## 7. Tests

Core test suites remain intact:

| Suite | Status |
|---|---|
| `benchmarks/` | Retained |
| `injection/` | Retained |
| `navigation/` | Retained |
| `state_manager/` | Retained |
| `translation/` | Retained |

Tests for removed modules (`animations/`, `utils/`, `rx/`) were either dropped or have been commented out for evaluation.

### Test Roadmap per Pillar

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

## 8. Documentation

SINT 1.0.0 ships with complete documentation in 12 languages, each containing 4 pillar-aligned docs plus a README:

| File | Content |
|---|---|
| `state_management.md` | Reactive (.obs, Obx), Simple (SintBuilder), StateMixin, Workers |
| `injection_management.md` | Sint.put, Sint.lazyPut, Sint.find, Bindings, SmartManagement |
| `navigation_management.md` | Routes, middleware, SnackBars, Dialogs, transitions |
| `translation_management.md` | .tr extension, Translations class, locale management |
| `README.md` | Full framework overview |

Languages: en_US, es_ES, ar_EG, fr_FR, pt_BR, ru_RU, ja_JP, zh_CN, kr_KO, id_ID, tr_TR, vi_VI

## 9. Roadmap

### Completed: Ecosystem Migration
- All imports migrated from `package:get/get.dart` to `package:sint/sint.dart`
- All `pubspec_overrides.yaml` updated across 21+ modules
- All barrel exports restructured
- Documentation generated in 12 languages

### Current: pub.dev Publication
- Publish `sint: 1.0.0` to pub.dev
- Remove `dependency_overrides` hack
- Evaluate and adapt commented-out tests

### Next: Pillar-Specific Evolution

**State Management (S)**
- Reactive performance profiling for `.obs` rebuild frequency
- Scoped `Rx` containers with auto-disposal tied to navigation scopes
- First-class Stream interop with Dart platform channels

**Injection (I)**
- Module-aware DI scopes aligned with `neom_modules/` boundaries
- Lazy module loading with Flutter deferred imports
- Simplified mock injection for testing across 21+ modules

**Navigation (N)**
- VR/XR/AR spatial routing via `SintPage` and middleware extensions for `neom_vr`
- Deep link standardization across all Open Neom apps
- Route analytics integration with `neom_analytics`
- Nested navigation improvements for tab-based flows

**Translation (T)**
- Dynamic per-module translation loading on demand
- Build-time `.tr` key validation across all locales
- RTL/LTR layout integration tied to locale changes

**Cross-Pillar**
- SINT DevTools extension: real-time state tree, DI registry, active routes, locale
- Optional `build_runner` code generation for type-safe routes and DI
- Flutter Web performance optimization for Open Neom's browser-based platform

## 10. Benefits

| Benefit | Detail |
|---|---|
| **37.7% less code** | 7,766 fewer lines — faster compilation, smaller binaries, less surface for bugs |
| **8 years of cleanup** | Removed all accumulated unused code from GetX's history |
| **Clean Architecture** | Every module follows domain/engine/ui structure |
| **Clear mental model** | 5 modules, each mapping to a pillar — self-documenting architecture |
| **Easier onboarding** | New developers and AI tools understand the scope immediately |
| **No dead weight** | Every file serves S, I, N, or T — nothing else |
| **Sovereign control** | No dependency on inactive third-party repository |
| **12-language documentation** | Complete docs aligned to the four pillars |
| **AI-friendly** | Predictable structure enables tools like Claude Code to navigate and contribute effectively |
| **Foundation for XR** | Lean routing core ready for VR/XR/AR spatial navigation patterns |

## 11. Philosophy

GetX: "Do everything."
SINT: "Do the right things."

**S + I + N + T** — State, Injection, Navigation, Translation. The four pillars of high-fidelity Flutter infrastructure. Nothing more, nothing less.
