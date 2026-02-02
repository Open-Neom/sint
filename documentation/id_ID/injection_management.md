# Manajemen Injeksi

Manajemen dependency injection SINT membuat aplikasi Anda lebih modular, testable, dan mudah dipelihara dengan memisahkan pembuatan objek dari penggunaannya.

## Daftar Isi

- [Metode Injeksi](#metode-injeksi)
- [Bindings](#bindings)
- [SmartManagement](#smartmanagement)
- [Best Practices](#best-practices)
- [Peta Pengujian](#peta-pengujian)

## Metode Injeksi

### Sint.put()

Menyuntikkan dependency dan membuatnya tersedia secara global:

```dart
class HomeController extends SintController {
  var count = 0;
  void increment() => count++;
}

// Injeksi
Sint.put(HomeController());

// Penggunaan
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Sint.find<HomeController>();
    return Text('Count: ${controller.count}');
  }
}
```

#### Parameter Put

```dart
Sint.put(
  HomeController(),
  permanent: true, // Instance tidak akan dihapus
  tag: 'uniqueTag', // Identifier unik untuk multiple instances
);
```

### Sint.lazyPut()

Menyuntikkan dependency yang hanya akan dibuat saat pertama kali digunakan:

```dart
Sint.lazyPut(() => HomeController());

// Controller dibuat hanya saat dipanggil pertama kali
final controller = Sint.find<HomeController>();
```

#### Parameter LazyPut

```dart
Sint.lazyPut(
  () => HomeController(),
  fenix: true, // Recreate instance jika sudah dihapus
  tag: 'uniqueTag',
);
```

### Sint.putAsync()

Untuk dependency yang memerlukan operasi async:

```dart
Sint.putAsync<DatabaseService>(() async {
  final service = DatabaseService();
  await service.init();
  return service;
});

// Tunggu sampai ready
await Sint.isRegistered<DatabaseService>();
```

### Sint.create()

Membuat instance baru setiap kali dipanggil:

```dart
Sint.create(() => FormController());

// Setiap kali find dipanggil, instance baru dibuat
final controller1 = Sint.find<FormController>();
final controller2 = Sint.find<FormController>();
// controller1 != controller2
```

### Sint.find()

Mengambil dependency yang sudah disuntikkan:

```dart
final controller = Sint.find<HomeController>();

// Dengan tag
final taggedController = Sint.find<HomeController>(tag: 'uniqueTag');
```

### Sint.delete()

Menghapus dependency dari memori:

```dart
Sint.delete<HomeController>();

// Dengan tag
Sint.delete<HomeController>(tag: 'uniqueTag');

// Force delete meskipun permanent
Sint.delete<HomeController>(force: true);
```

### Sint.reset()

Menghapus semua instances:

```dart
Sint.reset();

// Hapus hanya yang tidak permanent
Sint.reset(clearRouteBindings: false);
```

## Bindings

Bindings memungkinkan Anda mengorganisir dependencies dan menginjeksinya secara otomatis saat route dibuka.

### Membuat Binding

```dart
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Sint.lazyPut(() => HomeController());
    Sint.lazyPut(() => HomeService());
    Sint.put(HomeRepository());
  }
}
```

### Menggunakan Bindings dengan Routes

```dart
SintMaterialApp(
  initialRoute: '/home',
  getPages: [
    GetPage(
      name: '/home',
      page: () => HomePage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: '/details',
      page: () => DetailsPage(),
      binding: DetailsBinding(),
    ),
  ],
);
```

### Multiple Bindings

```dart
GetPage(
  name: '/complex',
  page: () => ComplexPage(),
  bindings: [
    UserBinding(),
    SettingsBinding(),
    AnalyticsBinding(),
  ],
);
```

### BindingsBuilder

Untuk binding sederhana tanpa membuat class:

```dart
GetPage(
  name: '/simple',
  page: () => SimplePage(),
  binding: BindingsBuilder(() {
    Sint.lazyPut(() => SimpleController());
  }),
);
```

### Global Bindings

Dependencies yang tersedia di semua routes:

```dart
SintMaterialApp(
  initialBinding: BindingsBuilder(() {
    Sint.put(AuthService());
    Sint.put(ThemeController());
    Sint.put(LanguageController());
  }),
  getPages: [...],
);
```

## SmartManagement

Mengontrol bagaimana dependencies dikelola secara otomatis:

### SmartManagement.full (Default)

```dart
SintMaterialApp(
  smartManagement: SmartManagement.full,
);
```

- Dispose controllers yang tidak digunakan di route yang tidak sedang ditampilkan
- Memory efficient untuk aplikasi besar

### SmartManagement.onlyBuilder

```dart
SintMaterialApp(
  smartManagement: SmartManagement.onlyBuilder,
);
```

- Hanya dispose controllers yang dibuat dengan `SintBuilder`, `GetX`, atau `Obx`
- Controllers yang di-inject dengan `Sint.put()` tidak akan di-dispose

### SmartManagement.keepFactory

```dart
SintMaterialApp(
  smartManagement: SmartManagement.keepFactory,
);
```

- Sama seperti `onlyBuilder`, tapi factory yang dibuat dengan `Sint.lazyPut()` tidak dihapus
- Instance dihapus, tapi factory tetap ada untuk membuat instance baru

## Best Practices

### 1. Gunakan LazyPut untuk Performa

```dart
// Baik - Lazy initialization
Sint.lazyPut(() => HeavyController());

// Buruk - Immediate initialization jika tidak diperlukan
Sint.put(HeavyController());
```

### 2. Organisir dengan Bindings

```dart
// Baik - Terorganisir dan mudah dipelihara
class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Sint.lazyPut(() => ProfileController());
    Sint.lazyPut(() => ProfileRepository());
    Sint.lazyPut(() => ImageUploadService());
  }
}

// Buruk - Hard-coded di widget
class ProfilePage extends StatelessWidget {
  ProfilePage() {
    Sint.put(ProfileController());
    Sint.put(ProfileRepository());
  }
}
```

### 3. Tag untuk Multiple Instances

```dart
// Multiple instances dari controller yang sama
Sint.put(TabController(), tag: 'tab1');
Sint.put(TabController(), tag: 'tab2');

// Gunakan tag untuk mengambil
final tab1 = Sint.find<TabController>(tag: 'tab1');
final tab2 = Sint.find<TabController>(tag: 'tab2');
```

### 4. Dispose Dengan Benar

```dart
class MyController extends SintController {
  final StreamSubscription subscription;

  MyController(this.subscription);

  @override
  void onClose() {
    subscription.cancel();
    super.onClose();
  }
}
```

### 5. Async Initialization

```dart
class DatabaseController extends SintController {
  Database? db;

  @override
  void onInit() async {
    super.onInit();
    db = await openDatabase('app.db');
  }
}

// Gunakan putAsync
Sint.putAsync<DatabaseController>(() async {
  final controller = DatabaseController();
  await controller.onInit();
  return controller;
});
```

## Dependency Injection Patterns

### Constructor Injection

```dart
class UserController extends SintController {
  final UserRepository repository;

  UserController(this.repository);

  void loadUser() {
    repository.getUser();
  }
}

// Binding
class UserBinding extends Bindings {
  @override
  void dependencies() {
    Sint.lazyPut(() => UserRepository());
    Sint.lazyPut(() => UserController(Sint.find()));
  }
}
```

### Service Locator Pattern

```dart
class ApiService {
  static ApiService get instance => Sint.find<ApiService>();

  Future<User> getUser() async {
    // ...
  }
}

// Gunakan di mana saja
final user = await ApiService.instance.getUser();
```

### Factory Pattern

```dart
Sint.create(() => FormValidator());

// Setiap form mendapat validator baru
class LoginForm extends StatelessWidget {
  final validator = Sint.find<FormValidator>();
}

class RegisterForm extends StatelessWidget {
  final validator = Sint.find<FormValidator>();
}
```

## Peta Pengujian

### Unit Tests

```dart
test('Sint.put stores and retrieves instance', () {
  final controller = HomeController();
  Sint.put(controller);

  final found = Sint.find<HomeController>();
  expect(found, controller);

  Sint.delete<HomeController>();
});

test('Sint.lazyPut creates instance on first access', () {
  var createCount = 0;

  Sint.lazyPut(() {
    createCount++;
    return HomeController();
  });

  expect(createCount, 0); // Belum dibuat

  final controller = Sint.find<HomeController>();
  expect(createCount, 1); // Dibuat saat pertama kali find

  final controller2 = Sint.find<HomeController>();
  expect(createCount, 1); // Tidak dibuat lagi, menggunakan instance yang sama

  Sint.delete<HomeController>();
});

test('Sint.create generates new instance each time', () {
  Sint.create(() => HomeController());

  final instance1 = Sint.find<HomeController>();
  final instance2 = Sint.find<HomeController>();

  expect(instance1 == instance2, false);

  Sint.delete<HomeController>();
});
```

### Widget Tests

```dart
testWidgets('Widget can access injected controller', (tester) async {
  final controller = HomeController();
  Sint.put(controller);

  await tester.pumpWidget(
    MaterialApp(home: HomePage()),
  );

  expect(find.text('Count: 0'), findsOneWidget);

  Sint.delete<HomeController>();
});

testWidgets('Binding injects dependencies automatically', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(
      initialRoute: '/home',
      getPages: [
        GetPage(
          name: '/home',
          page: () => HomePage(),
          binding: HomeBinding(),
        ),
      ],
    ),
  );

  await tester.pumpAndSettle();

  // Controller harus sudah diinjeksi oleh binding
  expect(Sint.isRegistered<HomeController>(), true);
});
```

### Mock Injection Tests

```dart
class MockRepository extends Mock implements UserRepository {}

test('Controller works with mocked repository', () {
  final mockRepo = MockRepository();
  Sint.put<UserRepository>(mockRepo);

  when(mockRepo.getUser()).thenAnswer((_) async => User(name: 'Test'));

  final controller = UserController(Sint.find());

  controller.loadUser();

  verify(mockRepo.getUser()).called(1);

  Sint.delete<UserRepository>();
});
```

### Integration Tests

```dart
testWidgets('Full app with dependency injection flow', (tester) async {
  await tester.pumpWidget(MyApp());

  // Navigate ke halaman yang menggunakan binding
  await tester.tap(find.text('Go to Profile'));
  await tester.pumpAndSettle();

  // Verify binding menginjeksi dependencies
  expect(Sint.isRegistered<ProfileController>(), true);

  // Navigate kembali
  await tester.pageBack();
  await tester.pumpAndSettle();

  // Dengan SmartManagement.full, controller harus di-dispose
  expect(Sint.isRegistered<ProfileController>(), false);
});
```

### Async Dependency Tests

```dart
test('putAsync waits for initialization', () async {
  Sint.putAsync<DatabaseService>(() async {
    await Future.delayed(Duration(milliseconds: 100));
    return DatabaseService();
  });

  expect(Sint.isRegistered<DatabaseService>(), false);

  await Future.delayed(Duration(milliseconds: 150));

  expect(Sint.isRegistered<DatabaseService>(), true);

  Sint.delete<DatabaseService>();
});
```

### Memory Leak Tests

```dart
test('Controllers are disposed properly', () {
  var disposeCallCount = 0;

  class TestController extends SintController {
    @override
    void onClose() {
      disposeCallCount++;
      super.onClose();
    }
  }

  Sint.put(TestController());
  Sint.delete<TestController>();

  expect(disposeCallCount, 1);
});
```
