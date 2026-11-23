# State Management (Pillar S)

- [Reactive Signals (`.obs`, `Obx`, `ObxSelect`)](#reactive-signals-obs-obx-obxselect)
- [Derived State (`Sint.computed`) & Synchronous Batching (`Sint.batch`)](#derived-state-sintcomputed--synchronous-batching-sintbatch)
- [High-Frequency Real-Time UI (`Sint.frameBatch` & `FrameThrottledRx`)](#high-frequency-real-time-ui-sintframebatch--framethrottledrx)
- [Async State (`RxFuture<T>` & `SintStatus<T>`)](#async-state-rxfuturet--sintstatust)
- [Zero-Stream Synchronous Workers](#zero-stream-synchronous-workers)
- [Simple State Manager (`SintBuilder`)](#simple-state-manager-sintbuilder)
- [Runtime Rebuild Profiling (`Sint.diagnostics`)](#runtime-rebuild-profiling-sintdiagnostics)
- [Performance Notes](#performance-notes)

---

SINT's **State** pillar is a zero-Stream synchronous signals engine built for both everyday UI and extreme-performance Flutter workloads (real-time audio DAWs, 3D/VR HUDs, 256 Hz EEG streams, and on-device LLM token streams).

---

## Reactive Signals (`.obs`, `Obx`, `ObxSelect`)

Make any value observable with `.obs`:

```dart
final count = 0.obs;
final name = 'SINT'.obs;
final items = <String>[].obs;
final user = User(name: 'Serzen', age: 30).obs;
```

### `Obx` (Zero-Allocation Single-Slot Fast Path)

```dart
Obx(
  () => Text('${controller.count.value}'),
  debugLabel: 'counter-label', // Optional label for Sint.diagnostics
)
```

- `Obx` only rebuilds when an observed value actually changes (`==`).
- Single-signal `Obx` widgets store their subscription inline with zero `Map`/`Set`/`List` allocations.
- Conditional `if`/`else` branches are pruned automatically on every build — zero stale listener leaks.
- Read values without tracking via `rx.peek` or `Sint.untrack(() => ...)`.

### `ObxSelect<T>` (Inline Fine-Grained Selector — SINT 2.3)

Observe a single slice of a rich `Rx<Model>` without declaring boilerplate `Computed` fields:

```dart
ObxSelect<double>(
  debugLabel: 'alpha-power',
  selector: () => controller.telemetry.value.alphaPower,
  equals: (prev, next) => (prev - next).abs() < 0.05, // Optional custom equality
  builder: (power) => Text('${power.toStringAsFixed(2)} µV'),
)
```

---

## Derived State (`Sint.computed`) & Synchronous Batching (`Sint.batch`)

```dart
class CartController extends SintController {
  final items = 1.obs;
  final price = 25.0.obs;
  final tax = 2.0.obs;

  // Glitch-free tri-color diamond propagation; auto-disposed on onClose().
  // Pass `lazy: true` to defer evaluation while unobserved.
  late final total = computed(() => (items.value * price.value) + tax.value);

  void applyBundle() => Sint.batch(() {
    items.value += 2;
    price.value = 20.0;
    tax.value = 1.5;
  }); // Recomputes `total` and notifies `Obx` ONCE instead of 3 times.
}
```

---

## High-Frequency Real-Time UI (`Sint.frameBatch` & `FrameThrottledRx`)

For streams arriving faster than display refresh (60–1000 Hz audio playheads, VU meters, EEG biosignals, VR controllers, or 100 tok/s LLM streams):

### 1. `Sint.frameBatch` (VSync-Aligned Coalescing)

```dart
/// Safe to call at 256+ Hz from FFI, DSP, or WebSocket callbacks:
void onHardwarePacket(double sample, double peakDb) {
  Sint.frameBatch(() {
    eegSample.value = sample;
    meterDb.value = peakDb;
  });
}
```

Multiple `Sint.frameBatch` calls arriving across separate async ticks coalesce in `O(1)` into **at most one UI flush right before the next Flutter VSync frame**. Call `Sint.flushFrameBatch()` if you need to force an immediate flush in tests or shutdown hooks.

### 2. `FrameThrottledRx<T>` (`rx.throttledToFrame()` / `controller.frameThrottled(rx)`)

```dart
class SynthController extends SintController {
  final rawPlayheadMs = 0.obs;

  // Coalesced to 1 emit/VSync; skips notifications when unobserved or when
  // sub-frame jitter returns to the last emitted value. Auto-disposed on onClose().
  late final uiPlayheadMs = frameThrottled(rawPlayheadMs);
}
```

- **Zero `StreamController` and zero `Timer` allocations**.
- Works natively with `Obx`, `ObxSelect`, `Computed`, `ever`, and Flutter's `ValueListenableBuilder`.

---

## Async State (`RxFuture<T>` & `SintStatus<T>`)

Use `rxFuture(...)` inside `SintController` for stale-while-revalidate async state with exhaustive Dart 3 pattern matching:

```dart
class ProfileController extends SintController {
  late final profile = rxFuture(() => repo.fetchProfile());
}

Obx(() => switch (controller.profile.value) {
  LoadingStatus(:final previousData) when previousData != null =>
      ProfileBody(previousData, refreshing: true),
  LoadingStatus() => const CircularProgressIndicator(),
  SuccessStatus(:final data) => ProfileBody(data),
  EmptyStatus() => const Text('No profile found'),
  ErrorStatus(:final error) => Text('Error: $error'),
})
```

---

## Zero-Stream Synchronous Workers

Workers run directly on `ListNotifier` callbacks (zero `StreamController` overhead) and are automatically disposed when their `SintController` closes:

```dart
@override
void onInit() {
  super.onInit();
  ever<int>(count, (v) => Sint.log('changed: $v'));
  everAll([items, price], (_) => Sint.log('inputs changed'));
  once<int>(count, (v) => Sint.log('first change: $v'));
  debounce<String>(query, (q) => search(q), time: const Duration(milliseconds: 300));
  interval<int>(clicks, (c) => track(c), time: const Duration(seconds: 1));
}
```

---

## Simple State Manager (`SintBuilder`)

For coarse manual rebuilds without reactive `.obs` fields:

```dart
class CounterController extends SintController {
  int counter = 0;
  void increment() {
    counter++;
    update(['counter-text']); // Empty dynamic ID groups are auto-pruned on unmount
  }
}

SintBuilder<CounterController>(
  id: 'counter-text',
  init: CounterController(),
  builder: (c) => Text('${c.counter}'),
)
```

---

## Runtime Rebuild Profiling (`Sint.diagnostics`)

Enable opt-in rebuild tracking in debug/profile mode (zero release overhead):

```dart
Sint.diagnostics.enableRebuildTracking = true;
// Interact with your screen...
print(Sint.diagnostics.rebuildStats()); // Sorted descending by rebuild count
```

---

## Performance Notes

Measured on the Dart VM JIT harness ([`four_pillars_benchmark_test.dart`](../../test/benchmarks/four_pillars_benchmark_test.dart), [`high_frequency_benchmark_test.dart`](../../test/benchmarks/high_frequency_benchmark_test.dart)):

| Workload | SINT 2.3 Median | Baseline | Speedup |
| --- | ---: | ---: | --- |
| 60 frames × 8 bursts/frame (256–480 Hz) × 50 subs | **`20.6 µs`** (`Sint.frameBatch`) | `73.3 µs` (`ValueNotifier`) | **8× fewer dispatches · 3.56× faster** |
| 20-widget screen, 4-field transaction + derived total | **`0.23 µs/op`** (`Sint.batch` + `Computed`) | `0.90 µs/op` (`ChangeNotifier`) | **4.0× faster** |
| Pure signal notify (1 listener) | **`0.010 µs/op`** | — | Allocation-free hot path |
