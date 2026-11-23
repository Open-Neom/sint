# Translation Management (Pillar T)

- [Setup](#setup)
- [Defining Translations](#defining-translations)
- [Reactive `.tr`, Parameters & Plurals](#reactive-tr-parameters--plurals)
- [Lazy Locale Bundles & Zero-Reassemble Switching](#lazy-locale-bundles--zero-reassemble-switching)
- [Missing-Key Telemetry & Endpoint Translation](#missing-key-telemetry--endpoint-translation)
- [Runtime Inspection (`Sint.diagnostics`)](#runtime-inspection-sintdiagnostics)

---

SINT's **Translation** pillar provides `O(1)` pre-resolved dictionary lookups, single-pass `.trParams` interpolation, native `.tr` reactivity inside `Obx` / `ObxSelect` / `Computed`, lazy per-locale bundle loading, and zero-reassemble locale switching.

---

## Setup

Configure translations directly on `SintApp` (or `SintMaterialApp` / `SintCupertinoApp`):

```dart
SintApp(
  materialTheme: ThemeData(),
  translations: AppTranslations(),
  locale: Sint.deviceLocale ?? const Locale('en', 'US'),
  fallbackLocale: const Locale('en', 'US'),
  initialRoute: '/',
  sintPages: [...],
)
```

---

## Defining Translations

```dart
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      'hello': 'Hello World',
      'logged_in': 'Logged in as @name',
      'item_count_zero': 'No items',
      'item_count': '1 item',
      'item_count_plural': '@count items',
    },
    'es_ES': {
      'hello': 'Hola Mundo',
      'logged_in': 'Sesión iniciada como @name',
      'item_count_zero': 'Sin elementos',
      'item_count': '1 elemento',
      'item_count_plural': '@count elementos',
    },
  };
}
```

---

## Reactive `.tr`, Parameters & Plurals

`.tr` automatically registers a lightweight signal read whenever evaluated inside `Obx`, `ObxSelect`, or `Sint.computed`:

```dart
// Simple reactive translation
Obx(() => Text('hello'.tr))

// Single-pass parameter substitution
Obx(() => Text('logged_in'.trParams({'name': controller.userName.value})))

// Automatic _zero / singular / _other plural handling
Obx(() => Text(
  'item_count'.trPluralParams(
    'item_count_plural',
    controller.count.value,
    {'count': '${controller.count.value}'},
  ),
))
```

---

## Lazy Locale Bundles & Zero-Reassemble Switching

Defer large locale JSON/ARB bundles until actually selected by the user. Concurrent calls for the same locale share a single in-flight `Future`:

```dart
Sint.registerLazyTranslations('fr_FR', () async {
  return await loadFrenchDictionary();
});

// Loads lazily (if needed) and updates all active Obx/.tr widgets in O(1)
// WITHOUT calling WidgetsBinding.performReassemble():
await Sint.updateLocale(const Locale('fr', 'FR'));
```

You can also merge modular package dictionaries incrementally at runtime using `Sint.appendTranslations({...})` (safely clones `const` maps).

---

## Missing-Key Telemetry & Endpoint Translation

```dart
// Report missing keys in CI or analytics:
Sint.onMissingTranslationKey = (key, locale) {
  Sint.log('Missing translation "$key" for $locale');
};
```

Set `translateEndpoints: true` on `SintApp` to localize URL route segments automatically via `PathTranslator`.

---

## Runtime Inspection (`Sint.diagnostics`)

```dart
final i18n = Sint.diagnostics.localizationSnapshot();
// { locale, fallbackLocale, loadedLocales, lazyLoaderLocales, dictionarySizes }
```
