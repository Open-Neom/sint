# ادارة التنقل

## المقدمة

إدارة التنقل هي أحد الأعمدة الأربعة لإطار عمل SINT. توفر SINT نظام توجيه قوي ومرن يسمح بالتنقل بين الصفحات بدون context، مع دعم المسارات المسماة، المعاملات الديناميكية، والوسائط (Middleware).

## SintMaterialApp

نقطة البداية لأي تطبيق يستخدم SINT:

```dart
void main() {
  runApp(
    SintMaterialApp(
      title: 'تطبيقي',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    ),
  );
}
```

### مع المسارات المسماة

```dart
void main() {
  runApp(
    SintMaterialApp(
      initialRoute: '/',
      getPages: [
        SintPage(name: '/', page: () => HomePage()),
        SintPage(name: '/profile', page: () => ProfilePage()),
        SintPage(name: '/settings', page: () => SettingsPage()),
      ],
    ),
  );
}
```

## طرق التنقل الأساسية

### Sint.to - الانتقال إلى صفحة جديدة

```dart
// انتقال بسيط
Sint.to(NextPage());

// مع تأثير انتقالي
Sint.to(
  NextPage(),
  transition: Transition.fadeIn,
  duration: Duration(milliseconds: 300),
);
```

### Sint.toNamed - الانتقال باستخدام المسار المسمى

```dart
// انتقال بسيط
Sint.toNamed('/profile');

// مع معاملات
Sint.toNamed('/profile', arguments: {'id': 123});

// مع parameters في URL
Sint.toNamed('/user/123');
```

### Sint.off - استبدال الصفحة الحالية

```dart
// استبدال الصفحة الحالية بصفحة جديدة
Sint.off(HomePage());

// مفيد بعد تسجيل الدخول
void onLoginSuccess() {
  Sint.off(DashboardPage());
}
```

### Sint.offNamed - استبدال باستخدام المسار

```dart
Sint.offNamed('/dashboard');

// مع معاملات
Sint.offNamed('/home', arguments: {'refresh': true});
```

### Sint.offAll - حذف كل الصفحات والانتقال

```dart
// حذف كل سجل التنقل
Sint.offAll(LoginPage());

// مفيد عند تسجيل الخروج
void logout() {
  Sint.offAll(LoginPage());
}
```

### Sint.back - الرجوع للصفحة السابقة

```dart
// رجوع بسيط
Sint.back();

// رجوع مع نتيجة
Sint.back(result: {'saved': true});

// رجوع مع التحقق
if (Sint.isSnackbarOpen) {
  Sint.back();
}
```

### Sint.until - الرجوع حتى شرط معين

```dart
// الرجوع حتى الصفحة الرئيسية
Sint.until((route) => route.isFirst);

// الرجوع حتى مسار معين
Sint.until((route) => route.settings.name == '/home');
```

## المسارات المسماة المتقدمة

### تعريف المسارات

```dart
class AppPages {
  static const initial = '/';
  static const login = '/login';
  static const home = '/home';
  static const profile = '/profile/:id';
  static const product = '/product/:productId';

  static final routes = [
    SintPage(
      name: initial,
      page: () => SplashPage(),
    ),
    SintPage(
      name: login,
      page: () => LoginPage(),
      transition: Transition.fadeIn,
    ),
    SintPage(
      name: home,
      page: () => HomePage(),
      binding: HomeBinding(),
    ),
    SintPage(
      name: profile,
      page: () => ProfilePage(),
      binding: ProfileBinding(),
    ),
    SintPage(
      name: product,
      page: () => ProductPage(),
    ),
  ];
}

// في main.dart
void main() {
  runApp(
    SintMaterialApp(
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    ),
  );
}
```

### المعاملات الديناميكية في URL

```dart
// تعريف المسار
SintPage(
  name: '/user/:userId/post/:postId',
  page: () => PostPage(),
)

// الانتقال
Sint.toNamed('/user/123/post/456');

// استقبال المعاملات
class PostPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = Sint.parameters['userId'];
    final postId = Sint.parameters['postId'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Post $postId by User $userId'),
      ),
    );
  }
}
```

### Query Parameters

```dart
// الإرسال
Sint.toNamed('/search?query=flutter&sort=recent');

// الاستقبال
final query = Sint.parameters['query']; // 'flutter'
final sort = Sint.parameters['sort']; // 'recent'
```

### Arguments

```dart
// الإرسال
Sint.toNamed('/profile', arguments: {
  'user': User(name: 'أحمد', age: 30),
  'isEditable': true,
});

// الاستقبال
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final args = Sint.arguments as Map<String, dynamic>;
    final user = args['user'] as User;
    final isEditable = args['isEditable'] as bool;

    return Scaffold(
      appBar: AppBar(title: Text(user.name)),
    );
  }
}
```

