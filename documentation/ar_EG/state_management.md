# ادارة الحالة

## المقدمة

إدارة الحالة هي أحد الأعمدة الأربعة الأساسية لإطار عمل SINT. توفر SINT طريقتين قويتين لإدارة الحالة في تطبيقات Flutter: مدير الحالة التفاعلي (Reactive State Manager) ومدير الحالة البسيط (Simple State Manager).

## مدير الحالة التفاعلي

### المتغيرات التفاعلية (.obs)

يمكنك جعل أي متغير تفاعلياً باستخدام `.obs`:

```dart
var name = 'John'.obs;
var age = 25.obs;
var isLogged = false.obs;
var balance = 0.0.obs;
var items = <String>[].obs;
var myMap = <String, int>{}.obs;
```

### استخدام Obx

`Obx` هو أداة بناء تفاعلية تعيد بناء الواجهة تلقائياً عند تغيير المتغيرات التفاعلية:

```dart
class Controller extends SintController {
  var count = 0.obs;

  void increment() => count++;
}

class HomePage extends StatelessWidget {
  final controller = Sint.put(Controller());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Obx(() => Text('Count: ${controller.count}')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.increment,
        child: Icon(Icons.add),
      ),
    );
  }
}
```

### Rx Types

SINT توفر أنواع Rx متخصصة:

```dart
// للنصوص
final name = RxString('');
// للأعداد الصحيحة
final count = RxInt(0);
// للأعداد العشرية
final price = RxDouble(0.0);
// للقيم المنطقية
final isActive = RxBool(false);
// للقوائم
final items = RxList<String>([]);
// للخرائط
final data = RxMap<String, dynamic>({});
```

### التحديث المتقدم

```dart
class User {
  String name;
  int age;
  User({required this.name, required this.age});
}

final user = User(name: 'Ali', age: 30).obs;

// التحديث الصحيح للكائنات المعقدة
void updateUser() {
  user.update((val) {
    val!.name = 'Ahmed';
    val.age = 35;
  });
}
```

## مدير الحالة البسيط

### SintBuilder

للحالات التي لا تحتاج إلى التفاعلية الكاملة، استخدم `SintBuilder`:

```dart
class CounterController extends SintController {
  int count = 0;

  void increment() {
    count++;
    update(); // إعلام الواجهة بالتحديث
  }

  void incrementWithId() {
    count++;
    update(['counter']); // تحديث معرف محدد فقط
  }
}

class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SintBuilder<CounterController>(
        init: CounterController(),
        builder: (controller) {
          return Center(
            child: Text('Count: ${controller.count}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Sint.find<CounterController>().increment(),
        child: Icon(Icons.add),
      ),
    );
  }
}
```

### التحديث باستخدام المعرفات

```dart
SintBuilder<CounterController>(
  id: 'counter',
  builder: (controller) {
    return Text('${controller.count}');
  },
)

// في المتحكم
update(['counter']); // تحديث الأدوات التي لديها id='counter' فقط
```

## StateMixin

`StateMixin` يوفر طريقة سهلة للتعامل مع حالات التحميل والنجاح والخطأ:

```dart
class DataController extends SintController with StateMixin<List<User>> {
  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  void fetchUsers() async {
    change(null, status: RxStatus.loading());

    try {
      final users = await apiService.getUsers();

      if (users.isEmpty) {
        change(null, status: RxStatus.empty());
      } else {
        change(users, status: RxStatus.success());
      }
    } catch (e) {
      change(null, status: RxStatus.error(e.toString()));
    }
  }
}
```

### استخدام StateMixin في الواجهة

```dart
class UsersPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('المستخدمون')),
      body: SintBuilder<DataController>(
        init: DataController(),
        builder: (controller) {
          return controller.obx(
            (users) => ListView.builder(
              itemCount: users!.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(users[index].name),
                );
              },
            ),
            onLoading: Center(child: CircularProgressIndicator()),
            onEmpty: Center(child: Text('لا يوجد مستخدمون')),
            onError: (error) => Center(child: Text('خطأ: $error')),
          );
        },
      ),
    );
  }
}
```

## Workers

Workers تسمح لك بالاستماع إلى التغييرات في المتغيرات التفاعلية:

### ever

يتم تنفيذه في كل مرة يتغير فيها المتغير:

```dart
class MyController extends SintController {
  var name = ''.obs;

  @override
  void onInit() {
    ever(name, (value) {
      print('تغير الاسم إلى: $value');
    });
    super.onInit();
  }
}
```

### once

يتم تنفيذه مرة واحدة فقط عند أول تغيير:

```dart
once(count, (value) {
  print('تم تغيير العداد لأول مرة: $value');
});
```

### debounce

يتم تنفيذه بعد فترة من عدم التغيير (مفيد للبحث):

```dart
debounce(
  searchText,
  (value) {
    performSearch(value);
  },
  time: Duration(milliseconds: 500),
);
```

### interval

