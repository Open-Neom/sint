# Управление навигацией

Система навигации SINT предоставляет мощный и простой способ для навигации, маршрутизации, snackbars, dialogs и bottom sheets без context.

## Содержание

- [Настройка](#настройка)
- [Простая навигация](#простая-навигация)
- [Именованные маршруты](#именованные-маршруты)
- [Динамические URL](#динамические-url)
- [Middleware](#middleware)
- [SnackBars](#snackbars)
- [Dialogs](#dialogs)
- [BottomSheets](#bottomsheets)
- [Переходы](#переходы)
- [Дорожная карта тестирования](#дорожная-карта-тестирования)

## Настройка

Замените `MaterialApp` на `SintMaterialApp`:

```dart
import 'package:sint/sint.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SintMaterialApp(
      title: 'SINT App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}
```

## Простая навигация

Навигация без context:

### Sint.to()

Переход на новую страницу:

```dart
Sint.to(DetailPage());

// С параметрами
Sint.to(DetailPage(id: 123));

// С переходом
Sint.to(
  DetailPage(),
  transition: Transition.rightToLeft,
  duration: Duration(milliseconds: 300),
);
```

### Sint.back()

Возврат на предыдущую страницу:

```dart
Sint.back();

// С результатом
Sint.back(result: 'Данные с предыдущей страницы');

// Получение результата
final result = await Sint.to(SecondPage());
print(result); // 'Данные с предыдущей страницы'
```

### Sint.off()

Замена текущей страницы новой:

```dart
Sint.off(HomePage());
```

### Sint.offAll()

Удаление всех предыдущих страниц и переход на новую:

```dart
Sint.offAll(LoginPage());

// С предикатом
Sint.offAll(
  HomePage(),
  predicate: (route) => route.isFirst,
);
```

## Именованные маршруты

### Определение маршрутов

```dart
SintMaterialApp(
  initialRoute: '/home',
  getPages: [
    GetPage(name: '/home', page: () => HomePage()),
    GetPage(name: '/details', page: () => DetailsPage()),
    GetPage(name: '/profile', page: () => ProfilePage()),
  ],
);
```

### Навигация с именованными маршрутами

```dart
// Переход на именованный маршрут
Sint.toNamed('/details');

// С аргументами
Sint.toNamed('/details', arguments: {'id': 123, 'name': 'Иван'});

// Получение аргументов на целевой странице
class DetailsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final args = Sint.arguments as Map<String, dynamic>;
    final id = args['id'];
    final name = args['name'];

    return Scaffold(
      body: Text('ID: $id, Имя: $name'),
    );
  }
}
```

### Off и OffAll с именованными маршрутами

```dart
// Замена текущего маршрута
Sint.offNamed('/home');

// Очистка всех и переход
Sint.offAllNamed('/login');
```

## Динамические URL

Используйте параметры URL как в веб-маршрутизации:

### Определение

```dart
getPages: [
  GetPage(
    name: '/user/:id',
    page: () => UserPage(),
  ),
  GetPage(
    name: '/product/:category/:id',
    page: () => ProductPage(),
  ),
]
```

### Использование

```dart
// Навигация
Sint.toNamed('/user/123');
Sint.toNamed('/product/electronics/456');

// Доступ к параметрам
class UserPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final id = Sint.parameters['id'];
    return Text('ID пользователя: $id');
  }
}

class ProductPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final category = Sint.parameters['category'];
    final id = Sint.parameters['id'];
    return Text('Категория: $category, ID: $id');
  }
}
```

### Параметры запроса

```dart
// Навигация с query params
Sint.toNamed('/search?q=flutter&sort=recent');

// Доступ к query params
final query = Sint.parameters['q']; // 'flutter'
final sort = Sint.parameters['sort']; // 'recent'
```

## Middleware

Middleware позволяет выполнять код перед отображением маршрута:

### Создание Middleware

```dart
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    // Проверка авторизации пользователя
    final authService = Sint.find<AuthService>();

    if (!authService.isAuthenticated) {
      return RouteSettings(name: '/login');
    }

    return null;
  }
}
```

### Использование Middleware

```dart
getPages: [
  GetPage(
    name: '/home',
    page: () => HomePage(),
  ),
  GetPage(
    name: '/profile',
    page: () => ProfilePage(),
    middlewares: [AuthMiddleware()],
  ),
  GetPage(
    name: '/login',
    page: () => LoginPage(),
  ),
]
```

### Множественные Middlewares

```dart
GetPage(
  name: '/admin',
  page: () => AdminPage(),
  middlewares: [
    AuthMiddleware(),
    AdminMiddleware(),
    LoggingMiddleware(),
  ],
)
```

### Жизненный цикл Middleware

```dart
class LoggingMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    print('Перенаправление на: $route');
    return null;
  }

  @override
  GetPage? onPageCalled(GetPage? page) {
    print('Страница вызвана: ${page?.name}');
    return page;
  }

  @override
  List<Bindings>? onBindingsStart(List<Bindings>? bindings) {
    print('Bindings запущены');
    return bindings;
  }

  @override
  GetPageBuilder? onPageBuildStart(GetPageBuilder? page) {
    print('Начало построения страницы');
    return page;
  }

  @override
  Widget onPageBuilt(Widget page) {
    print('Страница построена');
    return page;
  }

  @override
  void onPageDispose() {
    print('Страница удалена');
  }
}
```

## SnackBars

Отображение snackbar без context:

### Базовый SnackBar

```dart
Sint.snackbar(
  'Заголовок',
  'Сообщение',
);
```

### Настраиваемый SnackBar

```dart
Sint.snackbar(
  'Ошибка',
  'Что-то пошло не так',
  snackPosition: SnackPosition.BOTTOM,
  backgroundColor: Colors.red,
  colorText: Colors.white,
  duration: Duration(seconds: 3),
  icon: Icon(Icons.error, color: Colors.white),
  shouldIconPulse: true,
  barBlur: 20,
  isDismissible: true,
  onTap: (_) {
    print('SnackBar нажат');
  },
);
```

### SnackBar с действием

```dart
Sint.snackbar(
  'Удалено',
  'Элемент был удален',
  mainButton: TextButton(
    onPressed: () {
      // Отменить действие
    },
    child: Text('ОТМЕНИТЬ', style: TextStyle(color: Colors.white)),
  ),
);
```

## Dialogs

Отображение dialogs без context:

### Базовый Dialog

```dart
Sint.defaultDialog(
  title: 'Предупреждение',
  middleText: 'Это сообщение диалога',
);
```

### Настраиваемый Dialog

```dart
Sint.defaultDialog(
  title: 'Удалить элемент?',
  middleText: 'Вы уверены, что хотите удалить этот элемент?',
  textConfirm: 'Удалить',
  textCancel: 'Отмена',
  confirmTextColor: Colors.white,
  onConfirm: () {
    // Действие удаления
    Sint.back();
  },
  onCancel: () {
    print('Отменено');
  },
);
```

### Dialog с пользовательским содержимым

```dart
Sint.dialog(
  Dialog(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Пользовательский диалог'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Sint.back(),
            child: Text('Закрыть'),
          ),
        ],
      ),
    ),
  ),
);
```

### Dialog с результатом

```dart
final result = await Sint.dialog<bool>(
  AlertDialog(
    title: Text('Подтверждение'),
    content: Text('Вы уверены?'),
    actions: [
      TextButton(
        onPressed: () => Sint.back(result: false),
        child: Text('Нет'),
      ),
      TextButton(
        onPressed: () => Sint.back(result: true),
        child: Text('Да'),
      ),
    ],
  ),
);

if (result == true) {
  print('Подтверждено');
}
```

## BottomSheets

Отображение bottom sheets без context:

### Базовый BottomSheet

```dart
Sint.bottomSheet(
  Container(
    color: Colors.white,
    child: Wrap(
      children: [
        ListTile(
          leading: Icon(Icons.music_note),
          title: Text('Музыка'),
          onTap: () => Sint.back(),
        ),
        ListTile(
          leading: Icon(Icons.videocam),
          title: Text('Видео'),
          onTap: () => Sint.back(),
        ),
      ],
    ),
  ),
);
```

### Настраиваемый BottomSheet

```dart
Sint.bottomSheet(
  Container(
    height: 300,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Column(
      children: [
        Container(
          height: 4,
          width: 40,
          margin: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Text('Выберите опцию'),
        // ... больше содержимого
      ],
    ),
  ),
  backgroundColor: Colors.transparent,
  isDismissible: true,
  enableDrag: true,
  isScrollControlled: true,
);
```

### BottomSheet с результатом

```dart
final option = await Sint.bottomSheet<String>(
  Container(
    color: Colors.white,
    child: Wrap(
      children: [
        ListTile(
          title: Text('Опция 1'),
          onTap: () => Sint.back(result: 'option1'),
        ),
        ListTile(
          title: Text('Опция 2'),
          onTap: () => Sint.back(result: 'option2'),
        ),
      ],
    ),
  ),
);

print('Выбрано: $option');
```

## Переходы

### Встроенные переходы

```dart
Sint.to(
  NextPage(),
  transition: Transition.fadeIn,
  duration: Duration(milliseconds: 300),
);
```

Доступные переходы:
- `Transition.fadeIn`
- `Transition.rightToLeft`
- `Transition.leftToRight`
- `Transition.upToDown`
- `Transition.downToUp`
- `Transition.scale`
- `Transition.rotate`
- `Transition.size`
- `Transition.rightToLeftWithFade`
- `Transition.leftToRightWithFade`
- `Transition.zoom`
- `Transition.cupertino`
- `Transition.native`

### Пользовательский переход

```dart
Sint.to(
  NextPage(),
  transition: Transition.custom,
  customTransition: CustomPageTransition(),
);

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
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }
}
```

### Переход по умолчанию для приложения

```dart
SintMaterialApp(
  defaultTransition: Transition.fade,
  transitionDuration: Duration(milliseconds: 400),
)
```

## Дорожная карта тестирования

### Модульные тесты

```dart
test('Навигация по именованному маршруту', () async {
  await Sint.toNamed('/details', arguments: {'id': 123});

  expect(Sint.currentRoute, '/details');
  expect(Sint.arguments['id'], 123);
});

test('Парсинг параметров', () {
  Sint.toNamed('/user/123');

  expect(Sint.parameters['id'], '123');
});
```

### Виджетные тесты

```dart
testWidgets('Навигация на новую страницу', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(
      home: Builder(
        builder: (context) {
          return ElevatedButton(
            onPressed: () => Sint.to(SecondPage()),
            child: Text('Перейти'),
          );
        },
      ),
    ),
  );

  await tester.tap(find.text('Перейти'));
  await tester.pumpAndSettle();

  expect(find.byType(SecondPage), findsOneWidget);
});

testWidgets('Навигация назад', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(
      home: FirstPage(),
    ),
  );

  // Переход вперед
  Sint.to(SecondPage());
  await tester.pumpAndSettle();

  expect(find.byType(SecondPage), findsOneWidget);

  // Переход назад
  Sint.back();
  await tester.pumpAndSettle();

  expect(find.byType(FirstPage), findsOneWidget);
});
```

### Тесты Middleware

```dart
testWidgets('Middleware перенаправляет неавторизованных пользователей', (tester) async {
  final authService = MockAuthService();
  Sint.put<AuthService>(authService);

  when(authService.isAuthenticated).thenReturn(false);

  await tester.pumpWidget(
    SintMaterialApp(
      initialRoute: '/profile',
      getPages: [
        GetPage(name: '/login', page: () => LoginPage()),
        GetPage(
          name: '/profile',
          page: () => ProfilePage(),
          middlewares: [AuthMiddleware()],
        ),
      ],
    ),
  );

  await tester.pumpAndSettle();

  // Должен перенаправить на login
  expect(find.byType(LoginPage), findsOneWidget);
  expect(find.byType(ProfilePage), findsNothing);
});
```

### Тесты SnackBar

```dart
testWidgets('SnackBar отображает сообщение', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(
      home: Builder(
        builder: (context) {
          return ElevatedButton(
            onPressed: () {
              Sint.snackbar('Заголовок', 'Сообщение');
            },
            child: Text('Показать SnackBar'),
          );
        },
      ),
    ),
  );

  await tester.tap(find.text('Показать SnackBar'));
  await tester.pump();

  expect(find.text('Заголовок'), findsOneWidget);
  expect(find.text('Сообщение'), findsOneWidget);
});
```

### Тесты Dialog

```dart
testWidgets('Dialog показывается и возвращает результат', (tester) async {
  bool? result;

  await tester.pumpWidget(
    SintMaterialApp(
      home: Builder(
        builder: (context) {
          return ElevatedButton(
            onPressed: () async {
              result = await Sint.dialog<bool>(
                AlertDialog(
                  title: Text('Подтверждение'),
                  actions: [
                    TextButton(
                      onPressed: () => Sint.back(result: true),
                      child: Text('Да'),
                    ),
                  ],
                ),
              );
            },
            child: Text('Показать диалог'),
          );
        },
      ),
    ),
  );

  await tester.tap(find.text('Показать диалог'));
  await tester.pumpAndSettle();

  expect(find.text('Подтверждение'), findsOneWidget);

  await tester.tap(find.text('Да'));
  await tester.pumpAndSettle();

  expect(result, true);
});
```

### Интеграционные тесты

```dart
testWidgets('Полный навигационный поток', (tester) async {
  await tester.pumpWidget(MyApp());

  // Начало на главной
  expect(find.byType(HomePage), findsOneWidget);

  // Переход на детали
  await tester.tap(find.text('Посмотреть детали'));
  await tester.pumpAndSettle();
  expect(find.byType(DetailsPage), findsOneWidget);

  // Переход в профиль
  await tester.tap(find.text('Профиль'));
  await tester.pumpAndSettle();
  expect(find.byType(ProfilePage), findsOneWidget);

  // Назад на детали
  Sint.back();
  await tester.pumpAndSettle();
  expect(find.byType(DetailsPage), findsOneWidget);

  // offAll на главную
  Sint.offAll(HomePage());
  await tester.pumpAndSettle();
  expect(find.byType(HomePage), findsOneWidget);
});
```
