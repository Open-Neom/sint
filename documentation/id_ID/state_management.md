# Manajemen State

SINT menyediakan sistem manajemen state yang kuat dan fleksibel untuk aplikasi Flutter Anda. Dengan tiga pendekatan berbeda, Anda dapat memilih solusi yang paling sesuai dengan kebutuhan Anda.

## Daftar Isi

- [Manajemen State Reaktif](#manajemen-state-reaktif)
- [Manajemen State Sederhana](#manajemen-state-sederhana)
- [StateMixin](#statemixin)
- [Workers](#workers)
- [Peta Pengujian](#peta-pengujian)

## Manajemen State Reaktif

Manajemen state reaktif menggunakan `Rx` types dan `.obs` untuk membuat variabel yang dapat diamati (observable).

### Variabel Observable

```dart
class Controller extends SintController {
  var count = 0.obs;
  var name = ''.obs;
  var isLogged = false.obs;
  var user = User().obs;
  var list = <String>[].obs;
}
```

### Widget Obx

Widget `Obx` secara otomatis membangun ulang ketika variabel observable berubah:

```dart
class CounterPage extends StatelessWidget {
  final Controller controller = Sint.put(Controller());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Obx(() => Text(
          'Nilai: ${controller.count}',
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

### GetX Widget

`GetX` adalah widget yang menggabungkan manajemen state dan dependency injection:

```dart
GetX<Controller>(
  init: Controller(),
  builder: (controller) {
    return Text('Nilai: ${controller.count}');
  },
)
```

### Tipe Data Reaktif

SINT mendukung berbagai tipe data reaktif:

```dart
// Tipe primitif
var myInt = 0.obs;
var myDouble = 0.0.obs;
var myString = ''.obs;
var myBool = false.obs;

// List, Map, dan Set
var myList = <String>[].obs;
var myMap = <String, int>{}.obs;
var mySet = <int>{}.obs;

// Objek kustom
var myUser = User().obs;

// Mengakses nilai
print(myInt.value);
myString.value = 'Hello';
myUser.value = User(name: 'John');

// Update List
myList.add('item');
myList.remove('item');

// Update Map
myMap['key'] = 123;
```

### Metode Update untuk Objek

Untuk objek kompleks, gunakan metode `update()`:

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
      val?.name = 'John Doe';
      val?.age = 30;
    });
  }
}
```

## Manajemen State Sederhana

Untuk kasus yang lebih sederhana, gunakan `SintBuilder` tanpa overhead reaktivitas:

```dart
class Controller extends SintController {
  int count = 0;

  void increment() {
    count++;
    update(); // Panggil update untuk membangun ulang UI
  }

  void incrementWithId() {
    count++;
    update(['counter_text']); // Update hanya widget dengan ID tertentu
  }
}
```

### SintBuilder Widget

```dart
SintBuilder<Controller>(
  init: Controller(),
  builder: (controller) {
    return Text('Nilai: ${controller.count}');
  },
)
```

### SintBuilder dengan ID

Untuk kontrol yang lebih granular:

```dart
SintBuilder<Controller>(
  id: 'counter_text',
  builder: (controller) {
    return Text('Nilai: ${controller.count}');
  },
)

SintBuilder<Controller>(
  id: 'counter_button',
  builder: (controller) {
    return ElevatedButton(
      onPressed: controller.increment,
      child: Text('Tambah'),
    );
  },
)
```

## StateMixin

`StateMixin` menyediakan cara untuk mengelola berbagai state seperti loading, error, dan success:

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

### Menggunakan StateMixin dalam Widget

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
            onError: (error) => Center(child: Text('Error: $error')),
            onEmpty: Center(child: Text('Tidak ada data')),
          );
        },
      ),
    );
  }
}
```

### Status RxStatus

```dart
RxStatus.loading()
RxStatus.success()
RxStatus.error([String? message])
RxStatus.empty()
```

## Workers

Workers adalah callbacks reaktif yang dipanggil ketika event terjadi:

### ever

Dipanggil setiap kali variabel berubah:

```dart
class Controller extends SintController {
  var count = 0.obs;

