# SINT Roadmap

> **Current Release (`2.3.0` — 2026-11-22):** Ships extreme-performance VSync UI primitives (`Sint.frameBatch`, `FrameThrottledRx`, `ObxSelect`), the automated GetX → SINT migration & audit CLI (`dart run sint:migrate`), and built-in 4-pillar runtime diagnostics + Dart VM Service Extensions (`Sint.diagnostics` / `ext.sint.*`) — engineered and proven across Open Neom's real-time audio DAW, 3D/VR, 256 Hz EEG, and on-device LLM platforms. Zero breaking changes (`2.x` backwards-compatible).

---

## Shipped Across `2.0.0` – `2.3.0`

### `2.3.0` — Real-Time High-Frequency Primitives, Migration CLI & Runtime Diagnostics
- **Pillar S — Extreme-Performance Primitives**:
  - `Sint.frameBatch` & `Sint.flushFrameBatch()` for zero-allocation VSync coalescing of 60–1000 Hz streams (**8× fewer UI dispatches**, **3.56× faster** than unbatched `ValueNotifier`).
  - `FrameThrottledRx<T>` (`rx.throttledToFrame()` / `controller.frameThrottled(rx)`) with zero Streams/Timers, sub-frame jitter suppression, and automatic `onClose()` disposal.
  - `ObxSelect<T>` fine-grained inline selector widget with custom `equals:` comparator and `SintScope` isolation.
- **Developer Experience & Automated Migration**:
  - `dart run sint:migrate` pure-Dart CLI (`--dry-run`, `--apply`, `--json`) migrating `pubspec.yaml` + GetX symbols while running 4 architectural audit rules.
- **Observability & DevTools Foundation**:
  - `Sint.diagnostics` (`snapshot()`, `rebuildStats()`, `enableRebuildTracking`, `debugLabel:` on `Obx`/`ObxSelect`) + automatic debug/profile Dart VM Service Extensions (`ext.sint.*`).

### `2.2.x` — `MultiBinder` $O(1)$ Depth, Glitch-Free Signals, `Navigator`-Free Parity & Flutter 3.50 Clean Analysis
- **`2.2.2`**: Decoupled 49 legacy `flutter/material.dart` / `flutter/cupertino.dart` imports (`160/160` pub points readiness on Flutter 3.50 / Dart 3.14), leak-free `Sint.snackbar()`, `const` transitions, standalone `SintAppBar` parity, and `Bind.put` dynamic-type guard.
- **`2.2.1`**: Full `Navigator`-free APIs (`Sint.maybePop`, `Sint.canPop`, safe `Sint.pop`) and automatic `MaterialApp`/`CupertinoApp` widget-test fallback via `Sint.resolveNavigator`.
- **`2.2.0`**: Single-element `MultiBinder` ($O(1)$ widget depth), tri-color glitch-free & lazy `Computed`, single-slot zero-allocation `Obx`, reactive `.tr` with zero-reassemble `Sint.updateLocale`, unified Navigator 2.0 `SintMiddleware` guards, `Sint.putContractAsync`, `package:sint/rx.dart`, and [`llms.txt`](llms.txt).

### `2.1.0` — Contract-First DI, Synchronous Workers & Typed Routing
- `Bind.contract`, `Bind.putContract`, `aliases:`, `Sint.findAll<S>()`, `SintScope`, and `SintService`.
- Zero-Stream synchronous `ever`/`once`/`debounce`/`interval`, `ValueListenable` interop (`.rxValue`), sealed `SintStatus<T>` + `RxFuture<T>`.
- `globalMiddlewares`, typed `SintRoute<TArgs, TResult>`, $O(1)$ pre-resolved locale cache, and `Sint.registerLazyTranslations`.

