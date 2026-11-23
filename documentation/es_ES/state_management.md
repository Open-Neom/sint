# Gestión de Estado (Pilar S)

- [Señales Reactivas (`.obs`, `Obx`, `ObxSelect`)](#señales-reactivas-obs-obx-obxselect)
- [Estado Derivado (`Sint.computed`) y Batch Síncrono (`Sint.batch`)](#estado-derivado-sintcomputed-y-batch-síncrono-sintbatch)
- [UI de Alta Frecuencia en Tiempo Real (`Sint.frameBatch` y `FrameThrottledRx`)](#ui-de-alta-frecuencia-en-tiempo-real-sintframebatch-y-framethrottledrx)
- [Estado Asíncrono (`RxFuture<T>` y `SintStatus<T>`)](#estado-asíncrono-rxfuturet-y-sintstatust)
- [Workers Síncronos Zero-Stream](#workers-síncronos-zero-stream)
- [Gestor Simple (`SintBuilder`)](#gestor-simple-sintbuilder)
- [Perfilado en Tiempo de Ejecución (`Sint.diagnostics`)](#perfilado-en-tiempo-de-ejecución-sintdiagnostics)

---

El pilar **State** de SINT es un motor de señales síncrono sin `Stream`s diseñado tanto para apps convencionales como para cargas extremas de Flutter (DAWs de audio en tiempo real, HUDs 3D/VR, flujos EEG de 256 Hz y streaming LLM en dispositivo).

---

## Señales Reactivas (`.obs`, `Obx`, `ObxSelect`)

Convierte cualquier valor en observable con `.obs`:

```dart
final count = 0.obs;
final name = 'SINT'.obs;
final items = <String>[].obs;
final user = User(name: 'Serzen', age: 30).obs;
```

### `Obx` (Ruta Rápida Single-Slot sin Asignaciones)

```dart
Obx(
  () => Text('${controller.count.value}'),
  debugLabel: 'counter-label', // Etiqueta opcional para Sint.diagnostics
)
```

- `Obx` solo reconstruye cuando el valor observado cambia realmente (`==`).
- Los widgets `Obx` de 1 señal almacenan su suscripción inline sin crear `Map`/`Set`/`List`.
- Las ramas condicionales `if`/`else` se podan automáticamente en cada build — cero fugas de listeners.
- Lee sin suscribirte usando `rx.peek` o `Sint.untrack(() => ...)`.

### `ObxSelect<T>` (Selector Fino Inline — SINT 2.3)

Observa una única propiedad de un `Rx<Model>` sin declarar campos `Computed` extra:

```dart
ObxSelect<double>(
  debugLabel: 'alpha-power',
  selector: () => controller.telemetry.value.alphaPower,
  equals: (prev, next) => (prev - next).abs() < 0.05,
  builder: (power) => Text('${power.toStringAsFixed(2)} µV'),
)
```

---

## Estado Derivado (`Sint.computed`) y Batch Síncrono (`Sint.batch`)

```dart
class CartController extends SintController {
  final items = 1.obs;
  final price = 25.0.obs;
  final tax = 2.0.obs;

  // Propagación glitch-free en diamante; auto-disposed en onClose().
  late final total = computed(() => (items.value * price.value) + tax.value);

  void applyBundle() => Sint.batch(() {
    items.value += 2;
    price.value = 20.0;
    tax.value = 1.5;
  }); // Recalcula `total` y notifica a `Obx` UNA sola vez en lugar de 3.
}
```

---

## UI de Alta Frecuencia en Tiempo Real (`Sint.frameBatch` y `FrameThrottledRx`)

Para flujos más rápidos que el refresco de pantalla (60–1000 Hz en audio DSP, EEG, VR o streaming de tokens LLM):

### 1. `Sint.frameBatch` (Agrupación Alineada a VSync)

```dart
/// Seguro a 256+ Hz desde callbacks FFI, DSP o WebSocket:
void onHardwarePacket(double sample, double peakDb) {
  Sint.frameBatch(() {
    eegSample.value = sample;
    meterDb.value = peakDb;
  });
}
```

Múltiples mutaciones en ticks separados se agrupan en `O(1)` en **como máximo un flush antes del siguiente frame VSync** (**8× menos dispatches** y **3.56× más rápido** que `ValueNotifier` sin agrupar). Usa `Sint.flushFrameBatch()` para forzar un flush inmediato.

### 2. `FrameThrottledRx<T>` (`rx.throttledToFrame()` / `controller.frameThrottled(rx)`)

```dart
class SynthController extends SintController {
  final rawPlayheadMs = 0.obs;

  // 1 emisión máxima por VSync; omite notificaciones si no hay listeners o si
  // el jitter vuelve al último valor emitido. Auto-disposed en onClose().
  late final uiPlayheadMs = frameThrottled(rawPlayheadMs);
}
```

---

## Estado Asíncrono (`RxFuture<T>` y `SintStatus<T>`)

```dart
class ProfileController extends SintController {
  late final profile = rxFuture(() => repo.fetchProfile());
}

Obx(() => switch (controller.profile.value) {
  LoadingStatus(:final previousData) when previousData != null =>
      ProfileBody(previousData, refreshing: true),
  LoadingStatus() => const CircularProgressIndicator(),
  SuccessStatus(:final data) => ProfileBody(data),
  EmptyStatus() => const Text('Sin datos'),
  ErrorStatus(:final error) => Text('Error: $error'),
})
```

---

## Workers Síncronos Zero-Stream

```dart
@override
void onInit() {
  super.onInit();
  ever<int>(count, (v) => Sint.log('cambió: $v'));
  everAll([items, price], (_) => Sint.log('entradas actualizadas'));
  once<int>(count, (v) => Sint.log('primer cambio: $v'));
  debounce<String>(query, (q) => search(q), time: const Duration(milliseconds: 300));
  interval<int>(clicks, (c) => track(c), time: const Duration(seconds: 1));
}
```

---

## Gestor Simple (`SintBuilder`)

```dart
class CounterController extends SintController {
  int counter = 0;
  void increment() {
    counter++;
    update(['counter-text']);
  }
}

SintBuilder<CounterController>(
  id: 'counter-text',
  init: CounterController(),
  builder: (c) => Text('${c.counter}'),
)
```

---

## Perfilado en Tiempo de Ejecución (`Sint.diagnostics`)

```dart
Sint.diagnostics.enableRebuildTracking = true;
print(Sint.diagnostics.rebuildStats()); // Ordenado descendentemente por número de rebuilds
```
