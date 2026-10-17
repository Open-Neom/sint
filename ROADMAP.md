# SINT Roadmap

> **Current Release (`2.0.0` — 2026-10-17):** Ships the Next-Gen Reactive & Routing Engine (`O(1)` incremental `Obx` subscription reconciliation, synchronous `Sint.batch`, memoized `Sint.computed`, unified `RxMap`/`RxSet` semantics, and the Multi-Level Literal Prefix Trie router with **98× faster** shared-prefix matching) alongside adaptive `SintApp` for Flutter 3.47+ standalone `material_ui` and `cupertino_ui` packages (`Flutter >=3.44.0 / Dart >=3.12.0`).

---

## Shipped in `2.0.0`

- **Pillar S — Next-Gen Reactive Engine**:
  - Incremental `Obx` subscription diffing (`ObxReactiveElement` + `Notifier`): $O(1)$ steady-state widget rebuilds and automatic pruning of inactive conditional branches.
  - Synchronous mutation batching via `Sint.batch(() { ... })` (`ListNotifier.batch`).
  - Memoized derived reactive signals via `Sint.computed(() => ...)` (`Computed<T>`).
  - Unified collection reference & single-notification semantics for `RxMap.addAll` and `RxSet`.
- **Pillar N — Multi-Level Prefix Trie & Standalone Design Systems**:
  - Multi-level literal prefix trie (`_LiteralTrieNode`) in `RouteParser` (**97.8× speedup** on 1,000 shared-prefix routes, **128.7× speedup** on misses).
  - Zero-recompile `SintPage.copyWith` reusing compiled `PathDecoded` instances.
  - Adaptive `SintApp` / `SintApp.router` supporting standalone `material_ui` and `cupertino_ui` packages (Issue #12).
  - Restored and modernized `SintRouterOutlet`, `IndexedRouteBuilder`, and synchronized mixed imperative/declarative route stacks (Issue #10).
- **Community Migration Support**:
  - All `@Deprecated` `Get` aliases (`final Get = Sint`, `GetxController`, `GetxService`, `GetMaterialApp`, `GetCupertinoApp`, `GetPage`, `GetBuilder`, `GetRouterOutlet`, etc.) are preserved throughout `2.x` to provide a frictionless migration path for Flutter developers coming from GetX.

---

## Horizon 1 — Ecosystem & Developer Tooling (`2.1.0` – `2.2.0`)

- **Lightweight Synchronous Workers (`2.1.0`)**:
  - Migrate `ever`, `once`, `debounce`, and `interval` from `StreamController.broadcast` wrappers to direct `ListNotifier` callbacks (~10× lower memory and allocation overhead per worker).
- **Navigation-Scoped Reactive Containers (`2.1.0`)**:
  - Reactive state containers that automatically bind to the active route's lifecycle without requiring manual controller boilerplate.
- **Optional `build_runner` Codegen & Compile-Time `.tr` Validation (`2.2.0`)**:
  - Opt-in type-safe route builders, generated DI bindings, and build-time translation key verification.
- **SINT DevTools Extension (`2.2.0`)**:
  - Live inspection of the reactive `Obx`/`Computed` dependency graph, active `Sint` DI registry, route stack, and current locale.
- **AOT & Competitor Benchmark Suite (`2.2.0`)**:
  - Extend `tool/benchmark_runner.dart` with `dart compile exe` AOT measurements and reproducible comparisons against `ValueNotifier`, Riverpod, and BLoC.

---

## Horizon 2 — `SINT 3.0.0`: The Legacy `Get` Purge & Pure Standalone Architecture

Because many Flutter developers are still discovering SINT and migrating existing GetX codebases, **SINT `2.x` intentionally preserves all `@Deprecated` `Get*` symbols** (`Get`, `GetxController`, `GetxService`, `GetMaterialApp`, `GetCupertinoApp`, `GetPage`, `GetBuilder`, `GetRouterOutlet`, etc.) and `home:` with clear compiler deprecation warnings.

In **SINT `3.0.0`**, once the broader community migration window has completed:

1. **Complete Removal of `@Deprecated` `Get*` Compatibility Layer**:
   - Remove `final Get = Sint` from `sint_main.dart`.
   - Remove `legacy_typedefs.dart` (`GetxController`, `GetxService`, `GetMaterialApp`, `GetCupertinoApp`, `GetPage`, `GetPageRoute`, `GetBuilder`, `GetSnackBar`, `GetDialogRoute`, `GetModalBottomSheetRoute`, etc.) and `get_builder.dart`.
   - Remove `GetRouterOutlet`, `GetPageBuilder`, `GetRouteAwarePageBuilder`, and `RouteData.isGetPageRoute`.
2. **Declarative-Only Routing Contract**:
   - Remove the `@Deprecated` `home:` parameter from `SintMaterialApp`, `SintCupertinoApp`, `ConfigData`, and `SintRoot` in favor of `initialRoute` + `sintPages`.
3. **Standalone Design System Default**:
   - Complete the transition to Flutter's standalone `material_ui` and `cupertino_ui` packages as the primary host architecture once Flutter retires legacy SDK `flutter/material.dart` and `flutter/cupertino.dart` exports.

---

## Release Summary

| Version | Milestone |
| --- | --- |
| **1.6.x** | Type-keyed DI registry, $O(1)$ route disposal, statistical benchmark harness |
| **1.7.0** | Standalone `material_ui` / `cupertino_ui` (`SintApp`) & `SintRouterOutlet` |
| **2.0.0** | **Incremental $O(1)$ `Obx` engine, `Sint.batch`, `Sint.computed`, Multi-Level Trie Router** |
| **2.1.0 – 2.2.0** | Synchronous workers, scoped Rx containers, DevTools extension, opt-in codegen |
| **3.0.0** | **Removal of `@Deprecated` `Get*` migration aliases & legacy `home:` parameter** |