### `2.0.0` — Next-Gen Signals Engine, Trie Router & Standalone Design Systems
- Incremental $O(1)$ `Obx` diffing, `Sint.batch`, `Sint.computed`, and `Sint.untrack` / `rx.peek`.
- Multi-Level Literal Prefix Trie router (**97.8× speedup** on 1,000 shared-prefix routes).
- Adaptive `SintApp` / `SintApp.router` for Flutter 3.47+ standalone `material_ui` and `cupertino_ui` packages + `SintRouterOutlet`.

---

## Horizon 1 — DevTools UI, Static Lints & Live Wasm Stress Showcase (`2.4.0`)

- **Flutter DevTools Extension UI Panel (`extension/devtools/`)**:
  - Visual companion panel backed by `2.3.0`'s `ext.sint.*` VM Service Extensions showing live DI graph, route stack, locale dictionaries, and real-time `Obx`/`ObxSelect` rebuild flame bars.
- **Companion `sint_lints` Package (`custom_lint` / Dart Analyzer plugin)**:
  - Real-time IDE diagnostics enforcing `Sint.pop()` inside dialogs/sheets, preventing `Bind.put(() => ...)` closure traps, warning on direct `Navigator.*` calls, and flagging unbatched multi-`Rx` mutations.
- **Interactive Web/Wasm Performance Stress Showcase**:
  - Live browser playground (256 Hz waveform visualizer + 1,000-route trie lookup + live `Sint.diagnostics` overlay) demonstrating SINT's real-time frame stability directly on `openneom.dev` / GitHub Pages.
- **AOT Competitor Benchmark Matrix**:
  - Extend `tool/benchmark_runner.dart` with `dart compile exe` AOT runs comparing SINT against `ValueNotifier`, Riverpod, and BLoC under both CRUD and 256 Hz telemetry workloads.

---

## Horizon 2 — `SINT 3.0.0`: The Legacy `Get` Purge & Pure Standalone Architecture

Because Flutter teams are actively migrating existing GetX codebases to SINT, **SINT `2.x` intentionally preserves all `@Deprecated` `Get*` aliases** (`Get`, `GetxController`, `GetxService`, `GetMaterialApp`, `GetCupertinoApp`, `GetPage`, `GetBuilder`, `GetRouterOutlet`, etc.) and `home:` with zero breaking changes.

In **SINT `3.0.0`**, once the broader community migration window has completed:

1. **Complete Removal of `@Deprecated` `Get*` Compatibility Layer**:
   - Remove `final Get = Sint`, `legacy_typedefs.dart`, `get_builder.dart`, `GetRouterOutlet`, and `RouteData.isGetPageRoute`.
2. **Declarative-Only Routing Contract**:
   - Remove `@Deprecated` `home:` in favor of `initialRoute` + `sintPages`.
3. **Pure Standalone Design Systems**:
   - Retire legacy SDK `package:flutter/material.dart` and `package:flutter/cupertino.dart` bridge wrappers (`SintMaterialApp` / `SintCupertinoApp`) in favor of `SintApp` with standalone `material_ui` and `cupertino_ui`.

---

## Release Summary

| Version | Milestone |
| --- | --- |
| **1.6.x – 1.7.0** | Type-keyed DI registry, $O(1)$ route disposal, standalone `SintApp` & `SintRouterOutlet` |
| **2.0.0** | Incremental $O(1)$ `Obx` engine, `Sint.batch`, `Sint.computed`, Multi-Level Trie Router |
| **2.1.0 – 2.2.2** | Contract-First DI, `MultiBinder` $O(1)$ depth, glitch-free `Computed`, reactive `.tr`, `Navigator`-free parity, Flutter 3.50 clean analysis |
| **2.3.0** | **`Sint.frameBatch`, `FrameThrottledRx`, `ObxSelect`, `dart run sint:migrate`, `Sint.diagnostics` & `ext.sint.*` VM Extensions** |
| **2.4.0** | DevTools UI panel, `sint_lints` analyzer plugin, interactive Web/Wasm stress demo |
| **3.0.0** | Removal of `@Deprecated` `Get*` aliases, legacy `home:`, and legacy SDK UI bridges |
