# Manajemen Terjemahan

Sistem internasionalisasi SINT memudahkan aplikasi Anda untuk mendukung banyak bahasa dengan API yang sederhana dan powerful.

## Daftar Isi

- [Setup](#setup)
- [Menggunakan Translations](#menggunakan-translations)
- [Mengganti Locale](#mengganti-locale)
- [Translation dengan Parameters](#translation-dengan-parameters)
- [Pluralization](#pluralization)
- [Fallback Locale](#fallback-locale)
- [Best Practices](#best-practices)
- [Peta Pengujian](#peta-pengujian)

## Setup

### Membuat Translation Class

```dart
import 'package:sint/sint.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      'hello': 'Hello',
      'welcome': 'Welcome to SINT',
      'login': 'Login',
      'logout': 'Logout',
      'email': 'Email',
      'password': 'Password',
    },
    'id_ID': {
      'hello': 'Halo',
      'welcome': 'Selamat datang di SINT',
      'login': 'Masuk',
      'logout': 'Keluar',
      'email': 'Email',
      'password': 'Kata Sandi',
    },
    'es_ES': {
      'hello': 'Hola',
      'welcome': 'Bienvenido a SINT',
      'login': 'Iniciar sesión',
      'logout': 'Cerrar sesión',
      'email': 'Correo electrónico',
      'password': 'Contraseña',
    },
  };
}
```

### Konfigurasi SintMaterialApp

```dart
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SintMaterialApp(
      translations: AppTranslations(),
      locale: Locale('en', 'US'),
      fallbackLocale: Locale('en', 'US'),
      home: HomePage(),
    );
  }
}
```

## Menggunakan Translations

### Basic Usage

Gunakan extension `.tr` pada String key:

```dart
Text('hello'.tr)
// Output: 'Hello' (jika locale adalah en_US)
// Output: 'Halo' (jika locale adalah id_ID)
```

### Dalam Widget

```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('welcome'.tr),
      ),
      body: Column(
        children: [
          Text('hello'.tr),
          ElevatedButton(
            onPressed: () {},
            child: Text('login'.tr),
          ),
        ],
      ),
    );
  }
}
```

## Mengganti Locale

### Update Locale

```dart
// Ganti ke bahasa Indonesia
Sint.updateLocale(Locale('id', 'ID'));

// Ganti ke bahasa Spanyol
Sint.updateLocale(Locale('es', 'ES'));
```

### Locale Selector

```dart
class LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DropdownButton<Locale>(
      value: Sint.locale,
      items: [
        DropdownMenuItem(
          value: Locale('en', 'US'),
          child: Text('English'),
        ),
        DropdownMenuItem(
          value: Locale('id', 'ID'),
          child: Text('Bahasa Indonesia'),
        ),
        DropdownMenuItem(
          value: Locale('es', 'ES'),
          child: Text('Español'),
        ),
      ],
      onChanged: (locale) {
        if (locale != null) {
          Sint.updateLocale(locale);
        }
      },
    );
  }
}
```

### Menyimpan Locale Preference

```dart
class LanguageController extends SintController {
  var currentLocale = Locale('en', 'US').obs;

  @override
  void onInit() {
    super.onInit();
    loadSavedLocale();
  }

  void loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code');
    final countryCode = prefs.getString('country_code');

    if (languageCode != null && countryCode != null) {
      changeLocale(Locale(languageCode, countryCode));
    }
  }

  void changeLocale(Locale locale) async {
    currentLocale.value = locale;
    Sint.updateLocale(locale);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    await prefs.setString('country_code', locale.countryCode ?? '');
  }
}
```

## Translation dengan Parameters

### trParams

Gunakan `trParams` untuk menyisipkan parameter dinamis:

```dart
// Definisi keys
Map<String, Map<String, String>> get keys => {
  'en_US': {
    'greeting': 'Hello @name, welcome back!',
    'items_count': 'You have @count items',
    'user_info': '@name is @age years old',
  },
  'id_ID': {
    'greeting': 'Halo @name, selamat datang kembali!',
    'items_count': 'Anda memiliki @count item',
    'user_info': '@name berusia @age tahun',
  },
};

// Penggunaan
Text('greeting'.trParams({'name': 'John'}))
// Output: 'Hello John, welcome back!'

Text('items_count'.trParams({'count': '5'}))
// Output: 'You have 5 items'

Text('user_info'.trParams({
  'name': 'Alice',
  'age': '25',
}))
// Output: 'Alice is 25 years old'
```

### Multiple Parameters

```dart
// Keys
'order_summary': 'Order #@orderId for @amount on @date',

// Usage
Text('order_summary'.trParams({
  'orderId': '12345',
  'amount': '\$99.99',
  'date': '2024-01-15',
}))
// Output: 'Order #12345 for $99.99 on 2024-01-15'
```

## Pluralization

### trPlural

Gunakan `trPlural` untuk menangani bentuk tunggal dan jamak:

```dart
// Definisi keys
Map<String, Map<String, String>> get keys => {
  'en_US': {
    'item': 'item',
    'items': 'items',
    'person': 'person',
    'people': 'people',
  },
  'id_ID': {
    'item': 'item',
    'items': 'item', // Bahasa Indonesia tidak membedakan
    'person': 'orang',
    'people': 'orang',
  },
};

// Penggunaan
Text('item'.trPlural('items', 1))
// Output: '1 item'

Text('item'.trPlural('items', 5))
// Output: '5 items'

Text('person'.trPlural('people', 1))
// Output: '1 person'

Text('person'.trPlural('people', 10))
// Output: '10 people'
```

### Plural dengan Parameters

```dart
// Keys
'cart_summary': 'You have @count @item in your cart',

// Usage
String getCartSummary(int count) {
  return 'cart_summary'.trParams({
    'count': count.toString(),
    'item': 'item'.trPlural('items', count),
  });
}

print(getCartSummary(1)); // 'You have 1 item in your cart'
print(getCartSummary(5)); // 'You have 5 items in your cart'
```

## Fallback Locale

Jika translation tidak ditemukan untuk locale saat ini, SINT akan menggunakan fallback locale:

```dart
SintMaterialApp(
  translations: AppTranslations(),
  locale: Locale('fr', 'FR'), // Bahasa Prancis
  fallbackLocale: Locale('en', 'US'), // Fallback ke English
)
```

Jika key tidak ada di 'fr_FR', akan mencari di 'en_US'.

## Organisasi Translation

### Pemisahan berdasarkan Modul

```dart
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      ...AuthTranslations.en,
      ...HomeTranslations.en,
      ...ProfileTranslations.en,
    },
    'id_ID': {
      ...AuthTranslations.id,
      ...HomeTranslations.id,
      ...ProfileTranslations.id,
    },
  };
}

class AuthTranslations {
  static const en = {
    'auth_login': 'Login',
    'auth_register': 'Register',
    'auth_forgot_password': 'Forgot Password?',
  };

  static const id = {
    'auth_login': 'Masuk',
    'auth_register': 'Daftar',
    'auth_forgot_password': 'Lupa Kata Sandi?',
  };
}

class HomeTranslations {
  static const en = {
    'home_title': 'Home',
    'home_welcome': 'Welcome',
  };

  static const id = {
    'home_title': 'Beranda',
    'home_welcome': 'Selamat Datang',
  };
}
```

### Load dari File JSON

```dart
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': enUS,
    'id_ID': idID,
  };

  Map<String, String> enUS = {};
  Map<String, String> idID = {};

  Future<void> loadTranslations() async {
    final enJson = await rootBundle.loadString('assets/translations/en_US.json');
    final idJson = await rootBundle.loadString('assets/translations/id_ID.json');

    enUS = Map<String, String>.from(json.decode(enJson));
    idID = Map<String, String>.from(json.decode(idJson));
  }
}
```

## Best Practices

### 1. Gunakan Naming Convention yang Konsisten

```dart
// Baik - Hierarki yang jelas dengan prefix
'auth_login'
'auth_register'
'home_title'
'home_subtitle'
'profile_edit'
'profile_save'

// Buruk - Tidak konsisten
'login'
'registerButton'
'HomeTitle'
'edit_profile'
```

### 2. Hindari Hardcoded Strings

```dart
// Buruk
Text('Login')

// Baik
Text('auth_login'.tr)
```

### 3. Sediakan Translations Lengkap

```dart
// Buruk - Tidak semua bahasa memiliki key yang sama
'en_US': {
  'welcome': 'Welcome',
  'goodbye': 'Goodbye',
},
'id_ID': {
  'welcome': 'Selamat Datang',
  // 'goodbye' missing!
},

// Baik - Semua bahasa lengkap
'en_US': {
  'welcome': 'Welcome',
  'goodbye': 'Goodbye',
},
'id_ID': {
  'welcome': 'Selamat Datang',
  'goodbye': 'Sampai Jumpa',
},
```

### 4. Gunakan Context untuk Ambiguitas

```dart
// Untuk kata yang bisa memiliki arti berbeda
'button_close': 'Close', // Tombol close
'window_close': 'Close the window', // Aksi close window
'nearby_close': 'Close by', // Dekat dengan
```

### 5. Test Semua Locale

Pastikan UI tetap bagus untuk semua bahasa, terutama yang lebih panjang:

```dart
// Bahasa Jerman cenderung lebih panjang
'en_US': {
  'settings': 'Settings',
},
'de_DE': {
  'settings': 'Einstellungen',
},
```

## Peta Pengujian

### Unit Tests

```dart
test('Translation returns correct value', () {
  final translations = AppTranslations();

  expect(translations.keys['en_US']!['hello'], 'Hello');
  expect(translations.keys['id_ID']!['hello'], 'Halo');
});

test('trParams replaces parameters correctly', () {
  Sint.updateLocale(Locale('en', 'US'));

  final result = 'greeting'.trParams({'name': 'John'});

  expect(result, 'Hello John, welcome back!');
});

test('trPlural handles singular and plural', () {
  final singular = 'item'.trPlural('items', 1);
  final plural = 'item'.trPlural('items', 5);

  expect(singular, contains('1 item'));
  expect(plural, contains('5 items'));
});
```

### Widget Tests

```dart
testWidgets('Widget displays translated text', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(
      translations: AppTranslations(),
      locale: Locale('en', 'US'),
      home: Scaffold(
        body: Text('hello'.tr),
      ),
    ),
  );

  expect(find.text('Hello'), findsOneWidget);
});

testWidgets('Locale change updates UI', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(
      translations: AppTranslations(),
      locale: Locale('en', 'US'),
      home: Builder(
        builder: (context) {
          return Column(
            children: [
              Text('hello'.tr),
              ElevatedButton(
                onPressed: () {
                  Sint.updateLocale(Locale('id', 'ID'));
                },
                child: Text('Change Language'),
              ),
            ],
          );
        },
      ),
    ),
  );

  // Initial state
  expect(find.text('Hello'), findsOneWidget);

  // Change locale
  await tester.tap(find.text('Change Language'));
  await tester.pumpAndSettle();

  // Verify updated translation
  expect(find.text('Halo'), findsOneWidget);
  expect(find.text('Hello'), findsNothing);
});
```

### Integration Tests

```dart
testWidgets('Complete language switching flow', (tester) async {
  await tester.pumpWidget(MyApp());

  // Verify default language (English)
  expect(find.text('Welcome'), findsOneWidget);

  // Open language selector
  await tester.tap(find.byIcon(Icons.language));
  await tester.pumpAndSettle();

  // Select Indonesian
  await tester.tap(find.text('Bahasa Indonesia'));
  await tester.pumpAndSettle();

  // Verify language changed
  expect(find.text('Selamat Datang'), findsOneWidget);
  expect(find.text('Welcome'), findsNothing);

  // Navigate to another page
  await tester.tap(find.text('Profil'));
  await tester.pumpAndSettle();

  // Verify translation persists
  expect(find.text('Sunting Profil'), findsOneWidget);
});
```

### Locale Persistence Tests

```dart
testWidgets('Locale is saved and restored', (tester) async {
  final controller = LanguageController();
  Sint.put(controller);

  // Change locale
  controller.changeLocale(Locale('id', 'ID'));
  await tester.pumpAndSettle();

  // Simulate app restart
  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString('language_code');
  final savedCountry = prefs.getString('country_code');

  expect(savedLang, 'id');
  expect(savedCountry, 'ID');

  // Load saved locale
  controller.loadSavedLocale();
  await tester.pumpAndSettle();

  expect(controller.currentLocale.value.languageCode, 'id');
});
```

### Missing Translation Tests

```dart
test('Fallback locale is used when translation missing', () {
  Sint.updateLocale(Locale('fr', 'FR')); // French not defined

  final result = 'hello'.tr;

  // Should fallback to English
  expect(result, 'Hello');
});

test('Key is returned when translation not found', () {
  Sint.updateLocale(Locale('en', 'US'));

  final result = 'non_existent_key'.tr;

  expect(result, 'non_existent_key');
});
```

### Parameter Tests

```dart
test('Multiple parameters are replaced correctly', () {
  final result = 'user_info'.trParams({
    'name': 'Alice',
    'age': '25',
  });

  expect(result, contains('Alice'));
  expect(result, contains('25'));
});

test('Missing parameter shows placeholder', () {
  final result = 'greeting'.trParams({}); // No name parameter

  expect(result, contains('@name')); // Placeholder not replaced
});
```
