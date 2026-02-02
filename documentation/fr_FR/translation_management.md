# Gestion des Traductions

SINT fournit un système de traduction intégré et simple à utiliser pour internationaliser votre application Flutter.

## Table des matières

- [Configuration de Base](#configuration-de-base)
  - [Classe Translations](#classe-translations)
  - [Configuration de l'application](#configuration-de-lapplication)
- [Utilisation des Traductions](#utilisation-des-traductions)
  - [Traduction simple avec .tr](#traduction-simple-avec-tr)
  - [Traductions avec paramètres](#traductions-avec-paramètres)
  - [Traductions au pluriel](#traductions-au-pluriel)
- [Changement de Locale](#changement-de-locale)
  - [Changer la langue](#changer-la-langue)
  - [Obtenir la locale actuelle](#obtenir-la-locale-actuelle)
  - [Locale du système](#locale-du-système)
- [Organisation des Traductions](#organisation-des-traductions)
  - [Fichiers séparés](#fichiers-séparés)
  - [Chargement dynamique](#chargement-dynamique)
- [Cas d'Usage Avancés](#cas-dusage-avancés)
  - [Traductions imbriquées](#traductions-imbriquées)
  - [Fallback et locale par défaut](#fallback-et-locale-par-défaut)
- [Feuille de route des tests](#feuille-de-route-des-tests)

## Configuration de Base

### Classe Translations

Créez une classe qui étend `Translations` pour définir vos traductions:

```dart
import 'package:sint/sint.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'fr_FR': {
      'hello': 'Bonjour',
      'welcome': 'Bienvenue',
      'goodbye': 'Au revoir',
      'app_title': 'Mon Application',
    },
    'en_US': {
      'hello': 'Hello',
      'welcome': 'Welcome',
      'goodbye': 'Goodbye',
      'app_title': 'My Application',
    },
    'es_ES': {
      'hello': 'Hola',
      'welcome': 'Bienvenido',
      'goodbye': 'Adiós',
      'app_title': 'Mi Aplicación',
    },
  };
}
```

### Configuration de l'application

```dart
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SintMaterialApp(
      title: 'SINT i18n',
      translations: AppTranslations(),
      locale: Locale('fr', 'FR'), // Langue par défaut
      fallbackLocale: Locale('en', 'US'), // Langue de secours
      home: HomePage(),
    );
  }
}
```

## Utilisation des Traductions

### Traduction simple avec .tr

Utilisez l'extension `.tr` sur les clés de traduction:

```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app_title'.tr),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('hello'.tr, style: TextStyle(fontSize: 32)),
            SizedBox(height: 16),
            Text('welcome'.tr, style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}
```

**Dans les contrôleurs**:

```dart
class HomeController extends SintController {
  void showGreeting() {
    Sint.snackbar(
      'hello'.tr,
      'welcome'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  String getTitle() {
    return 'app_title'.tr;
  }
}
```

### Traductions avec paramètres

Utilisez `trParams` pour injecter des valeurs dynamiques:

```dart
// Définition des traductions
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'fr_FR': {
      'welcome_user': 'Bienvenue @name',
      'items_in_cart': 'Vous avez @count articles dans votre panier',
      'user_info': 'Bonjour @name, vous avez @age ans',
      'notification': '@user a commenté votre publication à @time',
    },
    'en_US': {
      'welcome_user': 'Welcome @name',
      'items_in_cart': 'You have @count items in your cart',
      'user_info': 'Hello @name, you are @age years old',
      'notification': '@user commented on your post at @time',
    },
  };
}

// Utilisation
Text('welcome_user'.trParams({'name': 'Marie'}))
// Résultat FR: "Bienvenue Marie"

Text('items_in_cart'.trParams({'count': '5'}))
// Résultat FR: "Vous avez 5 articles dans votre panier"

Text('user_info'.trParams({
  'name': 'Jean',
  'age': '25',
}))
// Résultat FR: "Bonjour Jean, vous avez 25 ans"

Text('notification'.trParams({
  'user': 'Sophie',
  'time': '14:30',
}))
// Résultat FR: "Sophie a commenté votre publication à 14:30"
```

**Dans un contrôleur avec données dynamiques**:

```dart
class ProfileController extends SintController {
  var user = User(name: 'Alice', age: 28).obs;

  String getUserInfo() {
    return 'user_info'.trParams({
      'name': user.value.name,
      'age': user.value.age.toString(),
    });
  }

  void showWelcomeMessage() {
    Sint.snackbar(
      'Notification',
      'welcome_user'.trParams({'name': user.value.name}),
    );
  }
}

class User {
  final String name;
  final int age;

  User({required this.name, required this.age});
}
```

### Traductions au pluriel

Utilisez `trPlural` pour gérer les formes singulier/pluriel:

```dart
// Définition des traductions
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'fr_FR': {
      'item': 'article',
      'items': 'articles',
      'message': 'message',
      'messages': 'messages',
      'notification': 'notification',
      'notifications': 'notifications',
    },
    'en_US': {
      'item': 'item',
      'items': 'items',
      'message': 'message',
      'messages': 'messages',
      'notification': 'notification',
      'notifications': 'notifications',
    },
  };
}

// Utilisation
Text('item'.trPlural('items', 1))  // "article" (FR) / "item" (EN)
Text('item'.trPlural('items', 5))  // "articles" (FR) / "items" (EN)

Text('message'.trPlural('messages', 0))  // "messages"
Text('message'.trPlural('messages', 1))  // "message"
Text('message'.trPlural('messages', 10)) // "messages"
```

**Combinaison avec trParams**:

```dart
// Traductions
'fr_FR': {
  'cart_item_count': 'Vous avez @count article',
  'cart_items_count': 'Vous avez @count articles',
},
'en_US': {
  'cart_item_count': 'You have @count item',
  'cart_items_count': 'You have @count items',
}

// Utilisation
class CartController extends SintController {
  var itemCount = 0.obs;

  String getCartMessage() {
    return 'cart_item_count'.trPlural(
      'cart_items_count',
      itemCount.value,
    ).replaceAll('@count', itemCount.value.toString());
  }
}

// Ou créer une extension personnalisée
extension PluralParamsExtension on String {
  String trPluralParams(String pluralKey, int count, Map<String, String> params) {
    return trPlural(pluralKey, count).trParams(params);
  }
}

// Utilisation simplifiée
'cart_item_count'.trPluralParams(
  'cart_items_count',
  5,
  {'count': '5'},
)
```

## Changement de Locale

### Changer la langue

```dart
class LanguageController extends SintController {
  var currentLocale = Locale('fr', 'FR').obs;

  void changeLanguage(String languageCode, String countryCode) {
    var locale = Locale(languageCode, countryCode);
    currentLocale.value = locale;
    Sint.updateLocale(locale);
  }

  void setFrench() => changeLanguage('fr', 'FR');
  void setEnglish() => changeLanguage('en', 'US');
  void setSpanish() => changeLanguage('es', 'ES');
}

// Dans l'interface
class SettingsPage extends StatelessWidget {
  final controller = Sint.find<LanguageController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr)),
      body: ListView(
        children: [
          ListTile(
            title: Text('Français'),
            leading: Icon(Icons.language),
            onTap: controller.setFrench,
            trailing: Obx(() =>
              controller.currentLocale.value.languageCode == 'fr'
                ? Icon(Icons.check, color: Colors.green)
                : null
            ),
          ),
          ListTile(
            title: Text('English'),
            leading: Icon(Icons.language),
            onTap: controller.setEnglish,
            trailing: Obx(() =>
              controller.currentLocale.value.languageCode == 'en'
                ? Icon(Icons.check, color: Colors.green)
                : null
            ),
          ),
          ListTile(
            title: Text('Español'),
            leading: Icon(Icons.language),
            onTap: controller.setSpanish,
            trailing: Obx(() =>
              controller.currentLocale.value.languageCode == 'es'
                ? Icon(Icons.check, color: Colors.green)
                : null
            ),
          ),
        ],
      ),
    );
  }
}
```

### Obtenir la locale actuelle

```dart
// Obtenir la locale actuelle
Locale currentLocale = Sint.locale ?? Locale('en', 'US');

print('Langue: ${currentLocale.languageCode}');
print('Pays: ${currentLocale.countryCode}');

// Vérifier la locale
if (Sint.locale?.languageCode == 'fr') {
  print('Application en français');
}
```

### Locale du système

```dart
class LanguageController extends SintController {
  @override
  void onInit() {
    super.onInit();
    // Utiliser la langue du système
    useSystemLanguage();
  }

  void useSystemLanguage() {
    var systemLocale = Sint.deviceLocale;

    if (systemLocale != null) {
      // Vérifier si la langue est supportée
      if (isLanguageSupported(systemLocale.languageCode)) {
        Sint.updateLocale(systemLocale);
      } else {
        // Utiliser la langue de fallback
        Sint.updateLocale(Locale('en', 'US'));
      }
    }
  }

  bool isLanguageSupported(String languageCode) {
    return ['fr', 'en', 'es'].contains(languageCode);
  }
}

// Obtenir la locale du device
Locale? deviceLocale = Sint.deviceLocale;
print('Langue du système: ${deviceLocale?.languageCode}');
```

## Organisation des Traductions

### Fichiers séparés

Pour de grandes applications, organisez vos traductions dans des fichiers séparés:

```dart
// translations/fr_fr.dart
class FrFR {
  static const Map<String, String> translations = {
    // Commun
    'app_title': 'Mon Application',
    'loading': 'Chargement...',
    'error': 'Erreur',
    'success': 'Succès',

    // Authentification
    'login': 'Connexion',
    'logout': 'Déconnexion',
    'email': 'Email',
    'password': 'Mot de passe',
    'forgot_password': 'Mot de passe oublié?',

    // Profil
    'profile': 'Profil',
    'edit_profile': 'Modifier le profil',
    'settings': 'Paramètres',

    // Messages
    'welcome_message': 'Bienvenue dans l\'application',
    'logout_confirmation': 'Voulez-vous vraiment vous déconnecter?',
  };
}

// translations/en_us.dart
class EnUS {
  static const Map<String, String> translations = {
    // Common
    'app_title': 'My Application',
    'loading': 'Loading...',
    'error': 'Error',
    'success': 'Success',

    // Authentication
    'login': 'Login',
    'logout': 'Logout',
    'email': 'Email',
    'password': 'Password',
    'forgot_password': 'Forgot password?',

    // Profile
    'profile': 'Profile',
    'edit_profile': 'Edit profile',
    'settings': 'Settings',

    // Messages
    'welcome_message': 'Welcome to the application',
    'logout_confirmation': 'Do you really want to logout?',
  };
}

// translations/app_translations.dart
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'fr_FR': FrFR.translations,
    'en_US': EnUS.translations,
    'es_ES': EsES.translations,
  };
}
```

**Organisation par modules**:

```dart
// translations/modules/auth_translations.dart
class AuthTranslations {
  static const Map<String, Map<String, String>> keys = {
    'fr_FR': {
      'auth.login': 'Connexion',
      'auth.register': 'Inscription',
      'auth.email': 'Email',
      'auth.password': 'Mot de passe',
    },
    'en_US': {
      'auth.login': 'Login',
      'auth.register': 'Register',
      'auth.email': 'Email',
      'auth.password': 'Password',
    },
  };
}

// translations/modules/profile_translations.dart
class ProfileTranslations {
  static const Map<String, Map<String, String>> keys = {
    'fr_FR': {
      'profile.title': 'Profil',
      'profile.edit': 'Modifier',
      'profile.save': 'Enregistrer',
    },
    'en_US': {
      'profile.title': 'Profile',
      'profile.edit': 'Edit',
      'profile.save': 'Save',
    },
  };
}

// translations/app_translations.dart
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys {
    final allTranslations = <String, Map<String, String>>{};

    // Fusionner toutes les traductions
    for (var locale in ['fr_FR', 'en_US']) {
      allTranslations[locale] = {
        ...?AuthTranslations.keys[locale],
        ...?ProfileTranslations.keys[locale],
        ...?CommonTranslations.keys[locale],
      };
    }

    return allTranslations;
  }
}

// Utilisation
Text('auth.login'.tr)
Text('profile.title'.tr)
```

### Chargement dynamique

Pour charger les traductions depuis une API ou un fichier:

```dart
class DynamicTranslations extends Translations {
  final Map<String, Map<String, String>> _translations = {};

  @override
  Map<String, Map<String, String>> get keys => _translations;

  Future<void> loadTranslations() async {
    try {
      // Charger depuis une API
      final response = await http.get(
        Uri.parse('https://api.example.com/translations'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _translations.addAll(data);
      }
    } catch (e) {
      print('Erreur lors du chargement des traductions: $e');
      // Utiliser les traductions par défaut
      _loadDefaultTranslations();
    }
  }

  void _loadDefaultTranslations() {
    _translations['fr_FR'] = FrFR.translations;
    _translations['en_US'] = EnUS.translations;
  }
}

// Initialisation
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final translations = DynamicTranslations();
  await translations.loadTranslations();

  runApp(
    SintMaterialApp(
      translations: translations,
      locale: Locale('fr', 'FR'),
      home: HomePage(),
    ),
  );
}
```

## Cas d'Usage Avancés

### Traductions imbriquées

```dart
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'fr_FR': {
      // Erreurs
      'error.network': 'Erreur réseau',
      'error.auth': 'Erreur d\'authentification',
      'error.validation': 'Erreur de validation',

      // Succès
      'success.saved': 'Enregistré avec succès',
      'success.deleted': 'Supprimé avec succès',

      // Formulaires
      'form.required': 'Ce champ est requis',
      'form.invalid_email': 'Email invalide',
      'form.password_too_short': 'Mot de passe trop court',
    },
    'en_US': {
      'error.network': 'Network error',
      'error.auth': 'Authentication error',
      'error.validation': 'Validation error',

      'success.saved': 'Successfully saved',
      'success.deleted': 'Successfully deleted',

      'form.required': 'This field is required',
      'form.invalid_email': 'Invalid email',
      'form.password_too_short': 'Password too short',
    },
  };
}

// Utilisation
Text('error.network'.tr)
Text('form.required'.tr)
```

### Fallback et locale par défaut

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SintMaterialApp(
      translations: AppTranslations(),

      // Locale par défaut
      locale: Locale('fr', 'FR'),

      // Utilisé si une traduction n'existe pas dans la locale actuelle
      fallbackLocale: Locale('en', 'US'),

      home: HomePage(),
    );
  }
}

// Si une clé n'existe pas en français, la version anglaise sera utilisée
// Si elle n'existe pas non plus en anglais, la clé elle-même sera affichée
```

**Gestion des clés manquantes**:

```dart
extension SafeTranslation on String {
  String get trSafe {
    try {
      return tr;
    } catch (e) {
      // Log l'erreur
      print('Traduction manquante pour: $this');
      // Retourner la clé ou une valeur par défaut
      return this;
    }
  }

  String trWithDefault(String defaultValue) {
    try {
      final translation = tr;
      return translation == this ? defaultValue : translation;
    } catch (e) {
      return defaultValue;
    }
  }
}

// Utilisation
Text('some.missing.key'.trSafe)
Text('another.key'.trWithDefault('Valeur par défaut'))
```

## Feuille de route des tests

### Tests Unitaires des Traductions

**Test de traductions de base**:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

void main() {
  group('AppTranslations Tests', () {
    setUp(() {
      Sint.testMode = true;
    });

    test('Les traductions doivent contenir toutes les locales', () {
      final translations = AppTranslations();

      expect(translations.keys.containsKey('fr_FR'), true);
      expect(translations.keys.containsKey('en_US'), true);
    });

    test('Les clés doivent être cohérentes entre les locales', () {
      final translations = AppTranslations();
      final frKeys = translations.keys['fr_FR']!.keys;
      final enKeys = translations.keys['en_US']!.keys;

      // Vérifier que toutes les clés FR existent en EN
      for (var key in frKeys) {
        expect(enKeys.contains(key), true,
          reason: 'Clé manquante en EN: $key');
      }

      // Vérifier que toutes les clés EN existent en FR
      for (var key in enKeys) {
        expect(frKeys.contains(key), true,
          reason: 'Clé manquante en FR: $key');
      }
    });

    test('Aucune traduction ne doit être vide', () {
      final translations = AppTranslations();

      translations.keys.forEach((locale, keys) {
        keys.forEach((key, value) {
          expect(value.isNotEmpty, true,
            reason: 'Traduction vide pour $locale.$key');
        });
      });
    });
  });
}
```

### Tests de Widget avec Traductions

```dart
testWidgets('Widget doit afficher la traduction correcte', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(
      translations: AppTranslations(),
      locale: Locale('fr', 'FR'),
      home: Scaffold(
        body: Text('hello'.tr),
      ),
    ),
  );

  expect(find.text('Bonjour'), findsOneWidget);
});

testWidgets('Changement de locale doit mettre à jour les traductions', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(
      translations: AppTranslations(),
      locale: Locale('fr', 'FR'),
      home: HomePage(),
    ),
  );

  // Vérifier la traduction en français
  expect(find.text('Bonjour'), findsOneWidget);

  // Changer la locale
  Sint.updateLocale(Locale('en', 'US'));
  await tester.pumpAndSettle();

  // Vérifier la traduction en anglais
  expect(find.text('Hello'), findsOneWidget);
  expect(find.text('Bonjour'), findsNothing);
});
```

### Tests de trParams

```dart
test('trParams doit remplacer les paramètres', () {
  Sint.testMode = true;

  final translations = AppTranslations();
  Sint.addTranslations(translations.keys);
  Sint.locale = Locale('fr', 'FR');

  final result = 'welcome_user'.trParams({'name': 'Alice'});

  expect(result, 'Bienvenue Alice');
});

test('trParams avec plusieurs paramètres', () {
  Sint.testMode = true;

  final translations = AppTranslations();
  Sint.addTranslations(translations.keys);
  Sint.locale = Locale('fr', 'FR');

  final result = 'user_info'.trParams({
    'name': 'Bob',
    'age': '30',
  });

  expect(result, 'Bonjour Bob, vous avez 30 ans');
});
```

### Tests de trPlural

```dart
test('trPlural doit utiliser le singulier pour 1', () {
  Sint.testMode = true;

  final translations = AppTranslations();
  Sint.addTranslations(translations.keys);
  Sint.locale = Locale('fr', 'FR');

  final result = 'item'.trPlural('items', 1);

  expect(result, 'article');
});

test('trPlural doit utiliser le pluriel pour > 1', () {
  Sint.testMode = true;

  final translations = AppTranslations();
  Sint.addTranslations(translations.keys);
  Sint.locale = Locale('fr', 'FR');

  final result = 'item'.trPlural('items', 5);

  expect(result, 'articles');
});

test('trPlural doit utiliser le pluriel pour 0', () {
  Sint.testMode = true;

  final translations = AppTranslations();
  Sint.addTranslations(translations.keys);
  Sint.locale = Locale('fr', 'FR');

  final result = 'item'.trPlural('items', 0);

  expect(result, 'articles');
});
```

### Tests de Changement de Locale

```dart
testWidgets('updateLocale doit changer la langue', (tester) async {
  final controller = LanguageController();
  Sint.put(controller);

  await tester.pumpWidget(
    SintMaterialApp(
      translations: AppTranslations(),
      locale: Locale('fr', 'FR'),
      home: Obx(() => Text('hello'.tr)),
    ),
  );

  expect(find.text('Bonjour'), findsOneWidget);

  controller.setEnglish();
  await tester.pumpAndSettle();

  expect(find.text('Hello'), findsOneWidget);
  expect(find.text('Bonjour'), findsNothing);
});

test('deviceLocale doit retourner la locale du système', () {
  final deviceLocale = Sint.deviceLocale;

  expect(deviceLocale, isNotNull);
  expect(deviceLocale?.languageCode, isNotEmpty);
});
```

### Bonnes Pratiques de Test

1. **Vérifier la cohérence des traductions**:
```dart
test('Toutes les locales doivent avoir les mêmes clés', () {
  final translations = AppTranslations();
  final locales = translations.keys.keys.toList();

  if (locales.length > 1) {
    final firstLocaleKeys = translations.keys[locales[0]]!.keys.toSet();

    for (var i = 1; i < locales.length; i++) {
      final currentKeys = translations.keys[locales[i]]!.keys.toSet();

      expect(
        firstLocaleKeys.difference(currentKeys).isEmpty,
        true,
        reason: 'Clés manquantes dans ${locales[i]}',
      );
    }
  }
});
```

2. **Tester le fallback**:
```dart
testWidgets('Fallback locale doit être utilisé si la clé manque', (tester) async {
  final incompleteTranslations = {
    'fr_FR': {'hello': 'Bonjour'},
    'en_US': {'hello': 'Hello', 'goodbye': 'Goodbye'},
  };

  await tester.pumpWidget(
    SintMaterialApp(
      translations: TestTranslations(incompleteTranslations),
      locale: Locale('fr', 'FR'),
      fallbackLocale: Locale('en', 'US'),
      home: Text('goodbye'.tr),
    ),
  );

  // Doit utiliser la version anglaise car elle n'existe pas en français
  expect(find.text('Goodbye'), findsOneWidget);
});
```

3. **Tester les traductions manquantes**:
```dart
test('Clé manquante doit retourner la clé elle-même', () {
  Sint.testMode = true;
  Sint.locale = Locale('fr', 'FR');

  final result = 'nonexistent.key'.tr;

  expect(result, 'nonexistent.key');
});
```

4. **Mock pour les tests**:
```dart
class TestTranslations extends Translations {
  final Map<String, Map<String, String>> _keys;

  TestTranslations(this._keys);

  @override
  Map<String, Map<String, String>> get keys => _keys;
}

// Utilisation dans les tests
testWidgets('Test avec traductions mockées', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(
      translations: TestTranslations({
        'fr_FR': {'test_key': 'Valeur de test'},
      }),
      locale: Locale('fr', 'FR'),
      home: Text('test_key'.tr),
    ),
  );

  expect(find.text('Valeur de test'), findsOneWidget);
});
```
