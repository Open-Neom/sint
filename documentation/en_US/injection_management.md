# Injection Management

- [Instancing methods](#instancing-methods)
  - [Sint.put()](#sintput)
  - [Sint.lazyPut()](#sintlazyput)
  - [Sint.putAsync()](#sintputasync)
  - [Sint.create()](#sintcreate)
- [Using instances](#using-instances)
- [Replacing instances](#replacing-instances)
- [Bindings](#bindings)
  - [Bindings class](#bindings-class)
  - [BindingsBuilder](#bindingsbuilder)
- [SmartManagement](#smartmanagement)
- [Test Roadmap](#test-roadmap)

---

SINT's **Injection** pillar provides a lightweight dependency injection system. Register, retrieve, and dispose of instances without `context`, `Provider`, or `InheritedWidget`.

---

## Instancing methods

### Sint.put()

Register an instance immediately:

```dart
Sint.put<AuthController>(AuthController());
Sint.put<ApiService>(ApiService(), permanent: true);
Sint.put<ItemController>(ItemController(), tag: 'unique-tag');
```

Parameters:
- `permanent: false` — set `true` to keep alive throughout the app
- `tag` — unique string to differentiate multiple instances of the same type

### Sint.lazyPut()

Register a factory that creates the instance on first use:

```dart
Sint.lazyPut<ApiService>(() => ApiService());
Sint.lazyPut<Controller>(() => Controller(), fenix: true);
```

With `fenix: true`, the instance is recreated if disposed and requested again.

### Sint.putAsync()

Register an asynchronous instance:

```dart
Sint.putAsync<SharedPreferences>(() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs;
});
```

### Sint.create()

Create a new instance every time `Sint.find()` is called:

```dart
Sint.create<ItemController>(() => ItemController());
```

Useful for list items that each need their own controller.

---

## Using instances

Retrieve a registered instance anywhere:

```dart
final controller = Sint.find<AuthController>();
// or
AuthController controller = Sint.find();
```

Delete when no longer needed (usually handled automatically):

```dart
Sint.delete<AuthController>();
```

---

## Replacing instances

Replace a registered instance with a different one:

```dart
Sint.put<BaseService>(ParentService());
Sint.replace<BaseService>(ChildService());

final instance = Sint.find<BaseService>();
print(instance is ChildService); // true
```

---

## Bindings

Organize dependency registration per route.

### Bindings class

```dart
class HomeBinding implements Bindings {
  @override
  void dependencies() {
    Sint.lazyPut<HomeController>(() => HomeController());
    Sint.put<ApiService>(ApiService());
  }
}
```

```dart
getPages: [
  SintPage(
    name: '/',
    page: () => HomeView(),
    binding: HomeBinding(),
  ),
]
```

### BindingsBuilder

Inline alternative:

```dart
SintPage(
  name: '/',
  page: () => HomeView(),
  binding: BindingsBuilder(() {
    Sint.lazyPut<HomeController>(() => HomeController());
  }),
)
```

When a route is removed from the stack, all controllers bound to it are automatically disposed.

---

## SmartManagement

Controls how SINT disposes unused instances:

| Mode | Behavior |
|---|---|
| `SmartManagement.full` (default) | Disposes unused instances automatically |
| `SmartManagement.onlyBuilder` | Only disposes instances started via `init:` or `lazyPut` |
| `SmartManagement.keepFactory` | Keeps the factory, recreates on demand |

```dart
SintMaterialApp(
  smartManagement: SmartManagement.full,
  home: Home(),
)
```

---

## Test Roadmap

Tests for Injection are retained from the original GetX test suite. Future enhancements:

- **Module-aware DI scopes** aligned with `neom_modules/` boundaries
- **Lazy module loading** with Flutter deferred imports
- **Simplified mock injection** for unit testing across 21+ modules
- Lifecycle tests: `put` → `find` → `delete` → verify disposal
- `fenix` recreation tests
- Tag-based instance isolation tests
- Bindings auto-disposal on route change
