# Gestión de Traducciones (Pilar T)

- [Configuración](#configuración)
- [Definición de Traducciones](#definición-de-traducciones)
- [`.tr` Reactivo, Parámetros y Plurales](#tr-reactivo-parámetros-y-plurales)
- [Carga Perezosa de Idiomas y Cambio Sin `performReassemble()`](#carga-perezosa-de-idiomas-y-cambio-sin-performreassemble)
- [Telemetría de Llaves Faltantes y Diagnóstico](#telemetría-de-llaves-faltantes-y-diagnóstico)

---

El pilar **Translation** de SINT ofrece búsquedas en caché `O(1)`, interpolación `.trParams` en una sola pasada, reactividad nativa de `.tr` dentro de `Obx` / `ObxSelect` / `Computed`, carga diferida por idioma y cambio de locale sin reconstruir toda la aplicación.

---

## Configuración

```dart
SintApp(
  materialTheme: ThemeData(),
  translations: AppTranslations(),
  locale: Sint.deviceLocale ?? const Locale('es', 'ES'),
  fallbackLocale: const Locale('en', 'US'),
  initialRoute: '/',
  sintPages: [...],
)
```

---

## Definición de Traducciones

```dart
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'es_ES': {
      'hello': 'Hola Mundo',
      'logged_in': 'Sesión iniciada como @name',
      'item_count_zero': 'Sin elementos',
      'item_count': '1 elemento',
      'item_count_plural': '@count elementos',
    },
    'en_US': {
      'hello': 'Hello World',
      'logged_in': 'Logged in as @name',
      'item_count_zero': 'No items',
      'item_count': '1 item',
      'item_count_plural': '@count items',
    },
  };
}
```

---

## `.tr` Reactivo, Parámetros y Plurales

```dart
Obx(() => Text('hello'.tr))

Obx(() => Text('logged_in'.trParams({'name': controller.userName.value})))

Obx(() => Text(
  'item_count'.trPluralParams(
    'item_count_plural',
    controller.count.value,
    {'count': '${controller.count.value}'},
  ),
))
```

---

## Carga Perezosa de Idiomas y Cambio Sin `performReassemble()`

```dart
Sint.registerLazyTranslations('fr_FR', () async {
  return await loadFrenchDictionary();
});

// Carga el bundle si falta y actualiza todos los Obx/.tr en O(1)
// SIN llamar a WidgetsBinding.performReassemble():
await Sint.updateLocale(const Locale('fr', 'FR'));
```

También puedes fusionar diccionarios de módulos dinámicamente con `Sint.appendTranslations({...})`.

---

## Telemetría de Llaves Faltantes y Diagnóstico

```dart
Sint.onMissingTranslationKey = (key, locale) {
  Sint.log('Traducción faltante "$key" para $locale');
};

final i18n = Sint.diagnostics.localizationSnapshot();
```
