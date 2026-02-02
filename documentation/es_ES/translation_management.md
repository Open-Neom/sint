# Gestion de Traducciones

SINT proporciona un sistema de internacionalizacion (i18n) simple y potente que permite traducir tu aplicacion sin context y con soporte completo para pluralizacion.

## Tabla de Contenidos

- [Configuracion Inicial](#configuracion-inicial)
- [Translations Class](#translations-class)
- [Extension .tr](#extension-tr)
- [Parametros en Traducciones](#parametros-en-traducciones)
  - [trParams](#trparams)
- [Pluralizacion](#pluralizacion)
  - [trPlural](#trplural)
- [Cambiar Idioma](#cambiar-idioma)
- [Locale del Sistema](#locale-del-sistema)
- [Traducciones por Modulo](#traducciones-por-modulo)
- [Fallback](#fallback)
- [Best Practices](#best-practices)
- [Test Roadmap](#test-roadmap)

---

## Configuracion Inicial

### 1. Definir traducciones

Crea una clase que extienda `Translations`:

```dart
import 'package:sint/sint.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'es_ES': {
      'hello': 'Hola',
      'welcome': 'Bienvenido',
      'goodbye': 'Adios',
    },
    'en_US': {
      'hello': 'Hello',
      'welcome': 'Welcome',
      'goodbye': 'Goodbye',
    },
    'fr_FR': {
      'hello': 'Bonjour',
      'welcome': 'Bienvenue',
      'goodbye': 'Au revoir',
    },
  };
}
```

### 2. Configurar SintMaterialApp

```dart
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SintMaterialApp(
      translations: AppTranslations(),
      locale: Locale('es', 'ES'), // Idioma inicial
      fallbackLocale: Locale('en', 'US'), // Idioma por defecto
      home: HomePage(),
    );
  }
}
```

---

## Translations Class

La clase `Translations` centraliza todas las traducciones:

```dart
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'es_ES': es_ES,
    'en_US': en_US,
    'pt_BR': pt_BR,
  };
}

// Archivo separado: es_ES.dart
const Map<String, String> es_ES = {
  // Home
  'home_title': 'Inicio',
  'home_subtitle': 'Bienvenido a SINT',

  // Buttons
  'btn_save': 'Guardar',
  'btn_cancel': 'Cancelar',
  'btn_delete': 'Eliminar',

  // Messages
  'msg_success': 'Operacion exitosa',
  'msg_error': 'Ocurrio un error',

  // Forms
  'form_email': 'Correo electronico',
  'form_password': 'Contraseña',
  'form_confirm_password': 'Confirmar contraseña',
};

// Archivo separado: en_US.dart
const Map<String, String> en_US = {
  'home_title': 'Home',
  'home_subtitle': 'Welcome to SINT',
  'btn_save': 'Save',
  'btn_cancel': 'Cancel',
  'btn_delete': 'Delete',
  // ...
};
```

---

## Extension .tr

Usa la extension `.tr` para traducir strings:

```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('home_title'.tr),
      ),
      body: Column(
        children: [
          Text('home_subtitle'.tr),
          ElevatedButton(
            onPressed: () {},
            child: Text('btn_save'.tr),
          ),
        ],
      ),
    );
  }
}
```

**Sin context:**

```dart
// En controllers, services, etc.
void showMessage() {
  print('msg_success'.tr); // Funciona sin BuildContext
}
```

**Traduccion con clave faltante:**

Si una clave no existe, devuelve la clave misma:

```dart
'non_existent_key'.tr // Devuelve: "non_existent_key"
```

---

## Parametros en Traducciones

### trParams

Usa `@param` como placeholder y reemplazalo con `trParams`:

```dart
// Definir traduccion
const Map<String, String> es_ES = {
  'welcome_user': 'Bienvenido, @name',
  'items_count': 'Tienes @count elementos en tu carrito',
  'profile': 'Perfil de @user (@age años)',
};

// Usar
Text('welcome_user'.trParams({'name': 'Juan'}));
// Output: "Bienvenido, Juan"

Text('items_count'.trParams({'count': '5'}));
// Output: "Tienes 5 elementos en tu carrito"

Text('profile'.trParams({'user': 'Ana', 'age': '25'}));
// Output: "Perfil de Ana (25 años)"
```

**Multiples parametros:**

```dart
const Map<String, String> es_ES = {
  'order_summary': 'Pedido #@orderId - @items articulos - Total: @total',
};

Text('order_summary'.trParams({
  'orderId': '12345',
  'items': '3',
  'total': '\$150.00',
}));
// Output: "Pedido #12345 - 3 articulos - Total: $150.00"
```

---

## Pluralizacion

### trPlural

Maneja singular/plural automaticamente:

```dart
// Definir traducciones
const Map<String, String> es_ES = {
  'apple': 'manzana',
  'apples': 'manzanas',
  'person': 'persona',
  'people': 'personas',
};

// Usar
Text('apple'.trPlural('apples', 1));  // "manzana"
Text('apple'.trPlural('apples', 5));  // "manzanas"
Text('person'.trPlural('people', 1)); // "persona"
Text('person'.trPlural('people', 10)); // "personas"
```

**Con parametros:**

```dart
const Map<String, String> es_ES = {
  'item_count': '@count articulo',
  'items_count': '@count articulos',
};

Text('item_count'.trPlural('items_count', 1, args: {'count': '1'}));
// Output: "1 articulo"

Text('item_count'.trPlural('items_count', 5, args: {'count': '5'}));
// Output: "5 articulos"
```

**Ejemplo completo:**

```dart
class CartWidget extends StatelessWidget {
  final int itemCount;

  CartWidget({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return Text(
      'cart_item'.trPlural(
        'cart_items',
        itemCount,
        args: {'count': itemCount.toString()},
      ),
    );
  }
}

// Traducciones
const Map<String, String> es_ES = {
  'cart_item': 'Tienes @count articulo en tu carrito',
  'cart_items': 'Tienes @count articulos en tu carrito',
};

// itemCount = 1 -> "Tienes 1 articulo en tu carrito"
// itemCount = 5 -> "Tienes 5 articulos en tu carrito"
```

---

## Cambiar Idioma

Cambia el idioma en runtime:

```dart
// Cambiar a español
Sint.updateLocale(Locale('es', 'ES'));

// Cambiar a ingles
Sint.updateLocale(Locale('en', 'US'));

// Cambiar a portugues
Sint.updateLocale(Locale('pt', 'BR'));
```

**Con boton de idioma:**

```dart
class LanguageSwitcher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton(
          onPressed: () => Sint.updateLocale(Locale('es', 'ES')),
          child: Text('Español'),
        ),
        ElevatedButton(
          onPressed: () => Sint.updateLocale(Locale('en', 'US')),
          child: Text('English'),
        ),
        ElevatedButton(
          onPressed: () => Sint.updateLocale(Locale('fr', 'FR')),
          child: Text('Français'),
        ),
      ],
    );
  }
}
```

**Obtener idioma actual:**

```dart
Locale currentLocale = Sint.locale!;
print('Idioma actual: ${currentLocale.languageCode}'); // "es"

// Comprobar idioma
if (Sint.locale?.languageCode == 'es') {
  print('App en español');
}
```

---

## Locale del Sistema

Detecta automaticamente el idioma del dispositivo:

```dart
SintMaterialApp(
  translations: AppTranslations(),
  locale: Sint.deviceLocale, // Usa el idioma del sistema
  fallbackLocale: Locale('en', 'US'),
)
```

**O detecta manualmente:**

```dart
void main() {
  final systemLocale = Sint.deviceLocale;
  print('Idioma del sistema: ${systemLocale?.languageCode}');

  runApp(MyApp());
}
```

**Seguir cambios del sistema:**

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SintMaterialApp(
      translations: AppTranslations(),
      locale: Sint.deviceLocale,
      fallbackLocale: Locale('en', 'US'),
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        // Verifica si el idioma del dispositivo esta soportado
        for (var locale in supportedLocales) {
          if (locale.languageCode == deviceLocale?.languageCode) {
            return deviceLocale;
          }
        }
        return Locale('en', 'US'); // Fallback
      },
    );
  }
}
```

---

## Traducciones por Modulo

Organiza traducciones por feature/modulo:

```dart
// lib/modules/auth/translations.dart
class AuthTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'es_ES': {
      'auth_login': 'Iniciar sesion',
      'auth_logout': 'Cerrar sesion',
      'auth_register': 'Registrarse',
    },
    'en_US': {
      'auth_login': 'Login',
      'auth_logout': 'Logout',
      'auth_register': 'Register',
    },
  };
}

// lib/modules/shop/translations.dart
class ShopTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'es_ES': {
      'shop_cart': 'Carrito',
      'shop_checkout': 'Finalizar compra',
      'shop_total': 'Total',
    },
    'en_US': {
      'shop_cart': 'Cart',
      'shop_checkout': 'Checkout',
      'shop_total': 'Total',
    },
  };
}

// Combinar todas
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'es_ES': {
      ...AuthTranslations().keys['es_ES']!,
      ...ShopTranslations().keys['es_ES']!,
      // Traducciones globales
      'app_name': 'Mi App',
      'app_version': 'Version 1.0.0',
    },
    'en_US': {
      ...AuthTranslations().keys['en_US']!,
      ...ShopTranslations().keys['en_US']!,
      'app_name': 'My App',
      'app_version': 'Version 1.0.0',
    },
  };
}
```

---

## Fallback

Define un idioma de respaldo cuando falta una traduccion:

```dart
SintMaterialApp(
  translations: AppTranslations(),
  locale: Locale('es', 'ES'),
  fallbackLocale: Locale('en', 'US'), // Si falta en español, usa ingles
)
```

**Cascada de fallback:**

1. Busca en el idioma actual (`es_ES`)
2. Si no existe, busca en `fallbackLocale` (`en_US`)
3. Si tampoco existe, devuelve la clave

```dart
// Traducciones
const Map<String, String> es_ES = {
  'hello': 'Hola',
  // 'new_feature' no existe en español
};

const Map<String, String> en_US = {
  'hello': 'Hello',
  'new_feature': 'New Feature',
};

// Con locale = es_ES
'hello'.tr        // "Hola" (encontrado en es_ES)
'new_feature'.tr  // "New Feature" (fallback a en_US)
'missing'.tr      // "missing" (no existe en ninguno)
```

---

## Best Practices

### 1. Organiza claves con prefijos

```dart
// BIEN - Claves organizadas
const Map<String, String> es_ES = {
  'home_title': 'Inicio',
  'home_subtitle': 'Bienvenido',

  'profile_title': 'Perfil',
  'profile_edit': 'Editar perfil',

  'settings_title': 'Configuracion',
  'settings_language': 'Idioma',
};

// MAL - Claves sin estructura
const Map<String, String> es_ES = {
  'title': 'Inicio', // Muy generico
  'edit': 'Editar', // Que se edita?
  'language': 'Idioma',
};
```

### 2. Usa archivos separados por idioma

```dart
// lib/translations/es_ES.dart
const Map<String, String> es_ES = { /* ... */ };

// lib/translations/en_US.dart
const Map<String, String> en_US = { /* ... */ };

// lib/translations/app_translations.dart
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'es_ES': es_ES,
    'en_US': en_US,
  };
}
```

### 3. Define constantes para claves

```dart
// lib/core/strings.dart
class Strings {
  static const homeTitle = 'home_title';
  static const btnSave = 'btn_save';
  static const msgSuccess = 'msg_success';
}

// Uso con autocomplete
Text(Strings.homeTitle.tr);
```

### 4. Usa trParams para contenido dinamico

```dart
// BIEN
'welcome_user'.trParams({'name': userName})

// MAL
'Bienvenido, $userName' // No es traducible
```

### 5. Implementa fallback siempre

```dart
SintMaterialApp(
  translations: AppTranslations(),
  locale: Locale('es', 'ES'),
  fallbackLocale: Locale('en', 'US'), // IMPORTANTE
)
```

---

## Test Roadmap

### Pruebas Planificadas - Pilar de Traduccion

1. **Carga Dinamica por Modulo**
   - Lazy loading de traducciones por feature
   - Tests de code splitting con deferred imports
   - Validacion de fallback cuando modulo no carga
   - Pruebas de cache de traducciones cargadas
   - Performance benchmarks de carga incremental

2. **Validacion de Claves .tr en Build-Time**
   - Analyzer plugin para detectar claves inexistentes
   - Tests de cobertura de traducciones (% traducido)
   - Validacion de parametros en trParams
   - Pruebas de keys duplicadas entre modulos
   - CI/CD integration para bloquear builds con traducciones faltantes

3. **Integracion RTL/LTR**
   - Soporte automatico para idiomas RTL (arabe, hebreo)
   - Tests de layout mirroring
   - Validacion de directionality per locale
   - Pruebas de transiciones RTL <-> LTR
   - Widgets RTL-aware automaticos

4. **Pluralizacion Avanzada**
   - Soporte para reglas de pluralizacion por idioma
   - Tests de plural forms (0, 1, 2, few, many)
   - Validacion de ICU Message Format
   - Pruebas de ordinal numbers (1st, 2nd, 3rd)
   - Gender-based pluralization

5. **Context-Aware Translations**
   - Traducciones que cambian segun contexto
   - Tests de formal vs informal
   - Validacion de genero en traducciones
   - Pruebas de variantes regionales (es_MX vs es_ES)
   - Context inheritance en nested translations

6. **Performance Optimization**
   - Benchmarks de .tr vs Intl package
   - Tests de memory footprint con muchos idiomas
   - Validacion de tree-shaking de traducciones no usadas
   - Pruebas de hot reload con cambios de locale
   - Profiling de trParams vs string interpolation

7. **Translation Tooling**
   - Generador de archivos de traduccion desde JSON/ARB
   - Tests de import/export con Lokalise, Crowdin
   - Validacion de merge de traducciones
   - Pruebas de diff entre versiones de traducciones
   - Integration con translation management platforms

8. **Fallback Strategies**
   - Tests de cascading fallback (es_MX -> es_ES -> en_US)
   - Validacion de partial translations
   - Pruebas de missing key reporting
   - Regional fallback automatico
   - Custom fallback logic per module
