# Управление состоянием

SINT предоставляет мощную и гибкую систему управления состоянием для ваших Flutter приложений. С тремя различными подходами вы можете выбрать решение, наиболее подходящее для ваших потребностей.

## Содержание

- [Реактивное управление состоянием](#реактивное-управление-состоянием)
- [Простое управление состоянием](#простое-управление-состоянием)
- [StateMixin](#statemixin)
- [Workers](#workers)
- [Дорожная карта тестирования](#дорожная-карта-тестирования)

## Реактивное управление состоянием

Реактивное управление состоянием использует `Rx` типы и `.obs` для создания наблюдаемых переменных.

### Наблюдаемые переменные

```dart
class Controller extends SintController {
  var count = 0.obs;
  var name = ''.obs;
  var isLogged = false.obs;
  var user = User().obs;
  var list = <String>[].obs;
}
```

### Виджет Obx

Виджет `Obx` автоматически перестраивается при изменении наблюдаемых переменных:

```dart
class CounterPage extends StatelessWidget {
  final Controller controller = Sint.put(Controller());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Obx(() => Text(
          'Значение: ${controller.count}',
          style: TextStyle(fontSize: 24),
        )),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.count++,
        child: Icon(Icons.add),
      ),
    );
  }
}
```

### Виджет GetX

`GetX` - это виджет, объединяющий управление состоянием и внедрение зависимостей:

```dart
GetX<Controller>(
  init: Controller(),
  builder: (controller) {
    return Text('Значение: ${controller.count}');
  },
)
```

### Реактивные типы данных

SINT поддерживает различные реактивные типы данных:

```dart
// Примитивные типы
var myInt = 0.obs;
var myDouble = 0.0.obs;
var myString = ''.obs;
var myBool = false.obs;

// List, Map и Set
var myList = <String>[].obs;
var myMap = <String, int>{}.obs;
var mySet = <int>{}.obs;

// Пользовательские объекты
var myUser = User().obs;

// Доступ к значению
print(myInt.value);
myString.value = 'Привет';
myUser.value = User(name: 'Иван');

// Обновление List
myList.add('элемент');
myList.remove('элемент');

// Обновление Map
myMap['ключ'] = 123;
```

### Метод Update для объектов

Для сложных объектов используйте метод `update()`:

```dart
class User {
  String name;
  int age;
  User({this.name = '', this.age = 0});
}

class Controller extends SintController {
  var user = User().obs;

  void updateUser() {
    user.update((val) {
      val?.name = 'Иван Иванов';
      val?.age = 30;
    });
  }
}
```

## Простое управление состоянием

Для более простых случаев используйте `SintBuilder` без накладных расходов реактивности:

```dart
class Controller extends SintController {
  int count = 0;

  void increment() {
    count++;
    update(); // Вызов update для перестройки UI
  }

  void incrementWithId() {
    count++;
    update(['counter_text']); // Обновление только виджетов с определенным ID
  }
}
```

### Виджет SintBuilder

```dart
SintBuilder<Controller>(
  init: Controller(),
  builder: (controller) {
    return Text('Значение: ${controller.count}');
  },
)
```

### SintBuilder с ID

Для более детального контроля:

```dart
SintBuilder<Controller>(
  id: 'counter_text',
  builder: (controller) {
    return Text('Значение: ${controller.count}');
  },
)

SintBuilder<Controller>(
  id: 'counter_button',
  builder: (controller) {
    return ElevatedButton(
      onPressed: controller.increment,
      child: Text('Увеличить'),
    );
  },
)
```

## StateMixin

`StateMixin` предоставляет способ управления различными состояниями, такими как загрузка, ошибка и успех:

```dart
class UserController extends SintController with StateMixin<User> {
  @override
  void onInit() {
    super.onInit();
    fetchUser();
  }

  void fetchUser() async {
    change(null, status: RxStatus.loading());

    try {
      final user = await api.getUser();
      change(user, status: RxStatus.success());
    } catch (error) {
      change(null, status: RxStatus.error(error.toString()));
    }
  }
}
```

### Использование StateMixin в виджетах

```dart
class UserPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SintBuilder<UserController>(
        builder: (controller) {
          return controller.obx(
            (user) => UserProfile(user: user!),
            onLoading: Center(child: CircularProgressIndicator()),
            onError: (error) => Center(child: Text('Ошибка: $error')),
            onEmpty: Center(child: Text('Нет данных')),
          );
        },
      ),
    );
  }
}
```

### Статусы RxStatus

```dart
RxStatus.loading()
RxStatus.success()
RxStatus.error([String? message])
RxStatus.empty()
```

## Workers

Workers - это реактивные обратные вызовы, которые вызываются при возникновении событий:

### ever

Вызывается каждый раз при изменении переменной:

```dart
class Controller extends SintController {
  var count = 0.obs;

  @override
  void onInit() {
    ever(count, (value) {
      print('Count изменен на $value');
    });
    super.onInit();
  }
}
```

### once

Вызывается только один раз при первом изменении переменной:

```dart
once(count, (value) {
  print('Count изменен впервые: $value');
});
```

### debounce

Вызывается после того, как пользователь прекратил вносить изменения в течение определенного времени:

```dart
debounce(searchQuery, (value) {
  performSearch(value);
}, time: Duration(milliseconds: 800));
```

### interval

Игнорирует изменения в течение определенного периода:

```dart
interval(position, (value) {
  updateLocation(value);
}, time: Duration(seconds: 1));
```

### Отмена Workers

```dart
class Controller extends SintController {
  late Worker countWorker;

  @override
  void onInit() {
    countWorker = ever(count, (value) {
      print('Count: $value');
    });
    super.onInit();
  }

  void stopWorker() {
    countWorker.dispose();
  }

  @override
  void onClose() {
    countWorker.dispose();
    super.onClose();
  }
}
```

## Лучшие практики

### 1. Выберите правильный подход

- Используйте **Reactive** для сложного UI с множеством изменений состояния
- Используйте **Simple** для редко обновляемых виджетов
- Используйте **StateMixin** для асинхронных операций с различными состояниями

### 2. Избегайте вложенных Obx

Не делайте:

```dart
Obx(() => Column(
  children: [
    Obx(() => Text(controller.name.value)), // Плохо
    Obx(() => Text(controller.email.value)), // Плохо
  ],
))
```

Делайте:

```dart
Obx(() => Column(
  children: [
    Text(controller.name.value),
    Text(controller.email.value),
  ],
))
```

### 3. Используйте SintBuilder для статических виджетов

Если виджету не нужны реактивные обновления, не оборачивайте его в Obx:

```dart
// Не делайте
Obx(() => Container(
  color: Colors.blue, // Цвет не меняется
  child: Text(controller.count.value.toString()),
))

// Делайте
Container(
  color: Colors.blue,
  child: Obx(() => Text(controller.count.value.toString())),
)
```

### 4. Удаляйте Workers

Всегда удаляйте workers в `onClose()`:

```dart
@override
void onClose() {
  myWorker.dispose();
  super.onClose();
}
```

## Дорожная карта тестирования

### Модульные тесты

```dart
test('Тест увеличения счетчика', () {
  final controller = Controller();

  // Тест начального значения
  expect(controller.count.value, 0);

  // Тест увеличения
  controller.increment();
  expect(controller.count.value, 1);
});

test('StateMixin состояние загрузки', () {
  final controller = UserController();

  // Проверка начального состояния
  expect(controller.status.isLoading, true);
});
```

### Виджетные тесты

```dart
testWidgets('Виджет Obx обновляется при изменении observable', (tester) async {
  final controller = Controller();
  Sint.put(controller);

  await tester.pumpWidget(
    MaterialApp(
      home: Obx(() => Text('${controller.count}')),
    ),
  );

  // Проверка начального текста
  expect(find.text('0'), findsOneWidget);

  // Обновление observable
  controller.count++;
  await tester.pump();

  // Проверка обновленного текста
  expect(find.text('1'), findsOneWidget);
});

testWidgets('SintBuilder обновляется при вызове update()', (tester) async {
  final controller = Controller();

  await tester.pumpWidget(
    MaterialApp(
      home: SintBuilder<Controller>(
        init: controller,
        builder: (c) => Text('${c.count}'),
      ),
    ),
  );

  expect(find.text('0'), findsOneWidget);

  controller.increment();
  await tester.pump();

  expect(find.text('1'), findsOneWidget);
});
```

### Интеграционные тесты

```dart
testWidgets('Полный пользовательский сценарий с управлением состоянием', (tester) async {
  await tester.pumpWidget(MyApp());

  // Нажатие кнопки входа
  await tester.tap(find.byKey(Key('login_button')));
  await tester.pumpAndSettle();

  // Проверка индикатора загрузки
  expect(find.byType(CircularProgressIndicator), findsOneWidget);

  // Ожидание асинхронной операции
  await tester.pumpAndSettle(Duration(seconds: 2));

  // Проверка успешного состояния
  expect(find.text('Добро пожаловать'), findsOneWidget);
});
```

### Тесты Workers

```dart
test('ever worker срабатывает при каждом изменении', () {
  final controller = Controller();
  int callCount = 0;

  ever(controller.count, (_) {
    callCount++;
  });

  controller.count++;
  controller.count++;
  controller.count++;

  expect(callCount, 3);
});

test('debounce worker задерживает выполнение', () async {
  final controller = Controller();
  int callCount = 0;

  debounce(controller.searchQuery, (_) {
    callCount++;
  }, time: Duration(milliseconds: 500));

  controller.searchQuery.value = 'a';
  controller.searchQuery.value = 'ab';
  controller.searchQuery.value = 'abc';

  expect(callCount, 0); // Еще не вызван

  await Future.delayed(Duration(milliseconds: 600));
  expect(callCount, 1); // Вызван один раз после debounce
});
```

### Тестирование с моками

```dart
class MockApi extends Mock implements ApiService {}

test('UserController обрабатывает ошибки API', () async {
  final mockApi = MockApi();
  final controller = UserController(api: mockApi);

  when(mockApi.getUser()).thenThrow(Exception('Ошибка сети'));

  controller.fetchUser();
  await Future.delayed(Duration.zero);

  expect(controller.status.isError, true);
  expect(controller.status.errorMessage, contains('Ошибка сети'));
});
```
