# Injection Management (Pillar I)

- [Contract-First DI (`Bind.contract` & `Sint.contract`)](#contract-first-di-bindcontract--sintcontract)
- [Declarative Route & Root Bindings (`Binds` / `MultiBinder`)](#declarative-route--root-bindings-binds--multibinder)
- [Imperative Registration (`put`, `lazyPut`, `putAsync`, `create`)](#imperative-registration-put-lazyput-putasync-create)
- [Scoped Overrides & Testing (`SintScope`)](#scoped-overrides--testing-sintscope)
- [Retrieving & Replacing Instances](#retrieving--replacing-instances)
- [SmartManagement & Lifecycle](#smartmanagement--lifecycle)
- [Runtime Inspection (`Sint.diagnostics`)](#runtime-inspection-sintdiagnostics)

---

SINT's **Injection** pillar is a reified `Type`-keyed dependency container (100% safe under Web/Wasm minification) with `O(1)` lookups (~47M lookups/sec), circular dependency detection, and deterministic `O(M)` route-bound disposal.

---

## Contract-First DI (`Bind.contract` & `Sint.contract`)

In Clean Architecture, domain interfaces (`AuthService`) are separated from concrete implementations (`AuthController extends SintController implements AuthService`). Bind both to a single shared factory in one line:

```dart
// Declarative (inside SintApp / SintPage / Binds):
Bind.contract<AuthService, AuthController>(
  () => AuthController(),
  aliases: [SessionManageable], // Optional extra interfaces
  fenix: true,
)

// Eager / Imperative:
Sint.contract<AuthService, AuthController>(() => AuthController(), fenix: true);
Sint.putContract<AuthService, AuthController>(AuthController());
await Sint.putContractAsync<AuthService, AuthController>(() async => AuthController());
```

Both `Sint.find<AuthService>()` and `Sint.find<AuthController>()` return the exact same instance and share a single lifecycle.

> **Multi-implementation lookup**: Register multiple tagged implementations of `S` and retrieve them via `Sint.findAll<S>()` or `Sint.findAt<S>(index)`.

---

## Declarative Route & Root Bindings (`Binds` / `MultiBinder`)

`Binds` flattens any number of declarative bindings into **1 single `MultiBindElement` (`InheritedModel<Type>`)** — eliminating deep nested `InheritedWidget` trees (`O(1)` widget depth):

```dart
SintApp(
  materialTheme: ThemeData(),
  initialRoute: '/',
  binds: [
    Bind.put<LoggerService>(LoggerService()), // SintService => permanent by default
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

> **Important**: `Bind.put` takes an **instance** (`Bind.put(MyController())`), never a factory closure (`Bind.put(() => MyController())`). Use `Bind.lazyPut(() => MyController())` for lazy factories.

---

## Imperative Registration (`put`, `lazyPut`, `putAsync`, `create`)

```dart
// Immediate singleton
Sint.put<AuthController>(AuthController());
Sint.put<ApiService>(ApiService(), permanent: true);
Sint.put<ItemController>(ItemController(), tag: 'unique-tag');

// Lazy singleton (created on first Sint.find)
Sint.lazyPut<ApiService>(() => ApiService(), fenix: true);

// Asynchronous singleton
await Sint.putAsync<LocalStore>(() async => LocalStore.open());

// Fresh instance on every Sint.find
Sint.create<RowController>(() => RowController());
```

`SintService` subclasses default to `permanent: true` and stay alive across route changes until explicitly deleted or reset.

---

## Scoped Overrides & Testing (`SintScope`)

Override dependencies for a widget subtree or unit test without mutating SINT's global registry. Any `SintController` / `SintService` created in a scope automatically receives `onClose()` when the scope exits:

```dart
// Headless unit test:
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

// Widget subtree (supports side-by-side sibling scopes):
SintScope(
  overrides: [
    SintOverride.value<AuthService>(FakeAuthService()),
  ],
  child: const LoginPage(),
)
```

---

## Retrieving & Replacing Instances

```dart
final auth = Sint.find<AuthService>();
final optional = Sint.findOrNull<AnalyticsService>();
final ctrl = Sint.findOrPut<SessionController>(() => SessionController());
final plugins = Sint.findAll<AudioPlugin>();

// Replace an existing binding cleanly:
Sint.replace<AuthService>(CustomAuthService());

// Manual deletion (normally handled automatically on route pop):
Sint.delete<AuthController>();
```

Circular dependencies (e.g. `A` depends on `B` which depends on `A`) fail fast with a descriptive `StateError` showing the exact resolution cycle.

---

## SmartManagement & Lifecycle

| Mode | Behavior |
| --- | --- |
| `SmartManagement.full` (default) | Disposes route-bound non-permanent controllers automatically on route pop (`O(M)`). |
| `SmartManagement.onlyBuilder` | Disposes only instances created by route bindings or `lazyPut`. |
| `SmartManagement.keepFactory` | Disposes instances on route pop while preserving lazy factories for automatic recreation. |

---

## Runtime Inspection (`Sint.diagnostics`)

```dart
final diSnapshot = Sint.diagnostics.dependenciesSnapshot();
// Reports count, activeScopes, and per-binding type/tag/permanent/fenix/initialized/instantiated flags.
```
