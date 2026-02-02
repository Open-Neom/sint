# Gestion de la Navigation

SINT simplifie radicalement la navigation dans Flutter avec une API intuitive et puissante qui ne nécessite pas de BuildContext.

## Table des matières

- [Configuration de Base](#configuration-de-base)
  - [SintMaterialApp](#sintmaterialapp)
  - [Configuration initiale](#configuration-initiale)
- [Navigation Simple](#navigation-simple)
  - [Navigation directe](#navigation-directe)
  - [Navigation avec retour](#navigation-avec-retour)
  - [Passage de données](#passage-de-données)
- [Routes Nommées](#routes-nommées)
  - [Définition des routes](#définition-des-routes)
  - [Navigation avec routes nommées](#navigation-avec-routes-nommées)
  - [Routes imbriquées](#routes-imbriquées)
- [URLs Dynamiques](#urls-dynamiques)
  - [Paramètres d'URL](#paramètres-durl)
  - [Query parameters](#query-parameters)
- [Middleware](#middleware)
  - [Création de middleware](#création-de-middleware)
  - [Guards d'authentification](#guards-dauthentification)
- [SnackBars, Dialogs et BottomSheets](#snackbars-dialogs-et-bottomsheets)
  - [SnackBars](#snackbars)
  - [Dialogs](#dialogs)
  - [BottomSheets](#bottomsheets)
- [Transitions](#transitions)
  - [Transitions personnalisées](#transitions-personnalisées)
  - [Configuration globale](#configuration-globale)
- [Feuille de route des tests](#feuille-de-route-des-tests)

## Configuration de Base

### SintMaterialApp

Remplacez `MaterialApp` par `SintMaterialApp` pour activer les fonctionnalités de navigation:

```dart
import 'package:sint/sint.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SintMaterialApp(
      title: 'Mon Application',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
      // ou utilisez initialRoute pour les routes nommées
      // initialRoute: '/home',
    );
  }
}
```

### Configuration initiale

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SintMaterialApp(
      title: 'SINT App',
      initialRoute: '/',
      defaultTransition: Transition.fade,
      translations: MyTranslations(),
      locale: Locale('fr', 'FR'),
      fallbackLocale: Locale('en', 'US'),
      getPages: [
        GetPage(name: '/', page: () => HomePage()),
        GetPage(name: '/profile', page: () => ProfilePage()),
        GetPage(name: '/settings', page: () => SettingsPage()),
      ],
    );
  }
}
```

## Navigation Simple

### Navigation directe

Naviguez vers une nouvelle page sans BuildContext:

```dart
// Navigation simple
Sint.to(SecondPage());

// Remplace la page actuelle
Sint.off(SecondPage());

// Supprime toutes les routes précédentes
Sint.offAll(HomePage());
```

**Exemples pratiques**:

```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Accueil')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Sint.to(ProfilePage()),
              child: Text('Voir le Profil'),
            ),
            ElevatedButton(
              onPressed: () => Sint.to(SettingsPage()),
              child: Text('Paramètres'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Navigation avec retour

```dart
// Navigue et attend un résultat
final result = await Sint.to(SelectItemPage());

if (result != null) {
  print('Item sélectionné: $result');
}

// Sur la page de sélection, retourner une valeur
class SelectItemPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sélectionner un item')),
      body: ListView(
        children: [
          ListTile(
            title: Text('Item 1'),
            onTap: () => Sint.back(result: 'Item 1'),
          ),
          ListTile(
            title: Text('Item 2'),
            onTap: () => Sint.back(result: 'Item 2'),
          ),
        ],
      ),
    );
  }
}
```

**Vérification de possibilité de retour**:

```dart
if (Sint.isDialogOpen ?? false) {
  Sint.back(); // Ferme le dialog
} else if (Sint.isBottomSheetOpen ?? false) {
  Sint.back(); // Ferme le bottom sheet
} else {
  // Logique personnalisée
}
```

### Passage de données

```dart
// Envoyer des données
Sint.to(
  UserDetailPage(),
  arguments: User(name: 'John', age: 30),
);

// Recevoir des données
class UserDetailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User user = Sint.arguments;

    return Scaffold(
      appBar: AppBar(title: Text(user.name)),
      body: Center(
        child: Text('Âge: ${user.age}'),
      ),
    );
  }
}

class User {
  final String name;
  final int age;

  User({required this.name, required this.age});
}
```

## Routes Nommées

### Définition des routes

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SintMaterialApp(
      initialRoute: '/',
      getPages: [
        GetPage(
          name: '/',
          page: () => HomePage(),
          binding: HomeBinding(),
        ),
        GetPage(
          name: '/profile',
          page: () => ProfilePage(),
          binding: ProfileBinding(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: '/settings',
          page: () => SettingsPage(),
          binding: SettingsBinding(),
        ),
        GetPage(
          name: '/product/:id',
          page: () => ProductDetailPage(),
          binding: ProductBinding(),
        ),
      ],
      unknownRoute: GetPage(
        name: '/notfound',
        page: () => NotFoundPage(),
      ),
    );
  }
}
```

### Navigation avec routes nommées

```dart
// Navigation vers une route nommée
Sint.toNamed('/profile');

// Avec arguments
Sint.toNamed('/profile', arguments: {'userId': 123});

// Remplacer la route actuelle
Sint.offNamed('/login');

// Supprime tout et navigue
Sint.offAllNamed('/home');

// Navigation vers une route avec retour jusqu'à une condition
Sint.until((route) => route.settings.name == '/home');
```

**Récupération des arguments**:

```dart
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final args = Sint.arguments as Map<String, dynamic>;
    final userId = args['userId'];

    return Scaffold(
      appBar: AppBar(title: Text('Profil #$userId')),
      body: ProfileContent(userId: userId),
    );
  }
}
```

### Routes imbriquées

```dart
GetPage(
  name: '/dashboard',
  page: () => DashboardPage(),
  children: [
    GetPage(
      name: '/overview',
      page: () => OverviewPage(),
    ),
    GetPage(
      name: '/analytics',
      page: () => AnalyticsPage(),
    ),
    GetPage(
      name: '/reports',
      page: () => ReportsPage(),
    ),
  ],
)

// Navigation vers les routes imbriquées
Sint.toNamed('/dashboard/overview');
Sint.toNamed('/dashboard/analytics');
```

## URLs Dynamiques

### Paramètres d'URL

```dart
// Définition avec paramètres
GetPage(
  name: '/product/:id',
  page: () => ProductDetailPage(),
)

GetPage(
  name: '/user/:userId/post/:postId',
  page: () => PostDetailPage(),
)

// Navigation
Sint.toNamed('/product/123');
Sint.toNamed('/user/456/post/789');

// Récupération des paramètres
class ProductDetailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final productId = Sint.parameters['id'];

    return Scaffold(
      appBar: AppBar(title: Text('Produit #$productId')),
      body: ProductDetails(productId: productId!),
    );
  }
}
```

### Query parameters

```dart
// Navigation avec query parameters
Sint.toNamed('/search?query=flutter&category=mobile');

// Récupération
class SearchPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final query = Sint.parameters['query'];
    final category = Sint.parameters['category'];

    return Scaffold(
      appBar: AppBar(title: Text('Recherche: $query')),
      body: SearchResults(
        query: query!,
        category: category,
      ),
    );
  }
}
```

**Combinaison de paramètres d'URL et query params**:

```dart
// Route: /product/:id
Sint.toNamed('/product/123?tab=reviews&sort=recent');

class ProductDetailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final productId = Sint.parameters['id'];
    final tab = Sint.parameters['tab'] ?? 'overview';
    final sort = Sint.parameters['sort'] ?? 'default';

    return ProductView(
      productId: productId!,
      initialTab: tab,
      sortOrder: sort,
    );
  }
}
```

## Middleware

Les middlewares permettent d'intercepter la navigation pour ajouter de la logique comme l'authentification.

### Création de middleware

```dart
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Vérifier si l'utilisateur est authentifié
    final authService = Sint.find<AuthService>();

    if (!authService.isAuthenticated) {
      return RouteSettings(name: '/login');
    }

    return null; // Continuer la navigation
  }

  @override
  int? get priority => 1;
}
```

### Guards d'authentification

```dart
class LoginRequiredMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Sint.find<AuthService>();

    if (!auth.isLoggedIn) {
      return RouteSettings(name: '/login');
    }

    return null;
  }
}

class AdminMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Sint.find<AuthService>();

    if (!auth.isAdmin) {
      // Rediriger vers la page d'accès refusé
      return RouteSettings(name: '/forbidden');
    }

    return null;
  }

  @override
  int? get priority => 2; // Exécuté après LoginRequiredMiddleware
}

// Configuration des routes avec middleware
SintMaterialApp(
  getPages: [
    GetPage(
      name: '/login',
      page: () => LoginPage(),
    ),
    GetPage(
      name: '/profile',
      page: () => ProfilePage(),
      middlewares: [LoginRequiredMiddleware()],
    ),
    GetPage(
      name: '/admin',
      page: () => AdminPage(),
      middlewares: [
        LoginRequiredMiddleware(),
        AdminMiddleware(),
      ],
    ),
  ],
)
```

**Middleware avec onPageCalled**:

```dart
class LoggingMiddleware extends GetMiddleware {
  @override
  GetPage? onPageCalled(GetPage? page) {
    print('Navigation vers: ${page?.name}');
    return page;
  }
}

class AnalyticsMiddleware extends GetMiddleware {
  @override
  GetPage? onPageCalled(GetPage? page) {
    // Envoyer l'événement à Google Analytics
    Analytics.logScreenView(screenName: page?.name ?? 'unknown');
    return page;
  }
}
```

## SnackBars, Dialogs et BottomSheets

### SnackBars

Afficher des messages sans BuildContext:

```dart
// SnackBar simple
Sint.snackbar(
  'Titre',
  'Message de notification',
);

// SnackBar avec options
Sint.snackbar(
  'Succès',
  'Opération réussie!',
  snackPosition: SnackPosition.BOTTOM,
  backgroundColor: Colors.green,
  colorText: Colors.white,
  duration: Duration(seconds: 3),
  icon: Icon(Icons.check_circle, color: Colors.white),
  margin: EdgeInsets.all(16),
  borderRadius: 8,
);

// SnackBar avec action
Sint.snackbar(
  'Fichier supprimé',
  'Le fichier a été supprimé',
  mainButton: TextButton(
    onPressed: () {
      // Annuler la suppression
      print('Annulation...');
    },
    child: Text('ANNULER', style: TextStyle(color: Colors.white)),
  ),
);
```

**SnackBar personnalisé**:

```dart
void showErrorSnackbar(String message) {
  Sint.snackbar(
    'Erreur',
    message,
    backgroundColor: Colors.red[700],
    colorText: Colors.white,
    icon: Icon(Icons.error_outline, color: Colors.white),
    snackPosition: SnackPosition.TOP,
    borderRadius: 12,
    margin: EdgeInsets.all(16),
    duration: Duration(seconds: 4),
  );
}

void showSuccessSnackbar(String message) {
  Sint.snackbar(
    'Succès',
    message,
    backgroundColor: Colors.green[700],
    colorText: Colors.white,
    icon: Icon(Icons.check_circle_outline, color: Colors.white),
    snackPosition: SnackPosition.BOTTOM,
  );
}
```

### Dialogs

```dart
// Dialog simple
Sint.defaultDialog(
  title: 'Confirmer',
  middleText: 'Voulez-vous continuer?',
  textConfirm: 'Oui',
  textCancel: 'Non',
  onConfirm: () {
    print('Confirmé');
    Sint.back();
  },
  onCancel: () {
    print('Annulé');
  },
);

// Dialog personnalisé
Sint.dialog(
  AlertDialog(
    title: Text('Notification'),
    content: Text('Contenu du dialog'),
    actions: [
      TextButton(
        onPressed: () => Sint.back(),
        child: Text('FERMER'),
      ),
    ],
  ),
);

// Dialog avec widget personnalisé
Sint.dialog(
  CustomDialog(),
  barrierDismissible: false,
);

class CustomDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, size: 48, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Attention',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Cette action est irréversible'),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Sint.back(result: false),
                  child: Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Sint.back(result: true),
                  child: Text('Confirmer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### BottomSheets

```dart
// BottomSheet simple
Sint.bottomSheet(
  Container(
    height: 200,
    color: Colors.white,
    child: Center(
      child: Text('BottomSheet'),
    ),
  ),
);

// BottomSheet avec options
Sint.bottomSheet(
  OptionsBottomSheet(),
  backgroundColor: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  isScrollControlled: true,
  enableDrag: true,
);

class OptionsBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.share),
            title: Text('Partager'),
            onTap: () {
              Sint.back(result: 'share');
            },
          ),
          ListTile(
            leading: Icon(Icons.link),
            title: Text('Copier le lien'),
            onTap: () {
              Sint.back(result: 'copy');
            },
          ),
          ListTile(
            leading: Icon(Icons.delete),
            title: Text('Supprimer'),
            onTap: () {
              Sint.back(result: 'delete');
            },
          ),
        ],
      ),
    );
  }
}

// Attendre le résultat du BottomSheet
final result = await Sint.bottomSheet(OptionsBottomSheet());

switch (result) {
  case 'share':
    shareContent();
    break;
  case 'copy':
    copyLink();
    break;
  case 'delete':
    deleteItem();
    break;
}
```

## Transitions

### Transitions personnalisées

```dart
// Transition par route
GetPage(
  name: '/details',
  page: () => DetailsPage(),
  transition: Transition.fadeIn,
  transitionDuration: Duration(milliseconds: 300),
)

// Types de transitions disponibles
Transition.fade
Transition.fadeIn
Transition.rightToLeft
Transition.leftToRight
Transition.upToDown
Transition.downToUp
Transition.rightToLeftWithFade
Transition.leftToRightWithFade
Transition.zoom
Transition.topLevel
Transition.noTransition
Transition.cupertino
Transition.cupertinoDialog
Transition.size
Transition.native
```

### Configuration globale

```dart
SintMaterialApp(
  defaultTransition: Transition.cupertino,
  transitionDuration: Duration(milliseconds: 400),
  getPages: [
    // Les pages utilisent la transition par défaut
    GetPage(name: '/home', page: () => HomePage()),

    // Sauf si surchargée
    GetPage(
      name: '/special',
      page: () => SpecialPage(),
      transition: Transition.zoom,
    ),
  ],
)
```

**Transition personnalisée avancée**:

```dart
GetPage(
  name: '/custom',
  page: () => CustomPage(),
  customTransition: CustomPageTransition(),
  transitionDuration: Duration(milliseconds: 500),
)

class CustomPageTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: animation,
      child: RotationTransition(
        turns: animation,
        child: child,
      ),
    );
  }
}
```

## Feuille de route des tests

### Tests de Navigation

**Test de navigation simple**:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

void main() {
  testWidgets('Navigation vers une nouvelle page', (tester) async {
    await tester.pumpWidget(
      SintMaterialApp(
        home: HomePage(),
      ),
    );

    // Vérifier la page d'accueil
    expect(find.text('Accueil'), findsOneWidget);

    // Naviguer
    Sint.to(SecondPage());
    await tester.pumpAndSettle();

    // Vérifier la navigation
    expect(find.text('Deuxième Page'), findsOneWidget);
    expect(find.text('Accueil'), findsNothing);
  });

  testWidgets('Navigation avec retour de données', (tester) async {
    await tester.pumpWidget(
      SintMaterialApp(
        home: SelectionPage(),
      ),
    );

    String? result;

    // Simuler la sélection
    Sint.to(ItemSelectionPage()).then((value) {
      result = value;
    });

    await tester.pumpAndSettle();

    // Sélectionner un item
    await tester.tap(find.text('Item A'));
    await tester.pumpAndSettle();

    expect(result, 'Item A');
  });
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Accueil')),
    );
  }
}

class SecondPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Deuxième Page')),
    );
  }
}
```

### Tests de Routes Nommées

```dart
testWidgets('Navigation avec routes nommées', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => HomePage()),
        GetPage(name: '/profile', page: () => ProfilePage()),
      ],
    ),
  );

  expect(find.text('Accueil'), findsOneWidget);

  Sint.toNamed('/profile');
  await tester.pumpAndSettle();

  expect(find.text('Profil'), findsOneWidget);
});

