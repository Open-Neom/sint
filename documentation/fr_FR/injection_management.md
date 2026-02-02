# Gestion de l'Injection

SINT fournit un système d'injection de dépendances puissant et flexible qui gère automatiquement le cycle de vie de vos instances.

## Table des matières

- [Injection de Base](#injection-de-base)
  - [Sint.put](#sintput)
  - [Sint.lazyPut](#sintlazyput)
  - [Sint.putAsync](#sintputasync)
  - [Sint.create](#sintcreate)
- [Récupération d'Instances](#récupération-dinstances)
  - [Sint.find](#sintfind)
  - [Recherche avec tag](#recherche-avec-tag)
- [Bindings](#bindings)
  - [Création de Bindings](#création-de-bindings)
  - [Utilisation avec les routes](#utilisation-avec-les-routes)
- [SmartManagement](#smartmanagement)
  - [Modes de gestion](#modes-de-gestion)
  - [Configuration](#configuration)
- [Gestion du Cycle de Vie](#gestion-du-cycle-de-vie)
- [Feuille de route des tests](#feuille-de-route-des-tests)

## Injection de Base

SINT propose plusieurs méthodes pour injecter des dépendances selon vos besoins.

### Sint.put

Instancie et enregistre immédiatement une dépendance:

```dart
class ApiController extends SintController {
  void fetchData() {
    print('Récupération des données...');
  }
}

// Injection simple
final controller = Sint.put(ApiController());

// Utilisation immédiate
controller.fetchData();
```

**Avec paramètre permanent**:

```dart
// Instance permanente - ne sera jamais supprimée automatiquement
Sint.put(CacheManager(), permanent: true);

// Instance normale - peut être supprimée
Sint.put(TemporaryController());
```

**Avec tag pour plusieurs instances**:

```dart
// Plusieurs instances du même type
Sint.put(ProfileController(), tag: 'user-profile');
Sint.put(ProfileController(), tag: 'admin-profile');

// Récupération
final userProfile = Sint.find<ProfileController>(tag: 'user-profile');
final adminProfile = Sint.find<ProfileController>(tag: 'admin-profile');
```

### Sint.lazyPut

Enregistre une dépendance qui ne sera instanciée que lors du premier usage:

```dart
// L'instance n'est pas créée immédiatement
Sint.lazyPut(() => HeavyController());

// Plus tard dans le code...
// L'instance est créée maintenant lors du premier find
final controller = Sint.find<HeavyController>();
```

**Avantages de lazyPut**:
- Améliore les performances de démarrage
- Réduit l'utilisation mémoire initiale
- Idéal pour les dépendances rarement utilisées

```dart
class HeavyController extends SintController {
  HeavyController() {
    print('HeavyController créé');
    // Opérations coûteuses
    loadLargeDataset();
  }

  void loadLargeDataset() {
    // Chargement de données volumineuses
  }
}

// Configuration au démarrage
void setupDependencies() {
  // Ces contrôleurs ne sont pas encore créés
  Sint.lazyPut(() => HeavyController());
  Sint.lazyPut(() => DatabaseController());
  Sint.lazyPut(() => AnalyticsController());
}
```

**Mode fenix (réactivation automatique)**:

```dart
// L'instance sera recréée si elle est supprimée puis redemandée
Sint.lazyPut(() => CacheController(), fenix: true);

// Utilisation
var cache = Sint.find<CacheController>(); // Créée
Sint.delete<CacheController>(); // Supprimée
cache = Sint.find<CacheController>(); // Recréée automatiquement
```

### Sint.putAsync

Pour les dépendances nécessitant une initialisation asynchrone:

```dart
class DatabaseController extends SintController {
  late Database db;

  Future<DatabaseController> init() async {
    db = await openDatabase('app.db');
    print('Base de données initialisée');
    return this;
  }

  Future<List<User>> getUsers() async {
    return await db.query('users');
  }
}

// Injection asynchrone
Future<void> initApp() async {
  await Sint.putAsync(() async {
    final controller = DatabaseController();
    await controller.init();
    return controller;
  });

  // La base de données est prête
  final db = Sint.find<DatabaseController>();
  final users = await db.getUsers();
}
```

**Exemple avec API et authentification**:

```dart
class AuthController extends SintController {
  late String token;
  late User currentUser;

  Future<AuthController> init() async {
    // Récupérer le token sauvegardé
    token = await SecureStorage.read('auth_token') ?? '';

    if (token.isNotEmpty) {
      // Vérifier le token et charger l'utilisateur
      currentUser = await ApiService.getCurrentUser(token);
    }

    return this;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser l'authentification avant de démarrer l'app
  await Sint.putAsync(() async {
    final auth = AuthController();
    await auth.init();
    return auth;
  });

  runApp(MyApp());
}
```

### Sint.create

Crée une nouvelle instance à chaque appel de `Sint.find`:

```dart
class FormController extends SintController {
  var formData = {}.obs;

  void updateField(String key, String value) {
    formData[key] = value;
  }

  @override
  void onClose() {
    formData.clear();
    super.onClose();
  }
}

// Enregistre une factory
Sint.create(() => FormController());

// Chaque page obtient sa propre instance
class Page1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Sint.find<FormController>(); // Instance A
    return FormWidget();
  }
}

class Page2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Sint.find<FormController>(); // Instance B (différente)
    return FormWidget();
  }
}
```

**Cas d'usage typiques pour create**:
- Formulaires multiples
- Éléments de liste avec leur propre état
- Dialogues et modals indépendants

```dart
class ListItemController extends SintController {
  final String itemId;
  var isExpanded = false.obs;

  ListItemController(this.itemId);

  void toggle() {
    isExpanded.toggle();
  }
}

// Configuration
Sint.create(() => ListItemController(''));

// Dans une ListView
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    // Chaque élément a son propre contrôleur
    final controller = Sint.find<ListItemController>();
    return ListItemWidget(controller: controller);
  },
);
```

## Récupération d'Instances

### Sint.find

Récupère une instance précédemment enregistrée:

```dart
// Récupération basique
final controller = Sint.find<ApiController>();

// Utilisation
controller.fetchData();
```

**Vérification de l'existence**:

```dart
// Vérifie si une instance existe
if (Sint.isRegistered<ApiController>()) {
  final controller = Sint.find<ApiController>();
  controller.fetchData();
} else {
  print('ApiController non enregistré');
}
```

### Recherche avec tag

Pour récupérer des instances avec des tags spécifiques:

```dart
// Enregistrement avec tags
Sint.put(ThemeController(), tag: 'light');
Sint.put(ThemeController(), tag: 'dark');

// Récupération
final lightTheme = Sint.find<ThemeController>(tag: 'light');
final darkTheme = Sint.find<ThemeController>(tag: 'dark');
```

## Bindings

Les Bindings permettent de grouper et d'organiser vos dépendances par fonctionnalité.

### Création de Bindings

```dart
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Injection de toutes les dépendances pour Home
    Sint.lazyPut(() => HomeController());
    Sint.lazyPut(() => ProductController());
    Sint.lazyPut(() => CartController());
  }
}

class HomeController extends SintController {
  void loadHome() {
    print('Chargement de la page d\'accueil');
  }

  @override
  void onInit() {
    super.onInit();
    loadHome();
  }
}

class ProductController extends SintController {
  var products = <Product>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  void fetchProducts() async {
    // Logique de récupération
    products.value = await ApiService.getProducts();
  }
}
```

### Utilisation avec les routes

```dart
void main() {
  runApp(
    SintMaterialApp(
      initialRoute: '/home',
      getPages: [
        GetPage(
          name: '/home',
          page: () => HomePage(),
          binding: HomeBinding(), // Injection automatique
        ),
        GetPage(
          name: '/profile',
          page: () => ProfilePage(),
          binding: ProfileBinding(),
        ),
        GetPage(
          name: '/settings',
          page: () => SettingsPage(),
          bindings: [
            // Plusieurs bindings
            SettingsBinding(),
            ThemeBinding(),
            LocaleBinding(),
          ],
        ),
      ],
    ),
  );
}
```

**BindingsBuilder pour configuration rapide**:

```dart
GetPage(
  name: '/product/:id',
  page: () => ProductDetailPage(),
  binding: BindingsBuilder(() {
    Sint.lazyPut(() => ProductDetailController());
    Sint.lazyPut(() => ReviewController());
    Sint.lazyPut(() => RelatedProductsController());
  }),
)
```

**Binding initial pour l'application**:

```dart
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Services globaux disponibles partout
    Sint.put(AuthService(), permanent: true);
    Sint.put(StorageService(), permanent: true);
    Sint.put(NetworkService(), permanent: true);
    Sint.put(LoggingService(), permanent: true);
  }
}

void main() {
  runApp(
    SintMaterialApp(
      initialBinding: InitialBinding(),
      home: SplashPage(),
    ),
  );
}
```

## SmartManagement

SmartManagement contrôle le cycle de vie automatique des instances.

### Modes de gestion

```dart
enum SmartManagement {
  // Garde les instances en mémoire
  // Ne supprime rien automatiquement
  full,

  // Supprime les contrôleurs non utilisés quand la route est fermée
  // Recommandé pour la plupart des apps
  onlyBuilder,

  // Supprime uniquement ce qui n'a pas été défini avec permanent: true
  keepFactory,
}
```

### Configuration

**Configuration globale**:

```dart
void main() {
  runApp(
    SintMaterialApp(
      smartManagement: SmartManagement.keepFactory,
      home: HomePage(),
    ),
  );
}
```

**Configuration par injection**:

```dart
// Cette instance ne sera jamais supprimée automatiquement
Sint.put(
  GlobalController(),
  permanent: true,
);

// Supprimée quand elle n'est plus utilisée
Sint.put(
  TemporaryController(),
  permanent: false,
);
```

**Exemples de stratégies**:

```dart
// Service global permanent
class AuthService extends SintController {
  // SintController ne se supprime jamais automatiquement
}

Sint.put(AuthService());

// Contrôleur de page temporaire
class PageController extends SintController {
  // Sera supprimé quand la page est fermée
}

Sint.lazyPut(() => PageController());

// Instance avec durée de vie personnalisée
class CacheController extends SintController {
  Timer? _cleanupTimer;

  @override
  void onInit() {
    super.onInit();

    // Auto-destruction après 5 minutes d'inactivité
    _cleanupTimer = Timer(Duration(minutes: 5), () {
      Sint.delete<CacheController>();
    });
  }

  @override
  void onClose() {
    _cleanupTimer?.cancel();
    super.onClose();
  }
}
```

## Gestion du Cycle de Vie

### Suppression manuelle

```dart
// Supprimer une instance spécifique
Sint.delete<HomeController>();

// Supprimer avec tag
Sint.delete<ProfileController>(tag: 'user-profile');

// Vider toutes les instances (attention!)
Sint.reset();

// Vider les instances temporaires uniquement
Sint.resetAllExceptPermanent();
```

### SintController pour services permanents

```dart
class LocalStorageService extends SintController {
  late SharedPreferences _prefs;

  Future<LocalStorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  String? getString(String key) => _prefs.getString(key);

  Future<bool> setString(String key, String value) {
    return _prefs.setString(key, value);
  }
}

// Injection permanente
Future<void> initServices() async {
  await Sint.putAsync(() async {
    final service = LocalStorageService();
    await service.init();
    return service;
  });
}
```

**Service avec dépendances**:

```dart
class ApiService extends SintController {
  final AuthService _auth;
  final LoggingService _logger;

  ApiService(this._auth, this._logger);

  Future<Response> get(String endpoint) async {
    _logger.log('GET $endpoint');
    final token = _auth.token;

    return await http.get(
      Uri.parse(endpoint),
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}

// Injection avec dépendances
Sint.put(
  ApiService(
    Sint.find<AuthService>(),
    Sint.find<LoggingService>(),
  ),
);
```

## Feuille de route des tests

### Tests Unitaires pour l'Injection

**Test d'injection de base**:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

void main() {
  tearDown(() {
    // Nettoyer après chaque test
    Sint.reset();
  });

  group('Sint.put Tests', () {
    test('put doit enregistrer et permettre la récupération', () {
      final controller = Sint.put(ApiController());

      expect(Sint.isRegistered<ApiController>(), true);
      expect(Sint.find<ApiController>(), controller);
    });

    test('put avec tag doit gérer plusieurs instances', () {
      Sint.put(ThemeController(), tag: 'light');
      Sint.put(ThemeController(), tag: 'dark');

      final light = Sint.find<ThemeController>(tag: 'light');
      final dark = Sint.find<ThemeController>(tag: 'dark');

      expect(light, isNot(dark));
    });

    test('put permanent doit persister après reset', () {
      Sint.put(CacheManager(), permanent: true);
      Sint.put(TempController());

      Sint.resetAllExceptPermanent();

      expect(Sint.isRegistered<CacheManager>(), true);
      expect(Sint.isRegistered<TempController>(), false);
    });
  });

  group('Sint.lazyPut Tests', () {
    test('lazyPut ne doit pas instancier immédiatement', () {
      var instanceCreated = false;

      Sint.lazyPut(() {
        instanceCreated = true;
        return TestController();
      });

      expect(instanceCreated, false);

      Sint.find<TestController>();
      expect(instanceCreated, true);
    });

    test('lazyPut fenix doit recréer après suppression', () {
      Sint.lazyPut(() => TestController(), fenix: true);

      final first = Sint.find<TestController>();
      Sint.delete<TestController>();
      final second = Sint.find<TestController>();

      expect(first, isNot(second));
    });
  });

  group('Sint.create Tests', () {
    test('create doit retourner une nouvelle instance à chaque fois', () {
      Sint.create(() => FormController());

      final instance1 = Sint.find<FormController>();
      final instance2 = Sint.find<FormController>();

      expect(instance1, isNot(instance2));
    });
  });
}

class TestController extends SintController {}
class CacheManager extends SintController {}
class TempController extends SintController {}
class ThemeController extends SintController {}
class FormController extends SintController {}
```

**Test de putAsync**:
```dart
test('putAsync doit attendre l\'initialisation', () async {
  await Sint.putAsync(() async {
    final controller = AsyncController();
    await controller.init();
    return controller;
  });

  final controller = Sint.find<AsyncController>();
  expect(controller.isInitialized, true);
});

class AsyncController extends SintController {
  bool isInitialized = false;

  Future<void> init() async {
    await Future.delayed(Duration(milliseconds: 100));
    isInitialized = true;
  }
}
```

### Tests de Bindings

```dart
testWidgets('Binding doit injecter les dépendances', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(
      getPages: [
        GetPage(
          name: '/test',
          page: () => TestPage(),
          binding: TestBinding(),
        ),
      ],
      initialRoute: '/test',
    ),
  );

  await tester.pumpAndSettle();

  // Vérifier que les dépendances sont injectées
  expect(Sint.isRegistered<TestController>(), true);
  expect(Sint.isRegistered<TestService>(), true);
});

class TestBinding extends Bindings {
  @override
  void dependencies() {
    Sint.lazyPut(() => TestController());
    Sint.lazyPut(() => TestService());
  }
}

class TestController extends SintController {}
class TestService extends SintController {}
class TestPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold();
}
```

### Tests de Cycle de Vie

```dart
test('delete doit supprimer l\'instance', () {
  Sint.put(TestController());
  expect(Sint.isRegistered<TestController>(), true);

  Sint.delete<TestController>();
  expect(Sint.isRegistered<TestController>(), false);
});

test('reset doit tout supprimer', () {
  Sint.put(TestController());
  Sint.put(AnotherController());

  Sint.reset();

  expect(Sint.isRegistered<TestController>(), false);
  expect(Sint.isRegistered<AnotherController>(), false);
});

test('onClose doit être appelé à la suppression', () {
  var closeCalled = false;

  final controller = TestControllerWithClose(() {
    closeCalled = true;
  });

  Sint.put(controller);
  Sint.delete<TestControllerWithClose>();

  expect(closeCalled, true);
});

class TestControllerWithClose extends SintController {
  final VoidCallback onCloseCallback;

  TestControllerWithClose(this.onCloseCallback);

  @override
  void onClose() {
    onCloseCallback();
    super.onClose();
  }
}

class AnotherController extends SintController {}
```

### Bonnes Pratiques de Test

1. **Toujours nettoyer après les tests**:
```dart
tearDown(() {
  Sint.reset();
});
```

2. **Utiliser des mocks pour les services**:
```dart
class MockApiService extends Mock implements ApiService {}

test('Injection avec mock', () {
  Sint.put<ApiService>(MockApiService());

  final service = Sint.find<ApiService>();
  expect(service, isA<MockApiService>());
});
```

3. **Tester l'isolation des instances**:
```dart
test('Les instances doivent être isolées', () {
  Sint.put(CounterController(), tag: 'counter1');
  Sint.put(CounterController(), tag: 'counter2');

  final c1 = Sint.find<CounterController>(tag: 'counter1');
  final c2 = Sint.find<CounterController>(tag: 'counter2');

  c1.increment();

  expect(c1.count, 1);
  expect(c2.count, 0);
});

class CounterController extends SintController {
  int count = 0;
  void increment() => count++;
}
```

4. **Tester les dépendances entre services**:
```dart
test('Les services doivent résoudre les dépendances', () {
  Sint.put(AuthService());
  Sint.put(ApiService(Sint.find<AuthService>()));

  final api = Sint.find<ApiService>();
  expect(api.auth, isA<AuthService>());
});

class AuthService extends SintController {
  String get token => 'test-token';
}

class ApiService extends SintController {
  final AuthService auth;
  ApiService(this.auth);
}
```
