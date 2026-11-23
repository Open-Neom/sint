# Inyección de Dependencias (Pilar I)

- [Inyección Contract-First (`Bind.contract` y `Sint.contract`)](#inyección-contract-first-bindcontract-y-sintcontract)
- [Bindings Declarativos (`Binds` / `MultiBinder`)](#bindings-declarativos-binds--multibinder)
- [Registro Imperativo (`put`, `lazyPut`, `putAsync`, `create`)](#registro-imperativo-put-lazyput-putasync-create)
- [Sobrescritura con Scope y Testing (`SintScope`)](#sobrescritura-con-scope-y-testing-sintscope)
- [Recuperación, Reemplazo y SmartManagement](#recuperación-reemplazo-y-smartmanagement)
- [Inspección en Tiempo de Ejecución (`Sint.diagnostics`)](#inspección-en-tiempo-de-ejecución-sintdiagnostics)

---

El pilar **Injection** de SINT utiliza un contenedor indexado por `Type` reificado (100% seguro ante minificación Web/Wasm) con búsquedas en `O(1)` (~47M/seg), detección de dependencias circulares y liberación determinística `O(M)` ligada al ciclo de vida de cada ruta.

---

## Inyección Contract-First (`Bind.contract` y `Sint.contract`)

En Clean Architecture, vincula la interfaz de dominio (`AuthService`) y su controlador concreto (`AuthController extends SintController implements AuthService`) a una sola fábrica compartida:

```dart
// Declarativo (dentro de SintApp / SintPage / Binds):
Bind.contract<AuthService, AuthController>(
  () => AuthController(),
  aliases: [SessionManageable],
  fenix: true,
)

// Imperativo / Asíncrono:
Sint.contract<AuthService, AuthController>(() => AuthController(), fenix: true);
Sint.putContract<AuthService, AuthController>(AuthController());
await Sint.putContractAsync<AuthService, AuthController>(() async => AuthController());
```

Tanto `Sint.find<AuthService>()` como `Sint.find<AuthController>()` devuelven exactamente la misma instancia. Para múltiples implementaciones etiquetadas, usa `Sint.findAll<S>()` o `Sint.findAt<S>(index)`.

---

## Bindings Declarativos (`Binds` / `MultiBinder`)

`Binds` colapsa cualquier número de registros declarativos en **1 único `MultiBindElement` (`InheritedModel<Type>`)** (`O(1)` de profundidad en el árbol de widgets):

```dart
SintApp(
  materialTheme: ThemeData(),
  initialRoute: '/',
  binds: [
    Bind.put<LoggerService>(LoggerService()), // SintService => permanent: true por defecto
    Bind.contract<AuthService, AuthController>(() => AuthController(), fenix: true),
  ],
  sintPages: [
    SintPage(
      name: '/profile',
      binds: [
        Bind.lazyPut<ProfileController>(() => ProfileController()),
      ],
      page: () => const ProfileView(),
    ),
  ],
)
```

> **Importante**: `Bind.put` recibe una **instancia** (`Bind.put(MyController())`), nunca una función fábrica (`Bind.put(() => MyController())`). Usa `Bind.lazyPut(() => MyController())` para fábricas perezosas.

---

## Registro Imperativo (`put`, `lazyPut`, `putAsync`, `create`)

```dart
Sint.put<AuthController>(AuthController());
Sint.put<ApiService>(ApiService(), permanent: true);
Sint.put<ItemController>(ItemController(), tag: 'unique-tag');
Sint.lazyPut<ApiService>(() => ApiService(), fenix: true);
await Sint.putAsync<LocalStore>(() async => LocalStore.open());
Sint.create<RowController>(() => RowController());
```

---

## Sobrescritura con Scope y Testing (`SintScope`)

```dart
// Test headless sin mutar el registro global:
await SintScope.run(
  overrides: [
    SintOverride.contract<AuthService, FakeAuthController>(
      () => FakeAuthController(),
    ),
  ],
  body: () async {
    expect(Sint.find<AuthService>().isLoggedIn, isTrue);
  },
);

// Subárbol de widgets (soporta scopes hermanos en el mismo frame):
SintScope(
  overrides: [
    SintOverride.value<AuthService>(FakeAuthService()),
  ],
  child: const LoginPage(),
)
```

---

## Recuperación, Reemplazo y SmartManagement

```dart
final auth = Sint.find<AuthService>();
final optional = Sint.findOrNull<AnalyticsService>();
final ctrl = Sint.findOrPut<SessionController>(() => SessionController());
Sint.replace<AuthService>(CustomAuthService());
Sint.delete<AuthController>();
```

| Modo | Comportamiento |
| --- | --- |
| `SmartManagement.full` (defecto) | Libera automáticamente controladores no permanentes al salir de su ruta (`O(M)`). |
| `SmartManagement.onlyBuilder` | Solo libera instancias creadas por bindings o `lazyPut`. |
| `SmartManagement.keepFactory` | Libera la instancia al salir de la ruta preservando la fábrica perezosa. |

---

## Inspección en Tiempo de Ejecución (`Sint.diagnostics`)

```dart
final diSnapshot = Sint.diagnostics.dependenciesSnapshot();
```