## Middleware

Middleware يسمح بالتحكم في التنقل قبل الوصول للصفحة:

```dart
class AuthMiddleware extends SintMiddleware {
  @override
  int? priority = 1;

  @override
  RouteSettings? redirect(String? route) {
    final authService = Sint.find<AuthService>();

    if (!authService.isAuthenticated) {
      return RouteSettings(name: '/login');
    }

    return null;
  }
}

// استخدام في المسار
SintPage(
  name: '/dashboard',
  page: () => DashboardPage(),
  middlewares: [AuthMiddleware()],
)
```

### Middleware متقدم

```dart
class RoleMiddleware extends SintMiddleware {
  final String requiredRole;

  RoleMiddleware(this.requiredRole);

  @override
  int? priority = 2;

  @override
  RouteSettings? redirect(String? route) {
    final user = Sint.find<AuthService>().currentUser;

    if (user?.role != requiredRole) {
      return RouteSettings(name: '/unauthorized');
    }

    return null;
  }

  @override
  SintPage? onPageCalled(SintPage? page) {
    print('تم استدعاء الصفحة: ${page?.name}');
    return super.onPageCalled(page);
  }

  @override
  Widget onPageBuilt(Widget page) {
    print('تم بناء الصفحة');
    return page;
  }
}

// الاستخدام
SintPage(
  name: '/admin',
  page: () => AdminPage(),
  middlewares: [
    AuthMiddleware(),
    RoleMiddleware('admin'),
  ],
)
```

## SnackBars

### SnackBar بسيط

```dart
Sint.snackbar(
  'العنوان',
  'الرسالة',
);
```

### SnackBar مخصص

```dart
Sint.snackbar(
  'نجاح',
  'تم حفظ البيانات بنجاح',
  snackPosition: SnackPosition.BOTTOM,
  backgroundColor: Colors.green,
  colorText: Colors.white,
  icon: Icon(Icons.check_circle, color: Colors.white),
  duration: Duration(seconds: 3),
  isDismissible: true,
  dismissDirection: DismissDirection.horizontal,
  forwardAnimationCurve: Curves.easeOutBack,
);
```

### SnackBar مع إجراءات

```dart
Sint.snackbar(
  'تنبيه',
  'هل تريد حذف هذا العنصر؟',
  mainButton: TextButton(
    onPressed: () {
      deleteItem();
      Sint.back();
    },
    child: Text('حذف', style: TextStyle(color: Colors.white)),
  ),
);
```

### أنواع SnackBar

```dart
// نجاح
void showSuccess(String message) {
  Sint.snackbar(
    'نجاح',
    message,
    backgroundColor: Colors.green,
    icon: Icon(Icons.check_circle),
  );
}

// خطأ
void showError(String message) {
  Sint.snackbar(
    'خطأ',
    message,
    backgroundColor: Colors.red,
    icon: Icon(Icons.error),
  );
}

// تحذير
void showWarning(String message) {
  Sint.snackbar(
    'تحذير',
    message,
    backgroundColor: Colors.orange,
    icon: Icon(Icons.warning),
  );
}

// معلومات
void showInfo(String message) {
  Sint.snackbar(
    'معلومة',
    message,
    backgroundColor: Colors.blue,
    icon: Icon(Icons.info),
  );
}
```

## Dialogs

### Dialog بسيط

```dart
Sint.defaultDialog(
  title: 'تأكيد',
  middleText: 'هل أنت متأكد من الحذف؟',
  onConfirm: () {
    deleteItem();
    Sint.back();
  },
  onCancel: () {},
);
```

### Dialog مخصص

```dart
Sint.defaultDialog(
  title: 'تنبيه',
  content: Column(
    children: [
      Icon(Icons.warning, size: 50, color: Colors.orange),
      SizedBox(height: 16),
      Text('هذا الإجراء لا يمكن التراجع عنه'),
    ],
  ),
  confirm: ElevatedButton(
    onPressed: () {
      performAction();
      Sint.back();
    },
    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
    child: Text('متابعة'),
  ),
  cancel: TextButton(
    onPressed: () => Sint.back(),
    child: Text('إلغاء'),
  ),
);
```

### Dialog مخصص بالكامل

```dart
Sint.dialog(
  Dialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Dialog مخصص', style: TextStyle(fontSize: 20)),
          SizedBox(height: 20),
          TextField(decoration: InputDecoration(hintText: 'أدخل النص')),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Sint.back(),
                child: Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  // معالجة البيانات
                  Sint.back();
                },
                child: Text('حفظ'),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
);
```

## BottomSheets

### BottomSheet بسيط

```dart
Sint.bottomSheet(
  Container(
    height: 200,
    color: Colors.white,
    child: Center(
      child: Text('Bottom Sheet'),
    ),
  ),
);
```

