# Управление внедрением зависимостей

Управление внедрением зависимостей SINT делает ваше приложение более модульным, тестируемым и удобным в обслуживании, отделяя создание объектов от их использования.

## Содержание

- [Методы внедрения](#методы-внедрения)
- [Bindings](#bindings)
- [SmartManagement](#smartmanagement)
- [Лучшие практики](#лучшие-практики)
- [Дорожная карта тестирования](#дорожная-карта-тестирования)

## Методы внедрения

### Sint.put()

Внедряет зависимость и делает её доступной глобально:

```dart
class HomeController extends SintController {
  var count = 0;
  void increment() => count++;
}

// Внедрение
Sint.put(HomeController());

// Использование
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Sint.find<HomeController>();
    return Text('Счет: ${controller.count}');
  }
}
```

#### Параметры Put

```dart
Sint.put(
  HomeController(),
  permanent: true, // Экземпляр не будет удален
  tag: 'uniqueTag', // Уникальный идентификатор для нескольких экземпляров
);
```

### Sint.lazyPut()

Внедряет зависимость, которая будет создана только при первом использовании:

```dart
Sint.lazyPut(() => HomeController());

// Контроллер создается только при первом вызове
final controller = Sint.find<HomeController>();
```

#### Параметры LazyPut

```dart
Sint.lazyPut(
  () => HomeController(),
  fenix: true, // Пересоздать экземпляр, если он был удален
  tag: 'uniqueTag',
);
```

### Sint.putAsync()

Для зависимостей, требующих асинхронных операций:

```dart
Sint.putAsync<DatabaseService>(() async {
  final service = DatabaseService();
  await service.init();
  return service;
});

// Ожидание готовности
await Sint.isRegistered<DatabaseService>();
```

### Sint.create()

Создает новый экземпляр при каждом вызове:

```dart
Sint.create(() => FormController());

// Каждый раз при вызове find создается новый экземпляр
final controller1 = Sint.find<FormController>();
final controller2 = Sint.find<FormController>();
// controller1 != controller2
```

### Sint.find()

Получает уже внедренную зависимость:

```dart
final controller = Sint.find<HomeController>();

// С тегом
final taggedController = Sint.find<HomeController>(tag: 'uniqueTag');
```

### Sint.delete()

Удаляет зависимость из памяти:

```dart
Sint.delete<HomeController>();

// С тегом
Sint.delete<HomeController>(tag: 'uniqueTag');

// Принудительное удаление даже если permanent
Sint.delete<HomeController>(force: true);
```

### Sint.reset()

Удаляет все экземпляры:

```dart
Sint.reset();

// Удалить только не permanent
Sint.reset(clearRouteBindings: false);
```

## Bindings

Bindings позволяют организовать зависимости и автоматически внедрять их при открытии маршрута.

### Создание Binding

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

### Использование Bindings с маршрутами

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

### Множественные Bindings

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

Для простых bindings без создания класса:

```dart
GetPage(
  name: '/simple',
  page: () => SimplePage(),
  binding: BindingsBuilder(() {
    Sint.lazyPut(() => SimpleController());
  }),
);
```

### Глобальные Bindings

Зависимости, доступные на всех маршрутах:

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

Контролирует автоматическое управление зависимостями:

### SmartManagement.full (По умолчанию)

```dart
SintMaterialApp(
  smartManagement: SmartManagement.full,
);
```

- Удаляет контроллеры, не используемые на маршруте, который не отображается
- Эффективно использует память для больших приложений

### SmartManagement.onlyBuilder

```dart
SintMaterialApp(
  smartManagement: SmartManagement.onlyBuilder,
);
```

- Удаляет только контроллеры, созданные с `SintBuilder`, `GetX` или `Obx`
- Контроллеры, внедренные с `Sint.put()`, не будут удалены

### SmartManagement.keepFactory

```dart
SintMaterialApp(
  smartManagement: SmartManagement.keepFactory,
);
```

- Как `onlyBuilder`, но фабрики, созданные с `Sint.lazyPut()`, не удаляются
- Экземпляр удаляется, но фабрика остается для создания новых экземпляров

## Лучшие практики

### 1. Используйте LazyPut для производительности

```dart
// Хорошо - Ленивая инициализация
Sint.lazyPut(() => HeavyController());

// Плохо - Немедленная инициализация, если не требуется
Sint.put(HeavyController());
```

### 2. Организуйте с помощью Bindings

```dart
// Хорошо - Организованно и легко поддерживать
class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Sint.lazyPut(() => ProfileController());
    Sint.lazyPut(() => ProfileRepository());
    Sint.lazyPut(() => ImageUploadService());
  }
}

// Плохо - Жестко закодировано в виджете
class ProfilePage extends StatelessWidget {
  ProfilePage() {
    Sint.put(ProfileController());
    Sint.put(ProfileRepository());
  }
}
```

### 3. Теги для множественных экземпляров

```dart
// Множественные экземпляры одного контроллера
Sint.put(TabController(), tag: 'tab1');
Sint.put(TabController(), tag: 'tab2');

// Используйте тег для получения
final tab1 = Sint.find<TabController>(tag: 'tab1');
final tab2 = Sint.find<TabController>(tag: 'tab2');
```

### 4. Правильное удаление

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

### 5. Асинхронная инициализация

```dart
class DatabaseController extends SintController {
  Database? db;

  @override
  void onInit() async {
    super.onInit();
    db = await openDatabase('app.db');
  }
}

// Используйте putAsync
Sint.putAsync<DatabaseController>(() async {
  final controller = DatabaseController();
  await controller.onInit();
  return controller;
});
```

## Паттерны внедрения зависимостей

### Внедрение через конструктор

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

### Паттерн Service Locator

```dart
class ApiService {
  static ApiService get instance => Sint.find<ApiService>();

  Future<User> getUser() async {
    // ...
  }
}

// Используйте везде
final user = await ApiService.instance.getUser();
```

### Паттерн Factory

```dart
Sint.create(() => FormValidator());

// Каждая форма получает новый валидатор
class LoginForm extends StatelessWidget {
  final validator = Sint.find<FormValidator>();
}

class RegisterForm extends StatelessWidget {
  final validator = Sint.find<FormValidator>();
}
```

## Дорожная карта тестирования

### Модульные тесты

```dart
test('Sint.put сохраняет и получает экземпляр', () {
  final controller = HomeController();
  Sint.put(controller);

  final found = Sint.find<HomeController>();
  expect(found, controller);

  Sint.delete<HomeController>();
});

test('Sint.lazyPut создает экземпляр при первом доступе', () {
  var createCount = 0;

  Sint.lazyPut(() {
    createCount++;
    return HomeController();
  });

  expect(createCount, 0); // Еще не создан

  final controller = Sint.find<HomeController>();
  expect(createCount, 1); // Создан при первом find

  final controller2 = Sint.find<HomeController>();
  expect(createCount, 1); // Не создан снова, используется тот же экземпляр

  Sint.delete<HomeController>();
});

test('Sint.create генерирует новый экземпляр каждый раз', () {
  Sint.create(() => HomeController());

  final instance1 = Sint.find<HomeController>();
  final instance2 = Sint.find<HomeController>();

  expect(instance1 == instance2, false);

  Sint.delete<HomeController>();
});
```

### Виджетные тесты

```dart
testWidgets('Виджет может получить доступ к внедренному контроллеру', (tester) async {
  final controller = HomeController();
  Sint.put(controller);

  await tester.pumpWidget(
    MaterialApp(home: HomePage()),
  );

  expect(find.text('Счет: 0'), findsOneWidget);

  Sint.delete<HomeController>();
});

testWidgets('Binding автоматически внедряет зависимости', (tester) async {
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

  // Контроллер должен быть уже внедрен binding
  expect(Sint.isRegistered<HomeController>(), true);
});
```

### Тесты с моками

```dart
class MockRepository extends Mock implements UserRepository {}

test('Контроллер работает с мок-репозиторием', () {
  final mockRepo = MockRepository();
  Sint.put<UserRepository>(mockRepo);

  when(mockRepo.getUser()).thenAnswer((_) async => User(name: 'Тест'));

  final controller = UserController(Sint.find());

  controller.loadUser();

  verify(mockRepo.getUser()).called(1);

  Sint.delete<UserRepository>();
});
```

### Интеграционные тесты

```dart
testWidgets('Полное приложение с внедрением зависимостей', (tester) async {
  await tester.pumpWidget(MyApp());

  // Переход на страницу, использующую binding
  await tester.tap(find.text('Перейти в профиль'));
  await tester.pumpAndSettle();

  // Проверка внедрения зависимостей binding
  expect(Sint.isRegistered<ProfileController>(), true);

  // Возврат назад
  await tester.pageBack();
  await tester.pumpAndSettle();

  // С SmartManagement.full контроллер должен быть удален
  expect(Sint.isRegistered<ProfileController>(), false);
});
```

### Тесты асинхронных зависимостей

```dart
test('putAsync ожидает инициализации', () async {
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

### Тесты утечек памяти

```dart
test('Контроллеры правильно удаляются', () {
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
