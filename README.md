# SINT

<p align="center">
  <img src="https://raw.githubusercontent.com/Open-Neom/sint/main/assets/SINT%20-%20Logo%20-%202026.png" alt="SINT Framework" width="280"/>
</p>

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
- [Material and Cupertino Migration Notice](#material-and-cupertino-migration-notice)
- [1.7.0 Development Preview](#170-development-preview)
- [Installing](#installing)
- [The Four Pillars](#the-four-pillars)
  - [State Management (S)](#state-management-s)
  - [Injection (I)](#injection-i)
  - [Navigation (N)](#navigation-n)
  - [Translation (T)](#translation-t)
- [Flutter Web & Deep Links](#flutter-web--deep-links)
- [Counter App with SINT](#counter-app-with-sint)
- [Migration from GetX](#migration-from-getx)
- [Origin & Philosophy](#origin--philosophy)

---

## About SINT

SINT is an architectural evolution of GetX (v5.0.0-rc), built as a focused framework around four pillars only:

| Pillar | Responsibility |
|---|---|
| **S** — State Management | `SintController`, `SintBuilder`, `Obx`, `.obs`, Rx types, Workers, `SintStatus`, `SintListener` |
| **I** — Injection | `Sint.put`, `Sint.find`, `Sint.lazyPut`, `Sint.putAsync`, Bindings, SmartManagement |
| **N** — Navigation | `SintPage`, `Sint.toNamed`, `Sint.toInitial`, `routeParam`, `pathParam`, `queryParam`, `pathParams`/`queryParams` API, pattern params & wildcards, O(k) route index, middleware, `SintMaterialApp`, `SintSnackBarStyle`, `SintUrlStrategy`, web-safe `back()` |
| **T** — Translation | `.tr` extension, `Translations` class, locale management, `loadTranslations`, `PathTranslator`, `translateEndpoints` |

Everything outside these four pillars has been removed: no HTTP client, no animations, no string validators, no generic utilities. The result is **37.7% less code** than GetX — 12,849 LOC vs 20,615 LOC.

**Key principles:**

- **PERFORMANCE:** Direct synchronous notifications for widgets; lazy asynchronous streams for `listen` and workers. Measure both paths separately.
- **PRODUCTIVITY:** Simple syntax. One import: `import 'package:sint/sint.dart';`
- **ORGANIZATION:** Clean Architecture structure. 5 modules, each mapping to a pillar.

---

## Material and Cupertino Migration Notice

> **Local development preview: SINT 1.7.0-dev.1.**
> `SintApp` provides standalone Material/Cupertino hosts in the current source.
> This is development status, not a claim that a stable release is published.
> This version requires **Flutter >=3.44.0 / Dart >=3.12.0**, including when
> using the legacy application classes.

`SintApp` selects Cupertino on iOS and Material on other target platforms. Set
`design: SintDesign.material` or `SintDesign.cupertino` to override that choice.
On web, automatic selection follows the browser's target platform. Configure
`materialTheme` with `material_ui.ThemeData` and `cupertinoTheme` with
`cupertino_ui.CupertinoThemeData`; a platform check does not convert these types.

The existing `SintMaterialApp` and `SintCupertinoApp` keep their SDK types.
`SintApp(theme: sdkTheme)` temporarily uses the legacy Material host and emits
a targeted `@Deprecated` analyzer diagnostic directing users to the new theme
arguments. Do not combine that legacy parameter with standalone themes. There
is no announced removal date. State, injection and translation are unaffected.

The [migration guide](MIGRATION_DESIGN_SYSTEMS.md) documents current imports,
working API shapes, theme operations, compatibility bridges and validation
requirements.

## 1.7.0 Development Preview

- `SintApp` and `SintApp.router` share the existing SINT root, registry and router
  while choosing a standalone design-system host.
- Synchronize declarative history with imperative `Navigator` removals and back actions (`SintDelegate`, `SintNavigator`, `SintAppBar`).
- Typed Material/Cupertino theme configuration, queries and runtime theme setters
  coexist with legacy APIs.
- See [CHANGELOG.md](CHANGELOG.md) for the complete history of releases (`1.1.0` through `1.7.0-dev.1`).

---

## Installing

Add SINT to your `pubspec.yaml`:

```yaml
dependencies:
  sint: ^1.6.2
```

Import it:

```dart
import 'package:sint/sint.dart';
```

---

## High-Fidelity Performance (Benchmarks)

See [benchmark methodology](test/benchmarks/README.md) for the serial runner, raw JSON artifacts and comparison tool, and [the performance app](performance/README.md) for profile/release frame measurements.

The suite distinguishes synchronous listener dispatch from asynchronous stream delivery; covers DI lookup and route disposal separately; and tests both distinct and shared route prefixes. Every workload asserts its observable outcome. Reported microbenchmark statistics describe means of timed batches, not frame times or per-operation tail latency.

CI separates correctness/coverage from serial benchmarks. Timing regressions require comparable machine, SDK, harness and execution-mode metadata plus an explicit budget; shared-runner noise is not a reliable universal pass/fail threshold. No comparative BLoC speed claim is made without an equivalent, executable benchmark.

---

## The Four Pillars

<p align="center">
  <img src="https://raw.githubusercontent.com/Open-Neom/sint/main/assets/SINT%20-%20Framework%20-%202026.png" alt="SINT — The Four Pillars" width="700"/>
</p>

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

**Workers** for reactive side effects:

```dart
ever(rx, callback);       // Every change
once(rx, callback);       // First change only
debounce(rx, callback);   // After pause (400ms default)
interval(rx, callback);   // Max once per duration (1s default)
```

**SintStatus** for async state:

```dart
status.value.when(
  loading: () => spinner,
  success: (data) => content(data),
  error: (err) => errorView(err),
  empty: () => emptyView,
);
```

[Full documentation](documentation/en_US/state_management.md)

### Injection (I)

Dependency injection without context:

```dart
Sint.put(AuthController());
Sint.lazyPut(() => ApiService());
await Sint.putAsync(() => SharedPreferences.getInstance());

final controller = Sint.find<AuthController>();
```

[Full documentation](documentation/en_US/injection_management.md)

### Navigation (N)

Route management without context — O(k) route matching, optimized for web deep links and mobile alike:

```dart
SintMaterialApp(
  initialRoute: '/',
  translateEndpoints: true,                          // i18n URLs (web)
  snackBarStyle: SintSnackBarStyle(...),              // Global theming
  sintPages: [
    SintPage(name: '/', page: () => Home()),
    SintPage(name: '/book/:bookId', page: () => BookDetail()),
    SintPage(name: '/user/:id(\\d+)', page: () => UserDetail()), // pattern param
    SintPage(name: '/docs/:path*', page: () => DocsViewer()),    // wildcard
    SintPage(name: '/search', page: () => Search()),
  ],
)

// Navigation
Sint.toNamed('/book/abc123?ref=home');
Sint.toNamed('/user/:id',
  pathParams: {'id': '42'},
  queryParams: {'tab': 'posts'},
);                                                   // → /user/42?tab=posts
Sint.back();                                         // Web-safe
Sint.toInitial();                                    // Hard reset to home
Sint.toInitial(keep: {AuthController});              // Keep specific controllers

// RESTful parameter extraction
String? id   = Sint.routeParam;                      // 'abc123'
String? id   = Sint.pathParam('bookId');              // 'abc123'
String? ref  = Sint.queryParam('ref');                // 'home'
String  sort = Sint.queryParamOrDefault('sort', 'a'); // 'a' (default)

// Path and query parameters, separated
String? uid  = Sint.pathParams['id'];                 // path params only
String? tab  = Sint.queryParams['tab'];               // query params only

// Snackbar with global style
Sint.snackbar('Title', 'Message');
```

Route syntax precedence: **literal > param with pattern > simple param > wildcard** (registration order preserved within each kind).

[Full documentation](documentation/en_US/navigation_management.md)

### Translation (T)

Internationalization with `.tr` — now powers URL routing too:

```dart
Text('hello'.tr);
Text('welcome'.trParams({'name': 'Serzen'}));
Sint.updateLocale(Locale('es', 'ES'));

// Lazy loading per module
await Sint.loadTranslations(() async {
  final json = await rootBundle.loadString('assets/i18n/shop.json');
  return {'es': Map<String, String>.from(jsonDecode(json))};
});

// URL path translation (automatic when translateEndpoints: true)
// Your translation keys double as URL segment mappings:
//   'book' → 'libro' (ES), 'livre' (FR), 'buch' (DE)
//
// PathTranslator handles:
//   canonicalizePath('/libro/abc')  → '/book/abc'   (incoming)
//   localizePath('/book/abc', 'es') → '/libro/abc'  (outgoing)
```

[Full documentation](documentation/en_US/translation_management.md)

---

## Flutter Web & Deep Links

SINT is designed with a **web-first, mobile-safe** philosophy. Every feature works identically across platforms, but web gets extra optimizations:

| Feature | Web Behavior | Mobile Behavior |
|---------|-------------|-----------------|
| `Sint.back()` | No-op if no internal history (browser arrows handle it) | Standard `Navigator.pop()` |
| `Sint.routeParam` | Extracted from browser URL path | Extracted from route arguments |
| `Sint.queryParam()` | Extracted from URL query string `?key=value` | Extracted from route arguments |
| `translateEndpoints` | Localizes browser URL bar + canonicalizes incoming URLs | No overhead — flag is ignored |
| Vanity / slug URLs | `unknownRoute` fires correctly for `/slug` paths; original URL preserved | Same behavior via deep links |
| Browser back/forward | Synced with internal stack — revisiting a URL pops to it instead of duplicating | Standard stack behavior |
| URL strategy | `SintUrlStrategy.setPath()` / `setHash()` in `main()` before `runApp()` | Ignored (no browser URL) |
| State restoration | Route state passed through `restoreRouteInformation` | Same |
| `Sint.showBackButton` | `false` (browser has native arrows) | `true` |
| Default transition | `Transition.fade` (GPU-light for web canvas) | Platform default (Cupertino/Material) |
| Scroll behavior | Drag enabled for touch, mouse, and trackpad | Platform default |
| `SintSnackBarStyle` | Same styling across web and mobile | Same styling across web and mobile |

### Deep Link Example (Web + Mobile)

```dart
// 1. Define routes with parameters
SintMaterialApp(
  initialRoute: '/',
  translateEndpoints: true,
  translationsKeys: AppTranslations.keys,
  locale: Locale('es'),
  sintPages: [
    SintPage(name: '/', page: () => HomePage()),
    SintPage(name: '/book/:bookId', page: () => BookDetail()),
    SintPage(name: '/profile/:userId', page: () => ProfilePage()),
  ],
)

// 2. In your controller — same code works everywhere
class BookDetailController extends SintController {
  late final String bookId;

  @override
  void onInit() {
    super.onInit();
    // Works from: browser URL, deep link, or Sint.toNamed()
    bookId = Sint.routeParam ?? '';
    loadBook(bookId);
  }
}
```

**On web:** User visits `https://myapp.com/libro/abc123` →
SINT canonicalizes to `/book/abc123` → routes to `BookDetail` →
`Sint.routeParam` returns `'abc123'` → browser shows `/libro/abc123`.

**On mobile:** `Sint.toNamed('/book/abc123')` →
routes to `BookDetail` → `Sint.routeParam` returns `'abc123'`.

**Same controller. Same routes. Same parameters. Zero platform checks.**

---

## Counter App with SINT

```dart
void main() => runApp(SintMaterialApp(
  initialRoute: '/',
  sintPages: [
    SintPage(name: '/', page: () => Home()),
    SintPage(name: '/other', page: () => Other()),
  ],
));

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
          onPressed: () => Sint.toNamed('/other'),
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