### BottomSheet مخصص

```dart
Sint.bottomSheet(
  Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: ListView(
      shrinkWrap: true,
      children: [
        ListTile(
          leading: Icon(Icons.photo_camera),
          title: Text('الكاميرا'),
          onTap: () {
            openCamera();
            Sint.back();
          },
        ),
        ListTile(
          leading: Icon(Icons.photo_library),
          title: Text('المعرض'),
          onTap: () {
            openGallery();
            Sint.back();
          },
        ),
        ListTile(
          leading: Icon(Icons.cancel),
          title: Text('إلغاء'),
          onTap: () => Sint.back(),
        ),
      ],
    ),
  ),
  backgroundColor: Colors.transparent,
  isDismissible: true,
  enableDrag: true,
);
```

### BottomSheet مع نموذج

```dart
void showFilterSheet() {
  Sint.bottomSheet(
    Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تصفية النتائج', style: TextStyle(fontSize: 20)),
          SizedBox(height: 20),
          DropdownButton<String>(
            value: 'الكل',
            items: ['الكل', 'نشط', 'غير نشط']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) {},
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Sint.back(),
                child: Text('إلغاء'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  applyFilter();
                  Sint.back();
                },
                child: Text('تطبيق'),
              ),
            ],
          ),
        ],
      ),
    ),
    isScrollControlled: true,
  );
}
```

## التأثيرات الانتقالية (Transitions)

### التأثيرات المتاحة

```dart
// Fade In
Sint.to(NextPage(), transition: Transition.fade);

// Right to Left
Sint.to(NextPage(), transition: Transition.rightToLeft);

// Left to Right
Sint.to(NextPage(), transition: Transition.leftToRight);

// Up to Down
Sint.to(NextPage(), transition: Transition.upToDown);

// Down to Up
Sint.to(NextPage(), transition: Transition.downToUp);

// Zoom
Sint.to(NextPage(), transition: Transition.zoom);

// Size
Sint.to(NextPage(), transition: Transition.size);

// No Transition
Sint.to(NextPage(), transition: Transition.noTransition);
```

### تخصيص التأثير

```dart
Sint.to(
  NextPage(),
  transition: Transition.custom,
  customTransition: CustomTransition(),
  duration: Duration(milliseconds: 500),
  curve: Curves.easeInOut,
);

class CustomTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: RotationTransition(
        turns: animation,
        child: child,
      ),
    );
  }
}
```

### تأثير افتراضي لكل المسارات

```dart
SintMaterialApp(
  defaultTransition: Transition.fadeIn,
  transitionDuration: Duration(milliseconds: 300),
  getPages: AppPages.routes,
)
```

## الوصول للمعلومات الحالية

### معلومات المسار

```dart
// المسار الحالي
final currentRoute = Sint.currentRoute; // '/profile'

// المسار السابق
final previousRoute = Sint.previousRoute; // '/home'

// المعاملات
final params = Sint.parameters; // {'id': '123'}

// Arguments
final args = Sint.arguments; // Any object
```

### حالة التنقل

```dart
// هل يمكن الرجوع؟
if (Sint.isDialogOpen) {
  print('Dialog مفتوح');
}

if (Sint.isSnackbarOpen) {
  print('Snackbar ظاهر');
}

if (Sint.isBottomSheetOpen) {
  print('BottomSheet مفتوح');
}

// هل نحن في الصفحة الأولى؟
if (Sint.isOverlaysOpen) {
  print('هناك overlay مفتوح');
}
```

### إغلاق Overlays

```dart
// إغلاق جميع Snackbars, Dialogs, BottomSheets
Sint.closeAllSnackbars();
Sint.closeCurrentSnackbar();

// إغلاق كل overlays
if (Sint.isOverlaysOpen) {
  Sint.back();
}
```

## أنماط التنقل المتقدمة

### التنقل الشرطي

```dart
void navigateToProfile() {
  final isLoggedIn = Sint.find<AuthService>().isLoggedIn;

  if (isLoggedIn) {
    Sint.toNamed('/profile');
  } else {
    Sint.toNamed('/login', arguments: {
      'returnTo': '/profile',
    });
  }
}
```

### التنقل مع النتيجة

```dart
// الصفحة الأولى
void openSettings() async {
  final result = await Sint.to(SettingsPage());

  if (result == true) {
    print('تم حفظ الإعدادات');
    refreshData();
  }
}

// صفحة الإعدادات
void saveSettings() {
  // حفظ البيانات
  Sint.back(result: true);
}
```

### التنقل المتداخل

```dart
// استخدام NavigatorKey مخصص
final nestedKey = GlobalKey<NavigatorState>();

Scaffold(
  body: Navigator(
    key: nestedKey,
    onGenerateRoute: (settings) {
      return MaterialPageRoute(
        builder: (context) => NestedPage(),
      );
    },
  ),
)
```

