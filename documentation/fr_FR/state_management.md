# Gestion de l'État

SINT propose plusieurs approches pour la gestion de l'état dans Flutter, permettant aux développeurs de choisir la solution la plus adaptée à leurs besoins spécifiques.

## Table des matières

- [Gestion d'État Réactive](#gestion-détat-réactive)
  - [Variables Observables (.obs)](#variables-observables-obs)
  - [Widget Obx](#widget-obx)
  - [Classes Rx personnalisées](#classes-rx-personnalisées)
- [Gestion d'État Simple](#gestion-détat-simple)
  - [SintBuilder](#SintBuilder)
  - [SintController](#SintController)
- [StateMixin](#statemixin)
  - [États de chargement](#états-de-chargement)
  - [Gestion des erreurs](#gestion-des-erreurs)
- [Workers](#workers)
  - [Types de Workers](#types-de-workers)
  - [Cas d'utilisation](#cas-dutilisation)
- [Feuille de route des tests](#feuille-de-route-des-tests)

## Gestion d'État Réactive

La gestion d'état réactive de SINT utilise le pattern Observable pour mettre à jour automatiquement l'interface utilisateur lorsque les données changent.

### Variables Observables (.obs)

Transformez n'importe quelle variable en observable en ajoutant `.obs`:

```dart
import 'package:sint/sint.dart';

class CounterController extends SintController {
  // Variable observable
  var count = 0.obs;

  // Méthode pour incrémenter
  void increment() {
    count++;
    // L'UI se met à jour automatiquement
  }

  // Liste observable
  var items = <String>[].obs;

  void addItem(String item) {
    items.add(item);
  }

  // Objet observable
  var user = User(name: 'John', age: 30).obs;

  void updateName(String newName) {
    user.update((val) {
      val?.name = newName;
    });
  }
}

class User {
  String name;
  int age;

  User({required this.name, required this.age});
}
```

### Widget Obx

Le widget `Obx` reconstruit automatiquement son contenu lorsqu'un observable change:

```dart
class CounterPage extends StatelessWidget {
  final controller = Sint.put(CounterController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Compteur Réactif')),
      body: Center(
        child: Obx(() => Text(
          'Compte: ${controller.count}',
          style: TextStyle(fontSize: 48),
        )),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.increment,
        child: Icon(Icons.add),
      ),
    );
  }
}
```

**Remarque importante**: Le widget `Obx` ne reconstruit que le widget spécifique où il est utilisé, pas toute la page.

### Classes Rx personnalisées

Pour des types personnalisés, créez des classes Rx:

```dart
class Product {
  final String name;
  final double price;

  Product({required this.name, required this.price});
}

class ShoppingController extends SintController {
  // Objet personnalisé observable
  var selectedProduct = Product(name: '', price: 0.0).obs;

  void selectProduct(Product product) {
    selectedProduct.value = product;
  }

  // Alternative avec Rx<T>
  final Rx<Product?> currentProduct = Rx<Product?>(null);

  void setCurrentProduct(Product product) {
    currentProduct.value = product;
  }
}
```

Utilisation dans l'interface:

```dart
class ProductView extends StatelessWidget {
  final controller = Sint.find<ShoppingController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final product = controller.selectedProduct.value;
      return Card(
        child: ListTile(
          title: Text(product.name),
          subtitle: Text('${product.price}€'),
        ),
      );
    });
  }
}
```

## Gestion d'État Simple

Pour les cas où la réactivité automatique n'est pas nécessaire, SINT propose une approche simple et performante.

### SintBuilder

`SintBuilder` est un widget léger qui ne se reconstruit que lorsque vous appelez explicitement `update()`:

```dart
class SimpleController extends SintController {
  int count = 0;

  void increment() {
    count++;
    update(); // Déclenche la reconstruction
  }

  void incrementWithoutUpdate() {
    count++;
    // Pas de reconstruction
  }

  // Update avec ID pour reconstruction ciblée
  void updateSpecificWidget() {
    count++;
    update(['counter-text']); // Seuls les widgets avec cet ID se reconstruisent
  }
}
```

Utilisation avec `SintBuilder`:

```dart
class SimplePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gestion Simple')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SintBuilder<SimpleController>(
              init: SimpleController(),
              builder: (controller) {
                return Text(
                  'Compte: ${controller.count}',
                  style: TextStyle(fontSize: 48),
                );
              },
            ),
            SizedBox(height: 20),
            SintBuilder<SimpleController>(
              id: 'counter-text',
              builder: (controller) {
                return Text('Compteur ciblé: ${controller.count}');
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Sint.find<SimpleController>().increment(),
        child: Icon(Icons.add),
      ),
    );
  }
}
```

**Avantages de SintBuilder**:
- Plus performant que les approches réactives pour de grandes listes
- Contrôle précis de la reconstruction
- Moins de consommation mémoire
- Reconstruction ciblée avec les ID

### SintController

Tous les contrôleurs héritent de `SintController` qui fournit des callbacks de cycle de vie:

```dart
class LifecycleController extends SintController {
  @override
  void onInit() {
    super.onInit();
    print('Contrôleur initialisé');
    // Initialisation, appels API, etc.
  }

  @override
  void onReady() {
    super.onReady();
    print('Contrôleur prêt - UI construite');
    // Actions après construction de l'UI
  }

  @override
  void onClose() {
    print('Contrôleur détruit');
    // Nettoyage des ressources
    super.onClose();
  }
}
```

## StateMixin

`StateMixin` simplifie la gestion des états de chargement, succès, et erreur dans vos contrôleurs.

### États de chargement

```dart
class UserController extends SintController with StateMixin<User> {
  final UserRepository repository;

  UserController(this.repository);

  @override
  void onInit() {
    super.onInit();
    loadUser();
  }

  Future<void> loadUser() async {
    // Définir l'état en chargement
    change(null, status: RxStatus.loading());

    try {
      final user = await repository.fetchUser();
      // Définir l'état en succès
      change(user, status: RxStatus.success());
    } catch (error) {
      // Définir l'état en erreur
      change(null, status: RxStatus.error(error.toString()));
    }
  }

  void retry() {
    loadUser();
  }
}
```

### Gestion des erreurs

Utilisez le widget approprié pour afficher les différents états:

```dart
class UserPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profil Utilisateur')),
      body: SintBuilder<UserController>(
        init: UserController(UserRepository()),
        builder: (controller) {
          return controller.obx(
            (user) => UserProfile(user: user!),
            onLoading: Center(
              child: CircularProgressIndicator(),
            ),
            onError: (error) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(error ?? 'Erreur inconnue'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: controller.retry,
                    child: Text('Réessayer'),
                  ),
                ],
              ),
            ),
            onEmpty: Center(
              child: Text('Aucune donnée disponible'),
            ),
          );
        },
      ),
    );
  }
}

class UserProfile extends StatelessWidget {
  final User user;

  const UserProfile({required this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Nom: ${user.name}', style: TextStyle(fontSize: 24)),
          Text('Âge: ${user.age}', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
```

## Workers

Les Workers écoutent les changements sur les observables et exécutent des callbacks.

### Types de Workers

```dart
class WorkerController extends SintController {
  var count = 0.obs;
  var name = ''.obs;

  @override
  void onInit() {
    super.onInit();

    // ever - Appelé à chaque changement
    ever(count, (value) {
      print('Count changé à: $value');
    });

    // once - Appelé une seule fois au premier changement
    once(count, (value) {
      print('Première modification du count: $value');
    });

    // debounce - Appelé après un délai depuis le dernier changement
    // Utile pour la recherche
    debounce(
      name,
      (value) {
        print('Recherche pour: $value');
        performSearch(value);
      },
      time: Duration(milliseconds: 800),
    );

    // interval - Appelé au maximum une fois par intervalle
    // Utile pour éviter trop d'appels API
    interval(
      count,
      (value) {
        print('Sauvegarde du count: $value');
        saveToServer(value);
      },
      time: Duration(seconds: 1),
    );
  }

  void performSearch(String query) {
    // Logique de recherche
  }

  void saveToServer(int value) {
    // Sauvegarde sur le serveur
  }

  void increment() {
    count++;
  }

  void updateName(String newName) {
    name.value = newName;
  }
}
```

### Cas d'utilisation

**Barre de recherche avec debounce**:

```dart
class SearchController extends SintController {
  var searchQuery = ''.obs;
  var results = <String>[].obs;

  @override
  void onInit() {
    super.onInit();

    debounce(
      searchQuery,
      (query) async {
        if (query.isNotEmpty) {
          results.value = await searchAPI(query);
        } else {
          results.clear();
        }
      },
      time: Duration(milliseconds: 500),
    );
  }

  Future<List<String>> searchAPI(String query) async {
    // Simulation d'appel API
    await Future.delayed(Duration(milliseconds: 300));
    return ['Résultat 1', 'Résultat 2', 'Résultat 3'];
  }
}

class SearchPage extends StatelessWidget {
  final controller = Sint.put(SearchController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recherche')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => controller.searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.results.isEmpty) {
                return Center(child: Text('Aucun résultat'));
              }
              return ListView.builder(
                itemCount: controller.results.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(controller.results[index]),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
```

**Sauvegarde automatique avec interval**:

```dart
class EditorController extends SintController {
  var content = ''.obs;
  var lastSaved = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();

    interval(
      content,
      (value) {
        saveContent(value);
        lastSaved.value = DateTime.now();
      },
      time: Duration(seconds: 5),
    );
  }

  void saveContent(String text) {
    print('Sauvegarde: $text');
    // Logique de sauvegarde
  }

  void updateContent(String text) {
    content.value = text;
  }
}
```

## Feuille de route des tests

### Tests Unitaires pour la Gestion d'État

**Test des variables observables**:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

void main() {
  group('CounterController Tests', () {
    late CounterController controller;

    setUp(() {
      controller = CounterController();
    });

    test('La valeur initiale du count doit être 0', () {
      expect(controller.count.value, 0);
    });

    test('increment() doit augmenter le count de 1', () {
      controller.increment();
      expect(controller.count.value, 1);

      controller.increment();
      expect(controller.count.value, 2);
    });

    test('Les listes observables doivent être modifiables', () {
      expect(controller.items.length, 0);

      controller.addItem('Item 1');
      expect(controller.items.length, 1);
      expect(controller.items[0], 'Item 1');
    });
  });
}
```

**Test avec SintBuilder**:
```dart
testWidgets('SintBuilder doit se reconstruire après update()', (tester) async {
  final controller = SimpleController();
  Sint.put(controller);

  await tester.pumpWidget(
    MaterialApp(
      home: SintBuilder<SimpleController>(
        builder: (ctrl) => Text('${ctrl.count}'),
      ),
    ),
  );

  expect(find.text('0'), findsOneWidget);

  controller.increment();
  await tester.pump();

  expect(find.text('1'), findsOneWidget);
});
```

**Test avec StateMixin**:
```dart
test('StateMixin doit gérer les états correctement', () async {
  final repository = MockUserRepository();
  final controller = UserController(repository);

  // État initial
  expect(controller.state, null);

  // État de chargement
  controller.loadUser();
  expect(controller.status.isLoading, true);

  // Attendre la complétion
  await Future.delayed(Duration(milliseconds: 100));

  // Vérifier l'état de succès
  expect(controller.status.isSuccess, true);
  expect(controller.state, isNotNull);
});
```

**Test des Workers**:
```dart
test('debounce doit attendre avant d\'exécuter le callback', () async {
  final controller = WorkerController();
  var callCount = 0;

  // Remplacer le worker pour le test
  debounce(
    controller.name,
    (_) => callCount++,
    time: Duration(milliseconds: 300),
  );

  controller.updateName('A');
  controller.updateName('AB');
  controller.updateName('ABC');

  // Ne doit pas être appelé immédiatement
  expect(callCount, 0);

  // Attendre le délai de debounce
  await Future.delayed(Duration(milliseconds: 400));

  // Doit être appelé une seule fois
  expect(callCount, 1);
});
```

### Tests de Widget

**Test du widget Obx**:
```dart
testWidgets('Obx doit se reconstruire quand l\'observable change', (tester) async {
  final controller = Sint.put(CounterController());

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Obx(() => Text('${controller.count}')),
      ),
    ),
  );

  expect(find.text('0'), findsOneWidget);

  controller.increment();
  await tester.pump();

  expect(find.text('1'), findsOneWidget);
  expect(find.text('0'), findsNothing);
});
```

### Bonnes Pratiques de Test

1. **Toujours nettoyer les contrôleurs après les tests**:
```dart
tearDown(() {
  Sint.delete<CounterController>();
  Sint.reset();
});
```

2. **Utiliser des mocks pour les dépendances**:
```dart
class MockRepository extends Mock implements UserRepository {}
```

3. **Tester les cycles de vie**:
```dart
test('onInit doit être appelé à l\'initialisation', () {
  var initCalled = false;

  final controller = LifecycleController();
  controller.onInit();

  // Vérifier que l'initialisation s'est bien passée
  expect(initCalled, true);
});
```

4. **Tester les cas d'erreur**:
```dart
test('StateMixin doit gérer les erreurs', () async {
  final repository = MockUserRepository();
  when(repository.fetchUser()).thenThrow(Exception('Network error'));

  final controller = UserController(repository);
  await controller.loadUser();

  expect(controller.status.isError, true);
  expect(controller.status.errorMessage, contains('Network error'));
});
```
