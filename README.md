# SINT

<p align="center">
  <img src="https://raw.githubusercontent.com/Open-Neom/sint/main/assets/SINT%20-%20Logo%20-%202026.png" alt="SINT Framework" width="240"/>
</p>

<p align="center">
  <strong>State · Injection · Navigation · Translation</strong><br/>
  High-performance, Clean Architecture micro-framework for Flutter.
</p>

<p align="center">
  <a href="https://pub.dev/packages/sint"><img src="https://img.shields.io/pub/v/sint.svg?label=sint&color=blue" alt="pub package"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License: MIT"/></a>
</p>

<div align="center">

[![English](https://img.shields.io/badge/English-blueviolet?style=flat-square)](#)
[![Spanish](https://img.shields.io/badge/Español-blueviolet?style=flat-square)](documentation/es_ES/README.md)
[![Arabic](https://img.shields.io/badge/العربية-blueviolet?style=flat-square)](documentation/ar_EG/README.md)
[![French](https://img.shields.io/badge/Français-blueviolet?style=flat-square)](documentation/fr_FR/README.md)
[![Portuguese](https://img.shields.io/badge/Português-blueviolet?style=flat-square)](documentation/pt_BR/README.md)
[![Russian](https://img.shields.io/badge/Русский-blueviolet?style=flat-square)](documentation/ru_RU/README.md)
[![Japanese](https://img.shields.io/badge/日本語-blueviolet?style=flat-square)](documentation/ja_JP/README.md)
[![Chinese](https://img.shields.io/badge/中文-blueviolet?style=flat-square)](documentation/zh_CN/README.md)
[![Korean](https://img.shields.io/badge/한국어-blueviolet?style=flat-square)](documentation/kr_KO/README.md)
[![Indonesian](https://img.shields.io/badge/Indonesia-blueviolet?style=flat-square)](documentation/id_ID/README.md)
[![Turkish](https://img.shields.io/badge/Türkçe-blueviolet?style=flat-square)](documentation/tr_TR/README.md)
[![Vietnamese](https://img.shields.io/badge/Tiếng_Việt-blueviolet?style=flat-square)](documentation/vi_VI/README.md)

</div>

---

## The Four Pillars

SINT focuses strictly on four foundational pillars—no HTTP client, validators, or unrelated bloat:

| Pillar | Core APIs | Guide |
| --- | --- | --- |
| **S — State** | `SintController`, `Obx`, `.obs`, `Sint.computed`, `Sint.batch`, `Sint.untrack`, `everSync` | [State Docs](documentation/en_US/state_management.md) |
| **I — Injection** | `Sint.put`, `Sint.lazyPut`, `Sint.putAsync`, `Sint.find`, `Bind`, `SmartManagement` | [Injection Docs](documentation/en_US/injection_management.md) |
| **N — Navigation** | `SintApp`, `SintPage`, `SintRouterOutlet`, `Sint.toNamed`, `Sint.back`, `pathParams`, `queryParams` | [Navigation Docs](documentation/en_US/navigation_management.md) |
| **T — Translation** | `.tr`, `.trParams`, `Translations`, `Sint.updateLocale`, `Sint.loadTranslations`, `translateEndpoints` | [Translation Docs](documentation/en_US/translation_management.md) |

---

## What's New in 2.0.0

- **Standalone Design Systems (`SintApp`)**: First-class host for Flutter 3.47+ standalone `material_ui` and `cupertino_ui` packages (`Flutter >=3.44.0 / Dart >=3.12.0`), while preserving `SintMaterialApp` and `SintCupertinoApp` for SDK Material/Cupertino apps. See [MIGRATION_DESIGN_SYSTEMS.md](MIGRATION_DESIGN_SYSTEMS.md).
- **State-of-the-Art Signals Engine (`Obx` $O(1)$ + `batch` + `computed` + `untrack`)**: Brings the modern fine-grained Signals triad (inspired by **SolidJS**, **Preact Signals**, and **Angular Signals**) to Flutter—persistent $O(1)$ `Obx` listener diffing with automatic conditional-branch pruning, zero-allocation `Sint.batch`, memoized `Sint.computed`, `Sint.untrack` / `rx.peek`, and controller-scoped `everSync` / `autoDispose`.
- **Multi-Level Prefix Trie Router**: Indexes all leading literal route segments and reuses compiled `PathDecoded` templates (**97.8× faster** on 1,000 shared-prefix routes: `250.48 µs → 2.56 µs/op`).
- **Nested Routing (`SintRouterOutlet`)**: Declarative nested outlets and `IndexedRouteBuilder` synchronized with imperative `Navigator` calls.

---

## Quick Start

```yaml
dependencies:
  sint: ^2.0.0
```

```dart
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sint/sint.dart';

class CartController extends SintController {
  final items = 1.obs;
  final price = 25.obs;
  late final total = computed(() => items.value * price.value); // Auto-disposed on route close

  void addBundle() => Sint.batch(() {
    items.value += 2;
    price.value = 20;
  });
}

void main() => runApp(
  SintApp(
    materialTheme: ThemeData(),
    initialRoute: '/',
    sintPages: [
      SintPage(
        name: '/',
        binds: [Bind.put(CartController())],
        page: () {
          final c = Sint.find<CartController>();
          return Scaffold(
            body: Center(child: Obx(() => Text('Total: \$${c.total.value}'))),
            floatingActionButton: FloatingActionButton(
              onPressed: c.addBundle,
              child: const Text('+'),
            ),
          );
        },
      ),
    ],
  ),
);
```

---

## Architectural Positioning & 4-Pillar Benchmark

### Why SINT 2.0 is Not GetX (And Why Context-Free is Clean Architecture)
GetX was criticized for bundling unrelated utilities (`GetConnect` HTTP/sockets, string validators), using `Type.toString()` keys that broke under Web/Wasm minification, leaking conditional `Obx` listeners, and lacking batching or computed signals. **SINT 2.0 replaces those internals** with:
1. **Strict 4-Pillar Scope (`S · I · N · T`)**: Clean Architecture boundaries (`domain`, `engine`, `router`, `ui`) with zero unrelated utilities.
2. **Reified `Type`-Keyed DI & $O(M)$ Route Teardown**: Safe under Web/Wasm minification; route-owned controllers and `computed` signals auto-dispose deterministically when their route exits.
3. **Zero-Stream Synchronous Signals**: `StreamController` is allocated lazily only if `.stream`/`.listen` is called; `Obx`, `Computed`, `Sint.batch`, and `everSync` run on synchronous pointer lists.
4. **Why Context-Free APIs (`Sint.toNamed`, `Sint.find`, `.tr`) Are Safe by Design**: In Flutter, navigation, snackbars, and localization belong to the root application host (`NavigatorState` / `ScaffoldMessengerState`), not to leaf widgets. Threading `BuildContext` into controllers or async callbacks couples domain logic to the UI tree and triggers `use_build_context_synchronously` bugs after `await` gaps. SINT binds lifecycle ownership directly to route entries in `SintRoot`, eliminating `BuildContext` plumbing without leaking state.

### Solving the 4 Pillars: Development Velocity, Maintenance & Audit Savings

Building an equivalent 4-pillar feature (Reactive State + Derived Value + Scoped DI + Parameterized Route + i18n + Snackbar):

| Dimension | **SINT 2.0** | **BLoC Stack** (`bloc` + `get_it` + `go_router` + `intl`) | **Riverpod Stack** (`riverpod` + `go_router` + `intl`) | **Provider Stack** (`provider` + `go_router` + `intl`) | **Legacy GetX** |
| --- | --- | --- | --- | --- | --- |
| **Packages to Maintain & Audit** | **1 (`sint`)** | 5+ external packages | 4+ packages + `build_runner` | 4+ external packages | 1 (bloated with HTTP/utils) |
| **Files Touched per Feature** | **1–2 files** | 5–6 files (`event`, `state`, `bloc`, `locator`, `router`, `.arb`) | 4–5 files (`provider`, `.g.dart`, `router`, `.arb`) | 4 files (`notifier`, `MultiProvider`, `router`, `.arb`) | 1–2 files |
| **Codegen (`build_runner`)** | **0 generated files** | Optional (`freezed`/`injectable`) + ARB | Required (`.g.dart` + ARB) | ARB codegen | 0 generated files |
| **Feature Boilerplate (LoC)** | **~35 LoC** | **~165 LoC** *(4.7× more code)* | **~115 LoC** *(3.3× more code + `.g.dart`)* | **~105 LoC** *(3.0× more code)* | ~40 LoC (no `batch`/`computed`) |
| **Code Audit & PR Review Surface** | **Minimal (~70–80% less code to audit)** | High (events, `copyWith`, manual DI teardown, 5 dep trees) | Medium–High (generated `.g.dart` + `WidgetRef` plumbing) | Medium (manual `notifyListeners` + context wiring) | High (global leaks, string keys) |
| **State Granularity (S)** | **Fine-grained Signals (`Obx` $O(1)$, `batch`, `computed`, `untrack`)** | Async Stream + immutable `copyWith` | Provider graph (`ConsumerWidget`) | Coarse object (`ChangeNotifier`) | Unbatched `.obs` (stale branch leaks) |
| **DI ↔ Router Lifecycle (I ↔ N)** | **Native ($O(M)$ auto-dispose on route pop)** | Manual `BlocProvider` / `GetIt` scopes | Coupled to widget unmount (`autoDispose`) | Coupled to `BuildContext` subtree | $O(N \times M)$ scan / string-key collisions |
| **Route Matching (N)** | **Multi-Level Prefix Trie ($O(\text{depth})$)** | External (`go_router`) | External (`go_router`) | External (`go_router`) | Linear / 1st-segment regex scan |
| **Flutter 3.47+ Standalone UI** | **Native (`SintApp`)** | Manual host setup | Manual host setup | Manual host setup | Unsupported (#3469) |

> **Engineering & Audit Time Impact:** Consolidating `S · I · N · T` into a single deterministic contract reduces per-feature code volume by **70%–78%**, eliminates `build_runner` wait times, and cuts **PR review & security audit time by ~3×–4×**—auditors verify **1 cohesive ~35 LoC file** with automatic route-bound teardown (`onClose`) and **1 dependency tree**, instead of tracing state mutations, manual disposal, and version compatibility across 5–6 files and 5 third-party packages.

### Verified 4-Pillar Benchmarks ([`four_pillars_benchmark_test.dart`](test/benchmarks/four_pillars_benchmark_test.dart))

> **How is `Sint.batch` faster than both unbatched `Rx` and `ChangeNotifier` / `BLoC`?**
> 1. **Inside SINT (`0.23 µs` batched vs `0.37 µs` unbatched — 1.6× faster):** Mutating 4 fields (`items`, `price`, `tax`, `discount`) without `Sint.batch` immediately recomputes derived state (`total`) and invokes downstream `Obx` listeners **4 separate times**. Inside `Sint.batch`, each mutation sets a zero-allocation boolean flag (`_queuedInBatch = true`, ~1ns) and defers evaluation until the block exits—recomputing `total` **1 single time** and notifying `Obx` **1 single time** (**75% less work**).
> 2. **Against `ChangeNotifier` (`0.90 µs`) & `BLoC` (`1.02 µs`) — 4.0× to 4.5× faster:** On a 20-widget screen where only 1 widget reads `total`, coarse model/stream patterns notify all 20 widgets on every mutation ($4 \times 20 = \mathbf{80\text{ widget callbacks}}$). SINT's fine-grained per-signal `Obx` graph notifies the 19 unrelated widgets **0 times** and the 1 target widget **1 time** ($\mathbf{1\text{ callback vs }80}$).

| Workload | SINT 2.0 Median | Baseline / Alternative Median | Result |
| --- | ---: | ---: | --- |
| **Pillar S** — 20-Widget Screen, 4-Field Transaction + Derived Total | **`0.23 µs/op`** (`Sint.batch` + `Computed`) | `0.37 µs/op` (Unbatched `Rx`)<br/>`0.90 µs/op` (`ChangeNotifier`)<br/>`1.02 µs/op` (Immutable State Copy) | **1.6× faster** than unbatched `Rx`<br/>**4.0× – 4.5× faster** than `ChangeNotifier` / `BLoC` |
| **Pillar N** — 1,000 Shared-Prefix Routes (`/api/item999/:id`) | **`2.56 µs/op`** (Multi-Level Trie) | `250.48 µs/op` (1st-segment / linear regex scan) | **97.8× faster** ($O(\text{depth})$ constant scaling) |
| **Pillar I** — Hot Typed/Tagged Dependency Lookup (`Sint.find<T>`) | **`0.021 µs/op`** (Reified `Type` registry) | — | **~47M lookups/sec** (Web/Wasm minification-safe) |
| **Full S·I·N·T Cycle** (Route Match + `Sint.find` + `batch`/`computed` + `.trParams`) | **`3.57 µs/op`** | — | **~280,000 complete 4-pillar cycles/sec** |

---

## Migrating from GetX

1. Replace `get:` with `sint: ^2.0.0` in `pubspec.yaml`.
2. Replace `import 'package:get/get.dart';` with `import 'package:sint/sint.dart';`.
3. **Zero-friction compatibility in `2.x`**: Existing `Get.`, `GetxController`, `GetMaterialApp`, `GetPage`, `GetBuilder`, and `GetRouterOutlet` calls continue to compile with `@Deprecated` notices so you can migrate to `Sint*` symbols incrementally before `3.0.0`.

---

## Documentation & Resources

- **Pillar Guides**: [State](documentation/en_US/state_management.md) · [Injection](documentation/en_US/injection_management.md) · [Navigation](documentation/en_US/navigation_management.md) · [Translation](documentation/en_US/translation_management.md)
- **Standalone Material / Cupertino Migration**: [MIGRATION_DESIGN_SYSTEMS.md](MIGRATION_DESIGN_SYSTEMS.md)
- **Benchmarks & Methodology**: [test/benchmarks/README.md](test/benchmarks/README.md) · [performance/README.md](performance/README.md)
- **Release History & Roadmap**: [CHANGELOG.md](CHANGELOG.md) · [ROADMAP.md](ROADMAP.md)

---

## License

Released under the [MIT License](LICENSE). Part of the [Open Neom](https://github.com/Open-Neom) ecosystem.
