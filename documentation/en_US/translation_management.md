# Translation Management

- [Setup](#setup)
- [Defining translations](#defining-translations)
- [Using translations](#using-translations)
  - [Simple translation](#simple-translation)
  - [Translation with parameters](#translation-with-parameters)
  - [Plural translations](#plural-translations)
- [Changing locale](#changing-locale)
- [System locale](#system-locale)
- [Test Roadmap](#test-roadmap)

---

SINT's **Translation** pillar provides internationalization (i18n) support using a simple key-value dictionary system with the `.tr` extension.

---

## Setup

Configure translations in `SintMaterialApp`:

```dart
SintMaterialApp(
  translations: AppTranslations(),
  locale: Locale('en', 'US'),
  fallbackLocale: Locale('en', 'US'),
  home: MyHome(),
)
```

---

## Defining translations

Create a class extending `Translations`:

```dart
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      'hello': 'Hello World',
      'logged_in': 'Logged in as @name',
    },
    'es_ES': {
      'hello': 'Hola Mundo',
      'logged_in': 'Sesion iniciada como @name',
    },
    'ar_EG': {
      'hello': 'مرحبا بالعالم',
      'logged_in': 'تم تسجيل الدخول باسم @name',
    },
  };
}
```

---

## Using translations

### Simple translation

```dart
Text('hello'.tr); // "Hello World" or "Hola Mundo" depending on locale
```

### Translation with parameters

```dart
Text('logged_in'.trParams({'name': 'Serzen'}));
// "Logged in as Serzen"
```

### Plural translations

```dart
Text('item_count'.trPlural('items_count', itemList.length, args));
```

---

## Changing locale

```dart
var locale = Locale('es', 'ES');
Sint.updateLocale(locale);
```

All widgets using `.tr` will automatically update.

---

## System locale

Use the device's locale:

```dart
SintMaterialApp(
  locale: Sint.deviceLocale,
)
```

---

## Test Roadmap

Tests for Translation are retained from the original GetX test suite. Future enhancements:

- **Dynamic per-module translation loading** on demand
- **Build-time `.tr` key validation** across all locales
- **RTL/LTR layout integration** tied to locale changes
- Missing key fallback tests
- Parameter substitution tests
- Locale change reactivity tests
- Plural form handling for various languages
