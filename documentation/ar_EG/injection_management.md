# ادارة الحقن

## المقدمة

إدارة الحقن (Dependency Injection) هي أحد الأعمدة الأربعة لإطار عمل SINT. توفر SINT نظام حقن تبعيات قوي وسهل الاستخدام يسمح لك بإدارة دورة حياة الكائنات بكفاءة عالية.

## Sint.put

الطريقة الأساسية لحقن التبعيات. تقوم بإنشاء وتسجيل الكائن فوراً:

```dart
class ApiController extends SintController {
  void fetchData() {
    print('جلب البيانات...');
  }
}

// حقن المتحكم
final apiController = Sint.put(ApiController());

// الاستخدام مباشرة
apiController.fetchData();
```

### مع معامل tag

```dart
// حقن نفس الصنف بمعرفات مختلفة
Sint.put(ApiController(), tag: 'api1');
Sint.put(ApiController(), tag: 'api2');

// الوصول حسب المعرف
final api1 = Sint.find<ApiController>(tag: 'api1');
final api2 = Sint.find<ApiController>(tag: 'api2');
```

### معامل permanent

```dart
// المتحكم سيبقى في الذاكرة حتى لو لم يعد مستخدماً
Sint.put(GlobalController(), permanent: true);

// المتحكم العادي (سيتم حذفه تلقائياً)
Sint.put(TemporaryController(), permanent: false);
```

## Sint.lazyPut

يؤجل إنشاء الكائن حتى يتم طلبه لأول مرة:

```dart
// لا يتم إنشاء DatabaseController الآن
Sint.lazyPut(() => DatabaseController());

// يتم الإنشاء هنا فقط عند أول استخدام
final db = Sint.find<DatabaseController>();
```

### فوائد lazyPut

```dart
class ExpensiveController extends SintController {
  ExpensiveController() {
    print('إنشاء متحكم مكلف...');
    // عمليات مكلفة
  }
}

// في صفحة التطبيق الرئيسية
void setupDependencies() {
  // لا يتم إنشاء المتحكمات الآن
  Sint.lazyPut(() => ExpensiveController());
  Sint.lazyPut(() => AnotherController());
  Sint.lazyPut(() => HeavyController());
}

// يتم الإنشاء فقط عند الحاجة
final controller = Sint.find<ExpensiveController>(); // الآن يتم الإنشاء
```

### معامل fenix

```dart
// عند الحذف التلقائي، يمكن إعادة الإنشاء
Sint.lazyPut(() => UserController(), fenix: true);

// حتى لو تم حذفه، سيتم إعادة إنشائه عند الطلب
final user = Sint.find<UserController>();
```

## Sint.putAsync

لحقن التبعيات التي تحتاج إلى عمليات غير متزامنة:

```dart
class DatabaseService extends SintController {
  Database? db;

  Future<DatabaseService> init() async {
    db = await openDatabase('app.db');
    return this;
  }
}

// انتظار اكتمال التهيئة
await Sint.putAsync(() async {
  final service = DatabaseService();
  await service.init();
  return service;
});

// الآن يمكن استخدام الخدمة
final db = Sint.find<DatabaseService>();
```

### مثال متقدم

```dart
Future<void> initServices() async {
  // خدمة التخزين
  await Sint.putAsync(() async {
    final storage = StorageService();
    await storage.init();
    return storage;
  });

  // خدمة المصادقة (تعتمد على التخزين)
  await Sint.putAsync(() async {
    final auth = AuthService();
    await auth.loadSavedUser();
    return auth;
  });

  // خدمة API (تعتمد على المصادقة)
  await Sint.putAsync(() async {
    final api = ApiService();
    await api.configure();
    return api;
  });
}
```

## Sint.create

ينشئ نسخة جديدة في كل مرة يتم طلبها:

```dart
class FormController extends SintController {
  var name = ''.obs;
  var email = ''.obs;

  void clearForm() {
    name.value = '';
    email.value = '';
  }
}

// تسجيل Factory
Sint.create(() => FormController());

// كل استدعاء ينشئ نسخة جديدة
final form1 = Sint.find<FormController>(); // نسخة 1
final form2 = Sint.find<FormController>(); // نسخة 2 (مختلفة)

print(form1 == form2); // false
```

### حالات الاستخدام

```dart
// للنماذج المتعددة في نفس الصفحة
class AddressFormPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AddressForm(title: 'عنوان الشحن'),
          AddressForm(title: 'عنوان الفواتير'),
        ],
      ),
    );
  }
}

class AddressForm extends StatelessWidget {
  final String title;
  final controller = Sint.find<FormController>(); // نسخة فريدة لكل نموذج

  AddressForm({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title),
        TextField(onChanged: (v) => controller.name.value = v),
      ],
    );
  }
}
```

## Sint.find

