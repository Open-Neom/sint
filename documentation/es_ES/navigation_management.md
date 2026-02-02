# Gestion de Navegacion

SINT proporciona un sistema de navegacion completo sin necesidad de `context`, con soporte para rutas nombradas, URLs dinamicas, middleware, y transiciones personalizadas.

## Tabla de Contenidos

- [Configuracion Inicial](#configuracion-inicial)
- [Navegacion Basica](#navegacion-basica)
  - [Sint.to](#sintto)
  - [Sint.back](#sintback)
  - [Sint.off](#sintoff)
  - [Sint.offAll](#sintoffall)
- [Rutas Nombradas](#rutas-nombradas)
  - [Definir Rutas](#definir-rutas)
  - [Navegar por Nombre](#navegar-por-nombre)
  - [Parametros y Argumentos](#parametros-y-argumentos)
- [URLs Dinamicas](#urls-dinamicas)
- [Middleware](#middleware)
- [Transiciones](#transiciones)
- [SnackBars](#snackbars)
- [Dialogs](#dialogs)
- [BottomSheets](#bottomsheets)
- [Navegacion Anidada](#navegacion-anidada)
- [Best Practices](#best-practices)
- [Test Roadmap](#test-roadmap)

---

## Configuracion Inicial

Reemplaza `MaterialApp` por `SintMaterialApp`:

```dart
import 'package:sint/sint.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SintMaterialApp(
      title: 'Mi App SINT',
      theme: ThemeData.light(),
      home: HomePage(),
    );
  }
}
```

Ahora puedes navegar sin `context` desde cualquier parte del codigo.

---

## Navegacion Basica

### Sint.to

Navega a una nueva pantalla:

```dart
// Navegacion simple
Sint.to(DetailPage());

// Con transicion
Sint.to(
  ProfilePage(),
  transition: Transition.rightToLeft,
  duration: Duration(milliseconds: 300),
);

// Esperar resultado
final result = await Sint.to(SelectionPage());
print('Seleccion: $result');
```

**Retornar resultado:**

```dart
// En SelectionPage
Sint.back(result: 'Opcion A');

// En la pagina anterior
final selection = await Sint.to(SelectionPage());
print(selection); // "Opcion A"
```

### Sint.back

Vuelve a la pantalla anterior:

```dart
// Volver sin resultado
Sint.back();

// Volver con resultado
Sint.back(result: {'status': 'saved', 'id': 123});

// Cerrar dialogs/bottomsheets
Sint.back(closeOverlays: true);
```

### Sint.off

Reemplaza la pantalla actual (no puedes volver):

```dart
// Navegar a login y eliminar pantalla actual
Sint.off(LoginPage());

// Util para flujos de onboarding
Sint.off(MainPage()); // El usuario no puede volver al onboarding
```

### Sint.offAll

Elimina todas las pantallas anteriores:

```dart
// Navegar a home y limpiar stack completo
Sint.offAll(HomePage());

// Util despues de login/logout
Sint.offAll(WelcomePage());

// Con predicado personalizado
Sint.offAll(
  HomePage(),
  predicate: (route) => route.isFirst, // Mantiene solo la primera ruta
);
```

---

## Rutas Nombradas

### Definir Rutas

```dart
class AppRoutes {
  static const home = '/';
  static const profile = '/profile';
  static const settings = '/settings';
  static const productDetail = '/product/:id';
}

SintMaterialApp(
  initialRoute: AppRoutes.home,
  getPages: [
    GetPage(
      name: AppRoutes.home,
      page: () => HomePage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => ProfilePage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => SettingsPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.productDetail,
      page: () => ProductDetailPage(),
    ),
  ],
)
```

### Navegar por Nombre

```dart
// Navegacion simple
Sint.toNamed('/profile');

// Con argumentos
Sint.toNamed('/product/123');

// Con parametros de query
Sint.toNamed('/settings?theme=dark&lang=es');

// Reemplazar ruta actual
Sint.offNamed('/login');

// Limpiar stack
Sint.offAllNamed('/home');
```

### Parametros y Argumentos

**Parametros de URL:**

```dart
// Ruta definida: '/product/:id'
Sint.toNamed('/product/42');

// En ProductDetailPage
final id = Sint.parameters['id']; // "42"
```

**Argumentos:**

```dart
// Enviar argumentos
Sint.toNamed(
  '/profile',
  arguments: {'userId': 123, 'name': 'Juan'},
);

// Recibir argumentos
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final args = Sint.arguments as Map<String, dynamic>;
    final userId = args['userId'];
    final name = args['name'];

    return Scaffold(
      appBar: AppBar(title: Text('Perfil de $name')),
      body: Text('ID: $userId'),
    );
  }
}
```

**Query Parameters:**

```dart
// URL: /settings?theme=dark&notifications=true
Sint.toNamed('/settings?theme=dark&notifications=true');

// Acceder
final theme = Sint.parameters['theme']; // "dark"
final notifications = Sint.parameters['notifications']; // "true"
```

---

## URLs Dinamicas

SINT soporta URLs tipo web con parametros y queries:

```dart
GetPage(
  name: '/user/:userId/posts/:postId',
  page: () => PostDetailPage(),
)

// Navegar
Sint.toNamed('/user/42/posts/100');

// Acceder parametros
final userId = Sint.parameters['userId']; // "42"
final postId = Sint.parameters['postId']; // "100"
```

**Parametros opcionales:**

```dart
GetPage(
  name: '/search/:category/:subcategory?',
  page: () => SearchPage(),
)

// Funciona con ambos:
Sint.toNamed('/search/electronics'); // subcategory = null
Sint.toNamed('/search/electronics/phones'); // subcategory = "phones"
```

---

## Middleware

Los **Middleware** interceptan la navegacion para validaciones o redirects:

```dart
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Verificar autenticacion
    final authService = Sint.find<AuthService>();

    if (!authService.isAuthenticated) {
      return RouteSettings(name: '/login');
    }

    return null; // null = continuar con la navegacion
  }

  @override
  int? get priority => 1; // Orden de ejecucion (menor = primero)
}

// Aplicar a ruta
GetPage(
  name: '/dashboard',
  page: () => DashboardPage(),
  middlewares: [AuthMiddleware()],
)
```

**onPageCalled:**

```dart
class LoggerMiddleware extends GetMiddleware {
  @override
  GetPage? onPageCalled(GetPage? page) {
    print('Navegando a: ${page?.name}');
    return page;
  }
}
```

**onBindingsStart/onPageBuilt:**

```dart
class AnalyticsMiddleware extends GetMiddleware {
  @override
  List<Bindings>? onBindingsStart(List<Bindings>? bindings) {
    print('Iniciando bindings');
    return bindings;
  }

  @override
  Widget onPageBuilt(Widget page) {
    print('Pagina construida');
    return page;
  }
}
```

---

## Transiciones

SINT incluye transiciones predefinidas:

```dart
Sint.to(
  NextPage(),
  transition: Transition.fadeIn,
  duration: Duration(milliseconds: 400),
  curve: Curves.easeInOut,
);
```

**Transiciones disponibles:**

- `Transition.fade` / `Transition.fadeIn`
- `Transition.rightToLeft` / `Transition.leftToRight`
- `Transition.upToDown` / `Transition.downToUp`
- `Transition.rightToLeftWithFade`
- `Transition.leftToRightWithFade`
- `Transition.zoom`
- `Transition.cupertino`
- `Transition.native` (Usa la transicion nativa de la plataforma)

**Transicion personalizada:**

```dart
GetPage(
  name: '/custom',
  page: () => CustomPage(),
  customTransition: MyCustomTransition(),
)

class MyCustomTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return RotationTransition(
      turns: animation,
      child: child,
    );
  }
}
```

**Transicion por defecto:**

```dart
SintMaterialApp(
  defaultTransition: Transition.cupertino,
  transitionDuration: Duration(milliseconds: 350),
)
```

---

## SnackBars

Mostrar notificaciones rapidas:

```dart
// SnackBar simple
Sint.snackbar(
  'Titulo',
  'Mensaje de notificacion',
);

// SnackBar personalizado
Sint.snackbar(
  'Error',
  'No se pudo conectar al servidor',
  snackPosition: SnackPosition.BOTTOM,
  backgroundColor: Colors.red,
  colorText: Colors.white,
  icon: Icon(Icons.error, color: Colors.white),
  duration: Duration(seconds: 3),
  isDismissible: true,
  dismissDirection: DismissDirection.horizontal,
  onTap: (_) => print('SnackBar presionado'),
);

// Con accion
Sint.snackbar(
  'Descarga completa',
  'archivo.pdf',
  mainButton: TextButton(
    onPressed: () => openFile(),
    child: Text('ABRIR', style: TextStyle(color: Colors.white)),
  ),
);
```

---

## Dialogs

Mostrar dialogos sin `context`:

```dart
// Dialog simple
Sint.defaultDialog(
  title: 'Eliminar',
  middleText: '¿Estas seguro de eliminar este elemento?',
  textConfirm: 'Eliminar',
  textCancel: 'Cancelar',
  confirmTextColor: Colors.white,
  onConfirm: () {
    deleteItem();
    Sint.back();
  },
);

// Dialog personalizado
Sint.dialog(
  AlertDialog(
    title: Text('Titulo'),
    content: Text('Contenido del dialog'),
    actions: [
      TextButton(
        onPressed: () => Sint.back(result: false),
        child: Text('Cancelar'),
      ),
      TextButton(
        onPressed: () => Sint.back(result: true),
        child: Text('Aceptar'),
      ),
    ],
  ),
  barrierDismissible: false,
);

// Esperar resultado
final confirmed = await Sint.dialog(...);
if (confirmed == true) {
  // Usuario confirmo
}
```

---

## BottomSheets

Mostrar paneles desde abajo:

```dart
// BottomSheet simple
Sint.bottomSheet(
  Container(
    color: Colors.white,
    child: Wrap(
      children: [
        ListTile(
          leading: Icon(Icons.photo),
          title: Text('Galeria'),
          onTap: () => Sint.back(result: 'gallery'),
        ),
        ListTile(
          leading: Icon(Icons.camera),
          title: Text('Camara'),
          onTap: () => Sint.back(result: 'camera'),
        ),
      ],
    ),
  ),
);

// BottomSheet personalizado
Sint.bottomSheet(
  Container(
    height: 300,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: YourCustomWidget(),
  ),
  backgroundColor: Colors.transparent,
  isDismissible: true,
  enableDrag: true,
  isScrollControlled: true,
);

// Esperar resultado
final choice = await Sint.bottomSheet(...);
print('Usuario eligio: $choice');
```

---

## Navegacion Anidada

Para tabs o navegacion dentro de widgets:

```dart
class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
        key: Sint.nestedKey(1), // ID unico para este navegador
        initialRoute: '/home',
        onGenerateRoute: (settings) {
          return GetPageRoute(
            page: () => _getPage(settings.name),
          );
        },
      ),
    );
  }

  Widget _getPage(String? route) {
    switch (route) {
      case '/home':
        return HomeTab();
      case '/profile':
        return ProfileTab();
      default:
        return HomeTab();
    }
  }
}

// Navegar en el navegador anidado
Sint.toNamed('/profile', id: 1);

// Volver en el navegador anidado
Sint.back(id: 1);
```

---

## Best Practices

### 1. Usa rutas nombradas para apps grandes

```dart
// BIEN - Rutas centralizadas
class Routes {
  static const login = '/login';
  static const home = '/home';
  static const profile = '/profile';
}

Sint.toNamed(Routes.profile);

// MAL - Strings hardcoded
Sint.toNamed('/profile');
```

### 2. Usa Bindings con rutas

```dart
// BIEN - Dependencias automaticas por ruta
GetPage(
  name: '/shop',
  page: () => ShopPage(),
  binding: ShopBinding(),
)

// MAL - Inyeccion manual en cada navegacion
Sint.to(ShopPage());
Sint.put(ShopController()); // Facil de olvidar
```

### 3. Limpia el stack cuando sea necesario

```dart
// Despues de login
Sint.offAllNamed('/home'); // El usuario no puede volver a login

// Despues de logout
Sint.offAllNamed('/welcome');
```

### 4. Usa middleware para proteger rutas

```dart
GetPage(
  name: '/admin',
  page: () => AdminPage(),
  middlewares: [AuthMiddleware(), RoleMiddleware()],
)
```

### 5. Define transiciones globales

```dart
SintMaterialApp(
  defaultTransition: Transition.cupertino,
  getPages: [
    GetPage(
      name: '/special',
      page: () => SpecialPage(),
      transition: Transition.zoom, // Override solo para esta ruta
    ),
  ],
)
```

---

## Test Roadmap

### Pruebas Planificadas - Pilar de Navegacion

1. **Deep Links**
   - Parsing de URLs complejas con multiples parametros
   - Tests de deep linking en Android/iOS
   - Validacion de fallback cuando deep link falla
   - Pruebas de deep links con autenticacion requerida
   - Integracion con Firebase Dynamic Links

2. **Analytics de Rutas**
   - Tracking automatico de navegacion por ruta
   - Tests de integracion con Firebase Analytics
   - Validacion de page view events
   - Pruebas de user journey mapping
   - Performance monitoring por ruta

3. **Navegacion Anidada Mejorada**
   - Tests de multiples navigators anidados
   - Validacion de state preservation en tabs
   - Pruebas de back button handling en nested navigation
   - Hero animations entre nested navigators
   - Tests de memory leaks con nested navigation

4. **Routing VR/XR/AR**
   - Navegacion espacial en entornos 3D
   - Tests de transiciones en realidad aumentada
   - Validacion de routing context-aware (location-based)
   - Pruebas de overlay routing en XR
   - Integracion con ARCore/ARKit routing

5. **Middleware Avanzado**
   - Tests de cadenas de middleware complejas
   - Validacion de short-circuit en middleware
   - Pruebas de async middleware con timeouts
   - Performance profiling de middleware stack
   - Tests de error handling en middleware

6. **Transiciones Personalizadas**
   - Library de transiciones pre-built
   - Tests de shared element transitions
   - Validacion de physics-based transitions
   - Pruebas de interrupt handling en transiciones
   - Performance benchmarks por tipo de transicion

7. **Overlay Management**
   - Tests de z-index en overlays multiples
   - Validacion de auto-dismiss en navegacion
   - Pruebas de overlay queue cuando hay muchos
   - Memory profiling de overlays no cerrados
   - Tests de accessibility en overlays