  @override
  void onInit() {
    ever(count, (value) {
      print('Count berubah menjadi $value');
    });
    super.onInit();
  }
}
```

### once

Dipanggil hanya sekali ketika variabel berubah untuk pertama kalinya:

```dart
once(count, (value) {
  print('Count berubah untuk pertama kalinya: $value');
});
```

### debounce

Dipanggil setelah user berhenti membuat perubahan untuk durasi tertentu:

```dart
debounce(searchQuery, (value) {
  performSearch(value);
}, time: Duration(milliseconds: 800));
```

### interval

Mengabaikan perubahan selama periode tertentu:

```dart
interval(position, (value) {
  updateLocation(value);
}, time: Duration(seconds: 1));
```

### Membatalkan Workers

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

## Best Practices

### 1. Pilih Pendekatan yang Tepat

- Gunakan **Reactive** untuk UI yang kompleks dengan banyak perubahan state
- Gunakan **Simple** untuk widget yang jarang diupdate
- Gunakan **StateMixin** untuk operasi async dengan berbagai state

### 2. Hindari Nested Obx

Jangan:

```dart
Obx(() => Column(
  children: [
    Obx(() => Text(controller.name.value)), // Buruk
    Obx(() => Text(controller.email.value)), // Buruk
  ],
))
```

Lakukan:

```dart
Obx(() => Column(
  children: [
    Text(controller.name.value),
    Text(controller.email.value),
  ],
))
```

### 3. Gunakan SintBuilder untuk Widget Statis

Jika widget tidak perlu reactive update, jangan wrap dengan Obx:

```dart
// Jangan
Obx(() => Container(
  color: Colors.blue, // Warna tidak berubah
  child: Text(controller.count.value.toString()),
))

// Lakukan
Container(
  color: Colors.blue,
  child: Obx(() => Text(controller.count.value.toString())),
)
```

### 4. Dispose Workers

Selalu dispose workers di `onClose()`:

```dart
@override
void onClose() {
  myWorker.dispose();
  super.onClose();
}
```

## Peta Pengujian

### Unit Tests

```dart
test('Counter increment test', () {
  final controller = Controller();

  // Test nilai awal
  expect(controller.count.value, 0);

  // Test increment
  controller.increment();
  expect(controller.count.value, 1);
});

test('StateMixin loading state', () {
  final controller = UserController();

  // Verify initial state
  expect(controller.status.isLoading, true);
});
```

### Widget Tests

```dart
testWidgets('Obx widget updates on observable change', (tester) async {
  final controller = Controller();
  Sint.put(controller);

  await tester.pumpWidget(
    MaterialApp(
      home: Obx(() => Text('${controller.count}')),
    ),
  );

  // Verify initial text
  expect(find.text('0'), findsOneWidget);

  // Update observable
  controller.count++;
  await tester.pump();

  // Verify updated text
  expect(find.text('1'), findsOneWidget);
});

testWidgets('SintBuilder updates on update() call', (tester) async {
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

### Integration Tests

```dart
testWidgets('Full user flow with state management', (tester) async {
  await tester.pumpWidget(MyApp());

  // Tap login button
  await tester.tap(find.byKey(Key('login_button')));
  await tester.pumpAndSettle();

  // Verify loading indicator
  expect(find.byType(CircularProgressIndicator), findsOneWidget);

  // Wait for async operation
  await tester.pumpAndSettle(Duration(seconds: 2));

  // Verify success state
  expect(find.text('Welcome'), findsOneWidget);
});
```

### Worker Tests

```dart
test('ever worker fires on every change', () {
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

test('debounce worker delays execution', () async {
  final controller = Controller();
  int callCount = 0;

  debounce(controller.searchQuery, (_) {
    callCount++;
  }, time: Duration(milliseconds: 500));

  controller.searchQuery.value = 'a';
  controller.searchQuery.value = 'ab';
  controller.searchQuery.value = 'abc';

  expect(callCount, 0); // Belum dipanggil

  await Future.delayed(Duration(milliseconds: 600));
  expect(callCount, 1); // Dipanggil sekali setelah debounce
});
```

### Mock Testing

```dart
class MockApi extends Mock implements ApiService {}

test('UserController handles API errors', () async {
  final mockApi = MockApi();
  final controller = UserController(api: mockApi);

  when(mockApi.getUser()).thenThrow(Exception('Network error'));

  controller.fetchUser();
  await Future.delayed(Duration.zero);

  expect(controller.status.isError, true);
  expect(controller.status.errorMessage, contains('Network error'));
});
```