للوصول إلى التبعيات المحقونة:

```dart
// الوصول البسيط
final controller = Sint.find<MyController>();

// مع معرف
final controller = Sint.find<MyController>(tag: 'special');
```

### التحقق من الوجود

```dart
// استخدام isRegistered للتحقق
if (Sint.isRegistered<MyController>()) {
  final controller = Sint.find<MyController>();
  controller.doSomething();
} else {
  print('المتحكم غير موجود');
}
```

## Bindings

Bindings تسمح لك بتنظيم التبعيات بشكل أفضل:

```dart
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Sint.lazyPut(() => HomeController());
    Sint.lazyPut(() => ProductController());
    Sint.lazyPut(() => CartController());
  }
}

// استخدام مع التوجيه
Sint.to(
  HomePage(),
  binding: HomeBinding(),
);
```

### BindingsBuilder

```dart
// بدون إنشاء صنف منفصل
Sint.to(
  ProfilePage(),
  binding: BindingsBuilder(() {
    Sint.lazyPut(() => ProfileController());
    Sint.lazyPut(() => SettingsController());
  }),
);
```

### Bindings في المسارات

```dart
final routes = [
  SintPage(
    name: '/home',
    page: () => HomePage(),
    binding: HomeBinding(),
  ),
  SintPage(
    name: '/profile',
    page: () => ProfilePage(),
    binding: ProfileBinding(),
  ),
];
```

## SmartManagement

يتحكم في كيفية إدارة دورة حياة التبعيات:

```dart
void main() {
  runApp(
    SintMaterialApp(
      smartManagement: SmartManagement.full,
      home: HomePage(),
    ),
  );
}
```

### أنواع SmartManagement

#### 1. SmartManagement.full (الافتراضي)

```dart
// يحذف المتحكمات غير المستخدمة تلقائياً
smartManagement: SmartManagement.full
```

#### 2. SmartManagement.onlyBuilder

```dart
// يحذف فقط المتحكمات المستخدمة في SintBuilder
smartManagement: SmartManagement.onlyBuilder
```

#### 3. SmartManagement.keepFactory

```dart
// يحافظ على المتحكمات المنشأة بـ Sint.create
smartManagement: SmartManagement.keepFactory
```

## SintController

للخدمات التي يجب أن تبقى طوال عمر التطبيق:

```dart
class AnalyticsService extends SintController {
  Future<AnalyticsService> init() async {
    print('تهيئة خدمة التحليلات');
    return this;
  }

  void logEvent(String event) {
    print('تسجيل حدث: $event');
  }

  @override
  void onClose() {
    print('إغلاق خدمة التحليلات');
    super.onClose();
  }
}

// حقن الخدمة
await Sint.putAsync(() => AnalyticsService().init());

// استخدام الخدمة في أي مكان
Sint.find<AnalyticsService>().logEvent('user_login');
```

## إزالة التبعيات

### حذف متحكم واحد

```dart
Sint.delete<MyController>();

// مع معرف
Sint.delete<MyController>(tag: 'special');
```

### حذف عند التوجيه

```dart
// حذف تلقائي عند مغادرة الصفحة
final controller = Sint.put(PageController());

Sint.to(NextPage());
// PageController سيتم حذفه تلقائياً
```

### منع الحذف التلقائي

```dart
Sint.put(ImportantController(), permanent: true);

// أو
class ImportantController extends SintController {
  @override
  void onClose() {
    // لن يتم استدعاؤه إذا كان permanent: true
    super.onClose();
  }
}
```

### reset و resetAll

```dart
// حذف جميع التبعيات
Sint.reset();

// حذف جميع التبعيات وإعادة التهيئة
Sint.resetAll();
```

## أنماط الاستخدام المتقدمة

### 1. الحقن الهرمي

```dart
class ParentController extends SintController {
  final child = Sint.find<ChildController>();

  void useChild() {
    child.doSomething();
  }
}

class ChildController extends SintController {
  void doSomething() {
    print('عمل شيء ما');
  }
}

// الترتيب مهم
Sint.put(ChildController());
Sint.put(ParentController());
```

### 2. Lazy Singleton Pattern

```dart
class ConfigService extends SintController {
  static ConfigService get instance => Sint.find();

  String apiUrl = '';

  Future<void> loadConfig() async {
    apiUrl = await fetchFromServer();
  }
}

// التهيئة
Sint.lazyPut(() => ConfigService());

// الاستخدام
final config = ConfigService.instance;
```

### 3. Factory مع معاملات

```dart
class ReportController extends SintController {
  final String reportType;

  ReportController(this.reportType);

  void generate() {
    print('إنشاء تقرير: $reportType');
  }
}

// استخدام create مع معاملات
Sint.create(() => ReportController('monthly'));

final monthly = Sint.find<ReportController>();
monthly.generate();
```