يتم تنفيذه فقط إذا كانت هناك فترة زمنية معينة بين التغييرات:

```dart
interval(
  scrollPosition,
  (value) {
    loadMoreData();
  },
  time: Duration(seconds: 1),
);
```

## دورة حياة المتحكم

```dart
class LifecycleController extends SintController {
  @override
  void onInit() {
    super.onInit();
    print('تم إنشاء المتحكم');
    // تهيئة البيانات، الاستماع للأحداث
  }

  @override
  void onReady() {
    super.onReady();
    print('المتحكم جاهز');
    // يتم استدعاؤه بعد عرض الواجهة
  }

  @override
  void onClose() {
    print('تم إغلاق المتحكم');
    // تنظيف الموارد، إلغاء الاشتراكات
    super.onClose();
  }
}
```

## أفضل الممارسات

### 1. اختيار الطريقة المناسبة

```dart
// استخدم Obx للتفاعلية السريعة
Obx(() => Text('${controller.count.value}'))

// استخدم SintBuilder للأداء الأفضل في الواجهات المعقدة
SintBuilder<Controller>(
  builder: (c) => ComplexWidget(data: c.data),
)
```

### 2. تجنب إعادة البناء غير الضرورية

```dart
// سيء - يعيد بناء كل الواجهة
Obx(() => Column(
  children: [
    Text('${controller.count}'),
    ExpensiveWidget(),
  ],
))

// جيد - يعيد بناء النص فقط
Column(
  children: [
    Obx(() => Text('${controller.count}')),
    ExpensiveWidget(),
  ],
)
```

### 3. استخدام Workers بحكمة

```dart
@override
void onInit() {
  super.onInit();

  // تذكر أن Workers يتم التخلص منها تلقائياً
  ever(user, (user) {
    saveUserToDatabase(user);
  });
}
```

### 4. الفصل بين منطق العمل والواجهة

```dart
// جيد - المتحكم يحتوي على المنطق فقط
class UserController extends SintController {
  final userRepository = UserRepository();
  var users = <User>[].obs;

  Future<void> loadUsers() async {
    users.value = await userRepository.fetchUsers();
  }
}

// الواجهة تعرض البيانات فقط
class UserView extends StatelessWidget {
  final controller = Sint.put(UserController());

  @override
  Widget build(BuildContext context) {
    return Obx(() => ListView(
      children: controller.users.map((user) => UserTile(user)).toList(),
    ));
  }
}
```

## مقارنة الأداء

| الميزة | Obx | SintBuilder |
|--------|-----|-----------|
| السرعة | سريع جداً | سريع |
| استهلاك الذاكرة | منخفض | منخفض جداً |
| سهولة الاستخدام | عالية جداً | عالية |
| التفاعلية | تلقائية | يدوية |
| الأفضل لـ | التحديثات الصغيرة المتكررة | الواجهات المعقدة |

## خارطة طريق الاختبارات

### اختبار المتحكمات

```dart
void main() {
  test('يجب أن يزيد العداد', () {
    final controller = CounterController();
    controller.increment();
    expect(controller.count, 1);
  });

  test('يجب أن تعمل المتغيرات التفاعلية', () {
    final controller = MyController();
    controller.name.value = 'Ahmed';
    expect(controller.name.value, 'Ahmed');
  });
}
```

### اختبار StateMixin

```dart
test('يجب أن يعرض حالة التحميل', () async {
  final controller = DataController();
  expect(controller.status.isLoading, true);

  await Future.delayed(Duration(seconds: 1));
  expect(controller.status.isSuccess, true);
});
```

### اختبار Workers

```dart
test('يجب أن ينفذ ever عند التغيير', () {
  final controller = MyController();
  int callCount = 0;

  ever(controller.name, (_) => callCount++);

  controller.name.value = 'Ali';
  controller.name.value = 'Ahmed';

  expect(callCount, 2);
});
```

### اختبار الواجهة

```dart
testWidgets('يجب أن تحدث الواجهة عند تغيير الحالة', (tester) async {
  final controller = CounterController();
  Sint.put(controller);

  await tester.pumpWidget(
    SintMaterialApp(
      home: CounterPage(),
    ),
  );

  expect(find.text('Count: 0'), findsOneWidget);

  controller.increment();
  await tester.pump();

  expect(find.text('Count: 1'), findsOneWidget);
});
```

### استراتيجية الاختبار الشاملة

1. **اختبار الوحدة (Unit Tests)**: اختبار المتحكمات والمنطق
2. **اختبار الواجهة (Widget Tests)**: اختبار التفاعل بين الواجهة والحالة
3. **اختبار التكامل (Integration Tests)**: اختبار التدفق الكامل للتطبيق
4. **اختبار الأداء**: قياس سرعة التحديثات واستهلاك الذاكرة
5. **اختبار Workers**: التأكد من عمل المستمعين بشكل صحيح
6. **اختبار دورة الحياة**: التحقق من onInit, onReady, onClose
