# SINT

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
- [Installing](#installing)
- [The Four Pillars](#the-four-pillars)
  - [State Management (S)](#state-management-s)
  - [Injection (I)](#injection-i)
  - [Navigation (N)](#navigation-n)
  - [Translation (T)](#translation-t)
- [Counter App with SINT](#counter-app-with-sint)
- [Migration from GetX](#migration-from-getx)
- [Origin & Philosophy](#origin--philosophy)

---

## About SINT

SINT is an architectural evolution of GetX (v5.0.0-rc), built as a focused framework around four pillars only:

| Pillar | Responsibility |
|---|---|
| **S** — State Management | `SintController`, `SintBuilder`, `Obx`, `.obs`, Rx types, Workers |
| **I** — Injection | `Sint.put`, `Sint.find`, `Sint.lazyPut`, Bindings, SmartManagement |
| **N** — Navigation | `SintPage`, `Sint.toNamed`, middleware, `SintMaterialApp`, transitions |
| **T** — Translation | `.tr` extension, `Translations` class, locale management |

Everything outside these four pillars has been removed: no HTTP client, no animations, no string validators, no generic utilities. The result is **37.7% less code** than GetX — 12,849 LOC vs 20,615 LOC.

**Key principles:**

- **PERFORMANCE:** No Streams or ChangeNotifier overhead. Minimal RAM consumption.
- **PRODUCTIVITY:** Simple syntax. One import: `import 'package:sint/sint.dart';`
- **ORGANIZATION:** Clean Architecture structure. 5 modules, each mapping to a pillar.

---

## Installing

Add SINT to your `pubspec.yaml`:

```yaml
dependencies:
  sint: ^1.0.0
```

Import it:

```dart
import 'package:sint/sint.dart';
```

---
## High-Fidelity Performance (Benchmarks)
SINT is built for speed. Every pillar is audited against the Open Neom Standard to ensure minimal latency in high-load scenarios.

Current Performance Audit (v1.0.0)
Pillar	Metric	Result	Context
S (State)	Reactive Core Speed	5.0151 µs/op	30,000 updates stress test
T (Translation)	Dynamic Interpolation	2.1614 µs/op	10,000 trParams lookups
I (Injection)	Registry Lookup	1.1688 µs/find	Depth 10 dependency resolution
N (Navigation)	Middleware Latency	1,504 µs	5-layer middleware chain execution
Core	Sync Latency	803 µs	Stream-to-Rx event synchronization

Why SINT is Faster:
•	Pillar S: SINT avoids Stream overhead by using microtasks for high-fidelity notifications.
•	Pillar I: Dependency resolution uses O(1) hash lookups in the global registry.
•	Pillar N: Navigation is context-less, removing the need for heavy widget tree lookups during routing.

## The Four Pillars

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

[Full documentation](documentation/en_US/state_management.md)

### Injection (I)

Dependency injection without context:

```dart
Sint.put(AuthController());
final controller = Sint.find<AuthController>();
```

[Full documentation](documentation/en_US/injection_management.md)

### Navigation (N)

Route management without context:

```dart
SintMaterialApp(
  getPages: [
    SintPage(name: '/', page: () => Home()),
    SintPage(name: '/details', page: () => Details()),
  ],
)

Sint.toNamed('/details');
Sint.back();
Sint.snackbar('Title', 'Message');
```

[Full documentation](documentation/en_US/navigation_management.md)

### Translation (T)

Internationalization with `.tr`:

```dart
Text('hello'.tr);
Text('welcome'.trParams({'name': 'Serzen'}));
Sint.updateLocale(Locale('es', 'ES'));
```

[Full documentation](documentation/en_US/translation_management.md)

---

## Counter App with SINT

```dart
void main() => runApp(SintMaterialApp(home: Home()));

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
          onPressed: () => Sint.to(Other()),
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