## أفضل الممارسات

### 1. استخدم lazyPut للأداء

```dart
// جيد - تحميل كسول
class AppBinding extends Bindings {
  @override
  void dependencies() {
    Sint.lazyPut(() => HeavyController());
  }
}

// سيء - تحميل فوري لجميع المتحكمات
class AppBinding extends Bindings {
  @override
  void dependencies() {
    Sint.put(HeavyController());
  }
}
```

### 2. استخدم SintController للخدمات الدائمة

```dart
// جيد
class ApiService extends SintController {
  // خدمة دائمة
}

// سيء - المتحكم العادي قد يتم حذفه
class ApiService extends SintController {
  // قد يتم حذفه تلقائياً
}
```

### 3. نظم التبعيات بـ Bindings

```dart
// جيد - منظم وواضح
class UserBinding extends Bindings {
  @override
  void dependencies() {
    Sint.lazyPut(() => UserController());
    Sint.lazyPut(() => ProfileController());
  }
}

// سيء - حقن مباشر في كل مكان
class UserPage extends StatelessWidget {
  final controller = Sint.put(UserController());
}
```

### 4. تجنب الحقن الدائري

```dart
// سيء - اعتماد دائري
class AController extends SintController {
  final b = Sint.find<BController>(); // يحتاج B
}

class BController extends SintController {
  final a = Sint.find<AController>(); // يحتاج A
}

// جيد - استخدام الحقن الكسول
class AController extends SintController {
  BController get b => Sint.find<BController>();
}
```

## خارطة طريق الاختبارات

### اختبار الحقن الأساسي

```dart
void main() {
  setUp(() {
    // تنظيف قبل كل اختبار
    Sint.reset();
  });

  test('يجب أن يحقن المتحكم', () {
    final controller = Sint.put(TestController());
    expect(Sint.isRegistered<TestController>(), true);
  });

  test('يجب أن يجد المتحكم المحقون', () {
    Sint.put(TestController());
    final found = Sint.find<TestController>();
    expect(found, isNotNull);
  });
}
```

### اختبار lazyPut

```dart
test('يجب أن لا ينشئ المتحكم مباشرة', () {
  bool created = false;

  Sint.lazyPut(() {
    created = true;
    return TestController();
  });

  expect(created, false);

  Sint.find<TestController>();
  expect(created, true);
});
```

### اختبار putAsync

```dart
test('يجب أن ينتظر التهيئة غير المتزامنة', () async {
  await Sint.putAsync(() async {
    final service = AsyncService();
    await service.init();
    return service;
  });

  final service = Sint.find<AsyncService>();
  expect(service.isInitialized, true);
});
```

### اختبار create (Factory)

```dart
test('يجب أن ينشئ نسخ مختلفة', () {
  Sint.create(() => TestController());

  final instance1 = Sint.find<TestController>();
  final instance2 = Sint.find<TestController>();

  expect(instance1 == instance2, false);
});
```

### اختبار Bindings

```dart
testWidgets('يجب أن يحقن التبعيات عبر Bindings', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(
      home: HomePage(),
      initialBinding: HomeBinding(),
    ),
  );

  expect(Sint.isRegistered<HomeController>(), true);
});
```

### اختبار دورة الحياة

```dart
test('يجب أن يحذف المتحكم', () {
  Sint.put(TestController());
  expect(Sint.isRegistered<TestController>(), true);

  Sint.delete<TestController>();
  expect(Sint.isRegistered<TestController>(), false);
});

test('يجب أن لا يحذف المتحكم الدائم', () {
  Sint.put(TestController(), permanent: true);

  Sint.delete<TestController>();
  expect(Sint.isRegistered<TestController>(), true);
});
```

### اختبار SmartManagement

```dart
testWidgets('يجب أن يحذف المتحكمات تلقائياً', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(
      smartManagement: SmartManagement.full,
      home: FirstPage(),
    ),
  );

  Sint.put(FirstPageController());
  expect(Sint.isRegistered<FirstPageController>(), true);

  Sint.to(SecondPage());
  await tester.pumpAndSettle();

  expect(Sint.isRegistered<FirstPageController>(), false);
});
```

### استراتيجية الاختبار الشاملة

1. **اختبار الحقن**: التحقق من put, lazyPut, putAsync, create
2. **اختبار البحث**: التحقق من find مع وبدون tags
3. **اختبار دورة الحياة**: التحقق من delete و permanent
4. **اختبار Bindings**: التحقق من dependencies
5. **اختبار SmartManagement**: التحقق من الحذف التلقائي
6. **اختبار التبعيات المتداخلة**: التحقق من ترتيب الحقن
7. **اختبار SintController**: التحقق من الخدمات الدائمة
8. **اختبار معالجة الأخطاء**: التحقق من السلوك عند التبعيات المفقودة
