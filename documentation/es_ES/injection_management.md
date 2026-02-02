# Gestion de Inyeccion

La **Inyeccion de Dependencias** en SINT permite gestionar instancias de controllers, services y otras clases de manera eficiente y desacoplada.

## Tabla de Contenidos

- [Conceptos Basicos](#conceptos-basicos)
- [Metodos de Inyeccion](#metodos-de-inyeccion)
  - [Sint.put](#sintput)
  - [Sint.lazyPut](#sintlazyput)
  - [Sint.putAsync](#sintputasync)
  - [Sint.create](#sintcreate)
- [Recuperar Dependencias](#recuperar-dependencias)
  - [Sint.find](#sintfind)
- [Bindings](#bindings)
  - [Binding Class](#binding-class)
  - [BindingsBuilder](#bindingsbuilder)
  - [SmartManagement](#smartmanagement)
- [Ciclo de Vida](#ciclo-de-vida)
- [Best Practices](#best-practices)
- [Test Roadmap](#test-roadmap)

---

## Conceptos Basicos

SINT gestiona el ciclo de vida completo de tus dependencias:

- **Inyeccion**: Registra instancias en el contenedor de DI
- **Localizacion**: Recupera instancias cuando las necesites
- **Disposal**: Limpia recursos automaticamente

```dart
// Inyectar
Sint.put(UserController());

// Usar
final controller = Sint.find<UserController>();

// No necesitas eliminar manualmente - SINT lo gestiona
```

---

## Metodos de Inyeccion

### Sint.put

Instancia la clase **inmediatamente** y la registra:

```dart
class HomeController extends SintController {
  var count = 0;

  void increment() => count++;
}

// En tu codigo
void main() {
  Sint.put(HomeController());
  runApp(MyApp());
}
```

**Parametros opcionales:**

```dart
Sint.put<UserService>(
  UserService(),
  permanent: true,  // Nunca se elimina automaticamente
  tag: 'adminUser', // Identificador unico para multiples instancias
);
```

**Uso con tag:**

```dart
Sint.put(ApiController(), tag: 'v1');
Sint.put(ApiController(), tag: 'v2');

// Recuperar
final controllerV1 = Sint.find<ApiController>(tag: 'v1');
final controllerV2 = Sint.find<ApiController>(tag: 'v2');
```

### Sint.lazyPut

Instancia la clase **solo cuando se use por primera vez**:

```dart
Sint.lazyPut<DatabaseService>(() => DatabaseService());

// La instancia NO se crea hasta que hagas:
final db = Sint.find<DatabaseService>(); // AQUI se instancia
```

**Ventajas:**
- Reduce consumo de memoria inicial
- Ideal para dependencias pesadas que no siempre se usan

**Parametros:**

```dart
Sint.lazyPut<HeavyService>(
  () => HeavyService(),
  fenix: true, // Se recrea automaticamente si se elimina y se vuelve a usar
);
```

### Sint.putAsync

Para dependencias que requieren **inicializacion asincrona**:

```dart
class StorageService extends SintController {
  late SharedPreferences prefs;

  Future<StorageService> init() async {
    prefs = await SharedPreferences.getInstance();
    return this;
  }
}

// Inyectar
void main() async {
  await Sint.putAsync<StorageService>(() async {
    final service = StorageService();
    await service.init();
    return service;
  });

  runApp(MyApp());
}
```

**Uso tipico:**
- Inicializar base de datos
- Cargar configuracion remota
- Establecer conexiones de red

### Sint.create

Crea una **nueva instancia cada vez** que se llama a `Sint.find`:

```dart
Sint.create<FormController>(() => FormController());

// Cada llamada devuelve una instancia diferente
final form1 = Sint.find<FormController>(); // Instancia 1
final form2 = Sint.find<FormController>(); // Instancia 2 (diferente)
```

**Caso de uso:**
- Controllers que necesitan estado aislado
- Formularios dinamicos
- Widgets que requieren instancias independientes

---

## Recuperar Dependencias

### Sint.find

Recupera una instancia previamente inyectada:

```dart
final controller = Sint.find<UserController>();
```

**Con tag:**

```dart
final admin = Sint.find<AuthController>(tag: 'admin');
```

**Verificar si existe:**

```dart
if (Sint.isRegistered<SettingsController>()) {
  final settings = Sint.find<SettingsController>();
}
```

**Eliminar dependencias:**

```dart
// Eliminar instancia especifica
Sint.delete<CacheController>();

// Eliminar con tag
Sint.delete<ApiController>(tag: 'v1');

// Forzar eliminacion (incluso si es permanent)
Sint.delete<DatabaseService>(force: true);

// Resetear todo el sistema de DI
Sint.reset();
```

---

## Bindings

Los **Bindings** agrupan la inyeccion de dependencias relacionadas con una ruta o modulo.

### Binding Class

```dart
class HomeBinding implements Bindings {
  @override
  void dependencies() {
    Sint.lazyPut<HomeController>(() => HomeController());
    Sint.lazyPut<NetworkService>(() => NetworkService());
    Sint.put<CacheService>(CacheService());
  }
}

// Usar con rutas nombradas
SintMaterialApp(
  initialRoute: '/home',
  getPages: [
    GetPage(
      name: '/home',
      page: () => HomeView(),
      binding: HomeBinding(),
    ),
  ],
)
```

### BindingsBuilder

Para bindings simples sin crear una clase:

```dart
GetPage(
  name: '/profile',
  page: () => ProfileView(),
  binding: BindingsBuilder(() {
    Sint.lazyPut<ProfileController>(() => ProfileController());
    Sint.lazyPut<StorageService>(() => StorageService());
  }),
)
```

**Multiples Bindings:**

```dart
GetPage(
  name: '/dashboard',
  page: () => DashboardView(),
  bindings: [
    DashboardBinding(),
    AnalyticsBinding(),
    NotificationBinding(),
  ],
)
```

### SmartManagement

Controla **cuando** se eliminan las dependencias automaticamente:

```dart
SintMaterialApp(
  smartManagement: SmartManagement.full, // Default
)
```

**Modos disponibles:**

| Modo | Descripcion |
|------|-------------|
| `full` | Elimina controllers cuando la ruta asociada se destruye (default) |
| `onlyBuilder` | Solo elimina controllers creados con `SintBuilder` |
| `keepFactory` | Mantiene factories (de `lazyPut`) incluso si la ruta se elimina |

**Ejemplo:**

```dart
// Con SmartManagement.full (default)
Sint.to(DetailPage()); // HomeController se elimina al navegar
Sint.back(); // DetailController se elimina al volver

// Con SmartManagement.keepFactory
Sint.to(DetailPage()); // HomeController NO se elimina
// La factory se mantiene para reconstruir rapidamente si vuelves
```

---

## Ciclo de Vida

Los controllers tienen metodos de ciclo de vida:

```dart
class LifecycleController extends SintController {
  @override
  void onInit() {
    super.onInit();
    print('Controller inicializado');
    // Cargar datos iniciales
  }

  @override
  void onReady() {
    super.onReady();
    print('Controller listo (despues del primer frame)');
    // Acciones que requieren que la UI este lista
  }

  @override
  void onClose() {
    print('Controller eliminado');
    // Limpiar recursos, cerrar streams, etc.
    super.onClose();
  }
}
```

**Orden de ejecucion:**

1. Constructor
2. `onInit()` - Inmediatamente despues de crear la instancia
3. `onReady()` - Despues del primer frame (cuando la UI esta lista)
4. `onClose()` - Cuando el controller se elimina del sistema de DI

**SintController:**

Para servicios que nunca deben eliminarse:

```dart
class ApiService extends SintController {
  @override
  void onInit() {
    super.onInit();
    print('ApiService iniciado');
  }

  Future<ApiService> init() async {
    // Inicializacion asincrona
    return this;
  }
}

// Inyectar
await Sint.putAsync(() => ApiService().init());

// SintController NUNCA se elimina automaticamente
```

---

## Best Practices

### 1. Usa lazyPut por defecto

```dart
// BIEN - Instancia solo cuando se necesita
Sint.lazyPut<Controller>(() => Controller());

// MAL - Instancia inmediatamente (puede ser innecesario)
Sint.put(Controller());
```

### 2. Usa Bindings para organizar dependencias

```dart
// BIEN - Dependencias organizadas por modulo
class ShopBinding implements Bindings {
  @override
  void dependencies() {
    Sint.lazyPut<CartController>(() => CartController());
    Sint.lazyPut<ProductService>(() => ProductService());
  }
}

// MAL - Inyeccion desorganizada en main()
void main() {
  Sint.put(CartController());
  Sint.put(ProductService());
  Sint.put(CheckoutController());
  // ...
}
```

### 3. Usa permanent para servicios globales

```dart
// Servicios que viven toda la app
Sint.put<AuthService>(AuthService(), permanent: true);
Sint.put<ThemeService>(ThemeService(), permanent: true);
```

### 4. Limpia recursos en onClose

```dart
class StreamController extends SintController {
  final StreamController<int> _stream = StreamController();

  @override
  void onClose() {
    _stream.close(); // IMPORTANTE
    super.onClose();
  }
}
```

### 5. Usa tags para multiples instancias

```dart
// Multiples temas
Sint.put(ThemeController(), tag: 'light');
Sint.put(ThemeController(), tag: 'dark');

// Multiples APIs
Sint.put(ApiClient(baseUrl: 'prod.api.com'), tag: 'production');
Sint.put(ApiClient(baseUrl: 'dev.api.com'), tag: 'development');
```

---

## Test Roadmap

### Pruebas Planificadas - Pilar de Inyeccion

1. **DI por Modulo**
   - Tests de aislamiento entre modulos
   - Validacion de namespace collision con tags
   - Pruebas de lazy loading con multiples modulos
   - Verificacion de orden de inicializacion entre modulos

2. **Carga Lazy con Deferred Imports**
   - Integracion de Sint.lazyPut con deferred imports
   - Tests de code splitting automatico por ruta
   - Validacion de memoria pre/post carga diferida
   - Pruebas de fallback cuando falla carga diferida

3. **Mock Injection Simplificado**
   - Sistema de mocking para tests unitarios
   - Swap de implementaciones en runtime (dev/prod)
   - Tests de inyeccion de fakes para testing
   - Validacion de reset completo entre tests

4. **SmartManagement Avanzado**
   - Tests de cada modo de SmartManagement
   - Validacion de memory leaks con permanent: true
   - Pruebas de disposal en navegacion compleja
   - Benchmarks de performance por modo

5. **Bindings Performance**
   - Medicion de overhead de Bindings vs put manual
   - Tests de lazy vs eager binding initialization
   - Validacion de dependencias circulares
   - Pruebas de hot reload con Bindings activos

6. **SintController Lifecycle**
   - Tests de persistencia entre reconstrucciones
   - Validacion de init asincrono completo
   - Pruebas de recovery en errores de inicializacion
   - Verificacion de singleton garantizado