## خارطة طريق الاختبارات

### اختبار التنقل الأساسي

```dart
testWidgets('يجب أن ينتقل إلى الصفحة التالية', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(
      home: HomePage(),
    ),
  );

  Sint.to(NextPage());
  await tester.pumpAndSettle();

  expect(find.byType(NextPage), findsOneWidget);
});
```

### اختبار المسارات المسماة

```dart
testWidgets('يجب أن ينتقل باستخدام المسار المسمى', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(
      initialRoute: '/',
      getPages: [
        SintPage(name: '/', page: () => HomePage()),
        SintPage(name: '/profile', page: () => ProfilePage()),
      ],
    ),
  );

  Sint.toNamed('/profile');
  await tester.pumpAndSettle();

  expect(find.byType(ProfilePage), findsOneWidget);
});
```

### اختبار المعاملات

```dart
testWidgets('يجب أن يمرر المعاملات', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(
      getPages: [
        SintPage(
          name: '/user/:id',
          page: () => UserPage(),
        ),
      ],
    ),
  );

  Sint.toNamed('/user/123');
  await tester.pumpAndSettle();

  expect(Sint.parameters['id'], '123');
});
```

### اختبار Arguments

```dart
test('يجب أن يمرر arguments', () {
  final testData = {'name': 'أحمد', 'age': 30};

  Sint.toNamed('/profile', arguments: testData);

  expect(Sint.arguments, testData);
});
```

### اختبار Middleware

```dart
testWidgets('يجب أن يعيد التوجيه للصفحة الصحيحة', (tester) async {
  // تعطيل المصادقة
  Sint.put(AuthService()..isAuthenticated = false);

  await tester.pumpWidget(
    SintMaterialApp(
      getPages: [
        SintPage(name: '/login', page: () => LoginPage()),
        SintPage(
          name: '/dashboard',
          page: () => DashboardPage(),
          middlewares: [AuthMiddleware()],
        ),
      ],
    ),
  );

  Sint.toNamed('/dashboard');
  await tester.pumpAndSettle();

  // يجب أن يعيد التوجيه للصفحة تسجيل الدخول
  expect(find.byType(LoginPage), findsOneWidget);
});
```

### اختبار SnackBar

```dart
testWidgets('يجب أن يعرض SnackBar', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(home: Scaffold()),
  );

  Sint.snackbar('عنوان', 'رسالة');
  await tester.pump();

  expect(find.text('عنوان'), findsOneWidget);
  expect(find.text('رسالة'), findsOneWidget);
});
```

### اختبار Dialog

```dart
testWidgets('يجب أن يعرض Dialog', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(home: Scaffold()),
  );

  Sint.defaultDialog(
    title: 'تأكيد',
    middleText: 'هل أنت متأكد؟',
  );
  await tester.pumpAndSettle();

  expect(find.text('تأكيد'), findsOneWidget);
  expect(find.text('هل أنت متأكد؟'), findsOneWidget);
});
```

### اختبار BottomSheet

```dart
testWidgets('يجب أن يعرض BottomSheet', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(home: Scaffold()),
  );

  Sint.bottomSheet(
    Container(child: Text('Bottom Sheet Content')),
  );
  await tester.pumpAndSettle();

  expect(find.text('Bottom Sheet Content'), findsOneWidget);
});
```

### اختبار الانتقالات

```dart
testWidgets('يجب أن يستخدم التأثير الصحيح', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(home: HomePage()),
  );

  Sint.to(NextPage(), transition: Transition.fadeIn);
  await tester.pump();
  await tester.pump(Duration(milliseconds: 150));

  expect(find.byType(NextPage), findsOneWidget);
});
```

### استراتيجية الاختبار الشاملة

1. **اختبار التنقل الأساسي**: to, toNamed, off, offAll, back
2. **اختبار المسارات**: initialRoute, getPages, parameters
3. **اختبار Arguments**: إرسال واستقبال البيانات
4. **اختبار Middleware**: redirect, onPageCalled, onPageBuilt
5. **اختبار Bindings**: حقن التبعيات مع المسارات
6. **اختبار SnackBar**: عرض وإخفاء الإشعارات
7. **اختبار Dialog**: defaultDialog و dialog مخصص
8. **اختبار BottomSheet**: عرض وإغلاق
9. **اختبار Transitions**: جميع أنواع التأثيرات
10. **اختبار Navigation Stack**: until, isFirst, previousRoute
11. **اختبار حالة التنقل**: isDialogOpen, isSnackbarOpen, isBottomSheetOpen
12. **اختبار الأداء**: قياس وقت التنقل وسلاسة الانتقالات