testWidgets('Paramètres d\'URL', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(
      getPages: [
        GetPage(
          name: '/user/:id',
          page: () => UserPage(),
        ),
      ],
      initialRoute: '/user/123',
    ),
  );

  await tester.pumpAndSettle();

  expect(Sint.parameters['id'], '123');
});

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Profil')));
  }
}

class UserPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Utilisateur')));
  }
}
```

### Tests de Middleware

```dart
testWidgets('Middleware doit rediriger les utilisateurs non authentifiés', (tester) async {
  final authService = MockAuthService();
  Sint.put<AuthService>(authService);

  when(authService.isAuthenticated).thenReturn(false);

  await tester.pumpWidget(
    SintMaterialApp(
      getPages: [
        GetPage(name: '/login', page: () => LoginPage()),
        GetPage(
          name: '/protected',
          page: () => ProtectedPage(),
          middlewares: [AuthMiddleware()],
        ),
      ],
      initialRoute: '/protected',
    ),
  );

  await tester.pumpAndSettle();

  // Doit être redirigé vers login
  expect(find.text('Login'), findsOneWidget);
  expect(find.text('Protected'), findsNothing);
});

class MockAuthService extends Mock implements AuthService {}

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Login')));
  }
}

class ProtectedPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Protected')));
  }
}
```

### Tests de SnackBars et Dialogs

```dart
testWidgets('Affichage de SnackBar', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(
      home: Scaffold(
        body: ElevatedButton(
          onPressed: () {
            Sint.snackbar('Titre', 'Message');
          },
          child: Text('Afficher'),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Afficher'));
  await tester.pump();

  expect(find.text('Titre'), findsOneWidget);
  expect(find.text('Message'), findsOneWidget);
});

testWidgets('Affichage de Dialog', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(
      home: Scaffold(
        body: ElevatedButton(
          onPressed: () {
            Sint.defaultDialog(
              title: 'Confirmation',
              middleText: 'Êtes-vous sûr?',
            );
          },
          child: Text('Afficher Dialog'),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Afficher Dialog'));
  await tester.pumpAndSettle();

  expect(find.text('Confirmation'), findsOneWidget);
  expect(find.text('Êtes-vous sûr?'), findsOneWidget);
});
```

### Bonnes Pratiques de Test

1. **Toujours utiliser pumpAndSettle pour les animations**:
```dart
Sint.to(NextPage());
await tester.pumpAndSettle(); // Attend que toutes les animations se terminent
```

2. **Nettoyer après les tests de navigation**:
```dart
tearDown(() {
  Sint.reset();
});
```

3. **Tester les transitions**:
```dart
testWidgets('Vérifier la transition', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(
      getPages: [
        GetPage(
          name: '/fade',
          page: () => FadePage(),
          transition: Transition.fadeIn,
        ),
      ],
      home: HomePage(),
    ),
  );

  Sint.toNamed('/fade');

  // Pump à mi-transition
  await tester.pump(Duration(milliseconds: 150));

  // Vérifier que les deux pages sont visibles (en transition)
  expect(find.text('Accueil'), findsOneWidget);
  expect(find.text('Fade Page'), findsOneWidget);

  // Terminer la transition
  await tester.pumpAndSettle();

  // Seule la nouvelle page est visible
  expect(find.text('Fade Page'), findsOneWidget);
  expect(find.text('Accueil'), findsNothing);
});

class FadePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Fade Page')));
  }
}
```
