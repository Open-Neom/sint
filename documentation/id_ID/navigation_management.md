# Manajemen Navigasi

Sistem navigasi SINT menyediakan cara yang powerful dan mudah untuk navigasi, routing, snackbars, dialogs, dan bottom sheets tanpa context.

## Daftar Isi

- [Setup](#setup)
- [Navigasi Sederhana](#navigasi-sederhana)
- [Named Routes](#named-routes)
- [Dynamic URLs](#dynamic-urls)
- [Middleware](#middleware)
- [SnackBars](#snackbars)
- [Dialogs](#dialogs)
- [BottomSheets](#bottomsheets)
- [Transitions](#transitions)
- [Peta Pengujian](#peta-pengujian)

## Setup

Ganti `MaterialApp` dengan `SintMaterialApp`:

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

## Navigasi Sederhana

Navigasi tanpa context:

### Sint.to()

Navigasi ke halaman baru:

```dart
Sint.to(DetailPage());

// Dengan parameter
Sint.to(DetailPage(id: 123));

// Dengan transition
Sint.to(
  DetailPage(),
  transition: Transition.rightToLeft,
  duration: Duration(milliseconds: 300),
);
```

### Sint.back()

Kembali ke halaman sebelumnya:

```dart
Sint.back();

// Dengan result
Sint.back(result: 'Data dari halaman sebelumnya');

// Terima result
final result = await Sint.to(SecondPage());
print(result); // 'Data dari halaman sebelumnya'
```

### Sint.off()

Ganti halaman saat ini dengan yang baru:

```dart
Sint.off(HomePage());
```

### Sint.offAll()

Hapus semua halaman sebelumnya dan navigasi ke yang baru:

```dart
Sint.offAll(LoginPage());

// Dengan predicate
Sint.offAll(
  HomePage(),
  predicate: (route) => route.isFirst,
);
```

## Named Routes

### Definisi Routes

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

### Navigasi dengan Named Routes

```dart
// Navigasi ke named route
Sint.toNamed('/details');

// Dengan arguments
Sint.toNamed('/details', arguments: {'id': 123, 'name': 'John'});

// Terima arguments di halaman tujuan
class DetailsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final args = Sint.arguments as Map<String, dynamic>;
    final id = args['id'];
    final name = args['name'];

    return Scaffold(
      body: Text('ID: $id, Name: $name'),
    );
  }
}
```

### Off dan OffAll dengan Named Routes

```dart
// Replace current route
Sint.offNamed('/home');

// Clear all and navigate
Sint.offAllNamed('/login');
```

## Dynamic URLs

Gunakan parameter URL seperti web routing:

### Definisi

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

### Penggunaan

```dart
// Navigasi
Sint.toNamed('/user/123');
Sint.toNamed('/product/electronics/456');

// Akses parameters
class UserPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final id = Sint.parameters['id'];
    return Text('User ID: $id');
  }
}

class ProductPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final category = Sint.parameters['category'];
    final id = Sint.parameters['id'];
    return Text('Category: $category, ID: $id');
  }
}
```

### Query Parameters

```dart
// Navigasi dengan query params
Sint.toNamed('/search?q=flutter&sort=recent');

// Akses query params
final query = Sint.parameters['q']; // 'flutter'
final sort = Sint.parameters['sort']; // 'recent'
```

## Middleware

Middleware mengizinkan Anda untuk menjalankan kode sebelum route ditampilkan:

### Membuat Middleware

```dart
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    // Cek apakah user sudah login
    final authService = Sint.find<AuthService>();

    if (!authService.isAuthenticated) {
      return RouteSettings(name: '/login');
    }

    return null;
  }
}
```

### Menggunakan Middleware

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

### Multiple Middlewares

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

### Middleware Lifecycle

```dart
class LoggingMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    print('Redirecting to: $route');
    return null;
  }

  @override
  GetPage? onPageCalled(GetPage? page) {
    print('Page called: ${page?.name}');
    return page;
  }

  @override
  List<Bindings>? onBindingsStart(List<Bindings>? bindings) {
    print('Bindings started');
    return bindings;
  }

  @override
  GetPageBuilder? onPageBuildStart(GetPageBuilder? page) {
    print('Page build started');
    return page;
  }

  @override
  Widget onPageBuilt(Widget page) {
    print('Page built');
    return page;
  }

  @override
  void onPageDispose() {
    print('Page disposed');
  }
}
```

## SnackBars

Tampilkan snackbar tanpa context:

### Basic SnackBar

```dart
Sint.snackbar(
  'Title',
  'Message',
);
```

### Custom SnackBar

```dart
Sint.snackbar(
  'Error',
  'Something went wrong',
  snackPosition: SnackPosition.BOTTOM,
  backgroundColor: Colors.red,
  colorText: Colors.white,
  duration: Duration(seconds: 3),
  icon: Icon(Icons.error, color: Colors.white),
  shouldIconPulse: true,
  barBlur: 20,
  isDismissible: true,
  onTap: (_) {
    print('SnackBar tapped');
  },
);
```

### SnackBar dengan Action

```dart
Sint.snackbar(
  'Deleted',
  'Item has been deleted',
  mainButton: TextButton(
    onPressed: () {
      // Undo action
    },
    child: Text('UNDO', style: TextStyle(color: Colors.white)),
  ),
);
```

## Dialogs

Tampilkan dialogs tanpa context:

### Basic Dialog

```dart
Sint.defaultDialog(
  title: 'Alert',
  middleText: 'This is a dialog message',
);
```

### Custom Dialog

```dart
Sint.defaultDialog(
  title: 'Delete Item?',
  middleText: 'Are you sure you want to delete this item?',
  textConfirm: 'Delete',
  textCancel: 'Cancel',
  confirmTextColor: Colors.white,
  onConfirm: () {
    // Delete action
    Sint.back();
  },
  onCancel: () {
    print('Cancelled');
  },
);
```

### Custom Content Dialog

```dart
Sint.dialog(
  Dialog(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Custom Dialog'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Sint.back(),
            child: Text('Close'),
          ),
        ],
      ),
    ),
  ),
);
```

### Dialog dengan Result

```dart
final result = await Sint.dialog<bool>(
  AlertDialog(
    title: Text('Confirm'),
    content: Text('Are you sure?'),
    actions: [
      TextButton(
        onPressed: () => Sint.back(result: false),
        child: Text('No'),
      ),
      TextButton(
        onPressed: () => Sint.back(result: true),
        child: Text('Yes'),
      ),
    ],
  ),
);

if (result == true) {
  print('Confirmed');
}
```

## BottomSheets

Tampilkan bottom sheets tanpa context:

### Basic BottomSheet

```dart
Sint.bottomSheet(
  Container(
    color: Colors.white,
    child: Wrap(
      children: [
        ListTile(
          leading: Icon(Icons.music_note),
          title: Text('Music'),
          onTap: () => Sint.back(),
        ),
        ListTile(
          leading: Icon(Icons.videocam),
          title: Text('Video'),
          onTap: () => Sint.back(),
        ),
      ],
    ),
  ),
);
```

### Custom BottomSheet

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
        Text('Choose an option'),
        // ... more content
      ],
    ),
  ),
  backgroundColor: Colors.transparent,
  isDismissible: true,
  enableDrag: true,
  isScrollControlled: true,
);
```

### BottomSheet dengan Result

```dart
final option = await Sint.bottomSheet<String>(
  Container(
    color: Colors.white,
    child: Wrap(
      children: [
        ListTile(
          title: Text('Option 1'),
          onTap: () => Sint.back(result: 'option1'),
        ),
        ListTile(
          title: Text('Option 2'),
          onTap: () => Sint.back(result: 'option2'),
        ),
      ],
    ),
  ),
);

print('Selected: $option');
```

## Transitions

### Built-in Transitions

```dart
Sint.to(
  NextPage(),
  transition: Transition.fadeIn,
  duration: Duration(milliseconds: 300),
);
```

Available transitions:
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

### Custom Transition

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

### Default Transition untuk App

```dart
SintMaterialApp(
  defaultTransition: Transition.fade,
  transitionDuration: Duration(milliseconds: 400),
)
```

## Peta Pengujian

### Unit Tests

```dart
test('Named route navigation', () async {
  await Sint.toNamed('/details', arguments: {'id': 123});

  expect(Sint.currentRoute, '/details');
  expect(Sint.arguments['id'], 123);
});

test('Parameters parsing', () {
  Sint.toNamed('/user/123');

  expect(Sint.parameters['id'], '123');
});
```

### Widget Tests

```dart
testWidgets('Navigation to new page', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(
      home: Builder(
        builder: (context) {
          return ElevatedButton(
            onPressed: () => Sint.to(SecondPage()),
            child: Text('Navigate'),
          );
        },
      ),
    ),
  );

  await tester.tap(find.text('Navigate'));
  await tester.pumpAndSettle();

  expect(find.byType(SecondPage), findsOneWidget);
});

testWidgets('Back navigation', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(
      home: FirstPage(),
    ),
  );

  // Navigate forward
  Sint.to(SecondPage());
  await tester.pumpAndSettle();

  expect(find.byType(SecondPage), findsOneWidget);

  // Navigate back
  Sint.back();
  await tester.pumpAndSettle();

  expect(find.byType(FirstPage), findsOneWidget);
});
```

### Middleware Tests

```dart
testWidgets('Middleware redirects unauthenticated users', (tester) async {
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

  // Should redirect to login
  expect(find.byType(LoginPage), findsOneWidget);
  expect(find.byType(ProfilePage), findsNothing);
});
```

### SnackBar Tests

```dart
testWidgets('SnackBar displays message', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(
      home: Builder(
        builder: (context) {
          return ElevatedButton(
            onPressed: () {
              Sint.snackbar('Title', 'Message');
            },
            child: Text('Show SnackBar'),
          );
        },
      ),
    ),
  );

  await tester.tap(find.text('Show SnackBar'));
  await tester.pump();

  expect(find.text('Title'), findsOneWidget);
  expect(find.text('Message'), findsOneWidget);
});
```

### Dialog Tests

```dart
testWidgets('Dialog shows and returns result', (tester) async {
  bool? result;

  await tester.pumpWidget(
    SintMaterialApp(
      home: Builder(
        builder: (context) {
          return ElevatedButton(
            onPressed: () async {
              result = await Sint.dialog<bool>(
                AlertDialog(
                  title: Text('Confirm'),
                  actions: [
                    TextButton(
                      onPressed: () => Sint.back(result: true),
                      child: Text('Yes'),
                    ),
                  ],
                ),
              );
            },
            child: Text('Show Dialog'),
          );
        },
      ),
    ),
  );

  await tester.tap(find.text('Show Dialog'));
  await tester.pumpAndSettle();

  expect(find.text('Confirm'), findsOneWidget);

  await tester.tap(find.text('Yes'));
  await tester.pumpAndSettle();

  expect(result, true);
});
```

### Integration Tests

```dart
testWidgets('Complete navigation flow', (tester) async {
  await tester.pumpWidget(MyApp());

  // Start at home
  expect(find.byType(HomePage), findsOneWidget);

  // Navigate to details
  await tester.tap(find.text('View Details'));
  await tester.pumpAndSettle();
  expect(find.byType(DetailsPage), findsOneWidget);

  // Navigate to profile
  await tester.tap(find.text('Profile'));
  await tester.pumpAndSettle();
  expect(find.byType(ProfilePage), findsOneWidget);

  // Back to details
  Sint.back();
  await tester.pumpAndSettle();
  expect(find.byType(DetailsPage), findsOneWidget);

  // offAll to home
  Sint.offAll(HomePage());
  await tester.pumpAndSettle();
  expect(find.byType(HomePage), findsOneWidget);
});
```
