# 状態管理

SINTは、Flutterアプリケーションの状態管理に対して、シンプルかつ強力なソリューションを提供します。リアクティブプログラミング、シンプルな状態更新、ステータス管理など、複数のアプローチをサポートしています。

## リアクティブ状態管理

### Observable変数 (.obs)

SINTでは、任意の変数を`.obs`を使用してリアクティブにすることができます。

```dart
var count = 0.obs;
var name = ''.obs;
var isLogged = false.obs;
var balance = 0.0.obs;
var items = <String>[].obs;
var user = User().obs;
```

### Obxウィジェット

`Obx`ウィジェットは、observable変数の変更を自動的に監視し、UIを更新します。

```dart
class CounterPage extends StatelessWidget {
  final count = 0.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('カウンター')),
      body: Center(
        child: Obx(() => Text(
          'クリック回数: ${count.value}',
          style: TextStyle(fontSize: 24),
        )),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => count.value++,
        child: Icon(Icons.add),
      ),
    );
  }
}
```

### SintController

より複雑な状態管理には、`SintController`を使用します。

```dart
class CounterController extends SintController {
  final count = 0.obs;

  void increment() => count.value++;
  void decrement() => count.value--;
  void reset() => count.value = 0;
}

// 使用方法
class CounterPage extends StatelessWidget {
  final controller = Sint.put(CounterController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Obx(() => Text('カウント: ${controller.count.value}')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.increment,
        child: Icon(Icons.add),
      ),
    );
  }
}
```

### ライフサイクルメソッド

```dart
class LifecycleController extends SintController {
  @override
  void onInit() {
    super.onInit();
    print('コントローラーが初期化されました');
  }

  @override
  void onReady() {
    super.onReady();
    print('コントローラーの準備が完了しました');
  }

  @override
  void onClose() {
    print('コントローラーが破棄されます');
    super.onClose();
  }
}
```

## シンプル状態管理

### SintBuilder

リアクティブ性が不要で、手動で更新したい場合は`SintBuilder`を使用します。

```dart
class SimpleController extends SintController {
  int count = 0;

  void increment() {
    count++;
    update(); // UIを更新
  }

  void incrementWithId() {
    count++;
    update(['counter']); // 特定のIDのみを更新
  }
}

// 使用方法
class SimplePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SintBuilder<SimpleController>(
        init: SimpleController(),
        builder: (controller) {
          return Text('カウント: ${controller.count}');
        },
      ),
    );
  }
}
```

### IDを使用した更新

```dart
SintBuilder<SimpleController>(
  id: 'counter',
  builder: (controller) {
    return Text('カウント: ${controller.count}');
  },
)
```

## StateMixin

`StateMixin`は、API呼び出しやデータ読み込みの状態を管理するための便利な方法です。

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
      final user = await userRepository.getUser();
      change(user, status: RxStatus.success());
    } catch (e) {
      change(null, status: RxStatus.error('ユーザーの取得に失敗しました'));
    }
  }
}

// 使用方法
class UserPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SintBuilder<UserController>(
        init: UserController(),
        builder: (controller) {
          return controller.obx(
            (user) => UserProfile(user: user),
            onLoading: CircularProgressIndicator(),
            onError: (error) => Text('エラー: $error'),
            onEmpty: Text('ユーザーが見つかりません'),
          );
        },
      ),
    );
  }
}
```

### StateMixinの状態

- `RxStatus.loading()` - データ読み込み中
- `RxStatus.success()` - データ読み込み成功
- `RxStatus.error(message)` - エラー発生
- `RxStatus.empty()` - データが空

## Workers

Workersは、observable変数の変更に反応するリスナーです。

### ever

値が変更されるたびに呼び出されます。

```dart
class WorkerController extends SintController {
  final count = 0.obs;

  @override
  void onInit() {
    super.onInit();

    ever(count, (value) {
      print('カウントが変更されました: $value');
    });
  }
}
```

### once

最初の変更時のみ呼び出されます。

```dart
once(count, (value) {
  print('カウントが初めて変更されました: $value');
});
```

### debounce

ユーザーが入力を停止してから指定時間後に呼び出されます。

```dart
final searchText = ''.obs;

debounce(searchText, (value) {
  // 検索APIを呼び出す
  performSearch(value);
}, time: Duration(milliseconds: 500));
```

### interval

変更がある限り、指定間隔で呼び出されます。

```dart
interval(count, (value) {
  print('インターバル更新: $value');
}, time: Duration(seconds: 1));
```

## ベストプラクティス

### 1. コントローラーの分離

```dart
// 良い例
class UserController extends SintController {
  final userRepository = Sint.find<UserRepository>();
  final user = Rx<User?>(null);

  Future<void> loadUser(String id) async {
    user.value = await userRepository.getUser(id);
  }
}

// 悪い例 - ビジネスロジックがUI内にある
class UserPage extends StatelessWidget {
  final user = Rx<User?>(null);

  void loadUser() async {
    user.value = await http.get(...); // UIとロジックが混在
  }
}
```

### 2. リソースの適切な破棄

```dart
class ResourceController extends SintController {
  final streamController = StreamController();
  final timer = Timer.periodic(Duration(seconds: 1), (_) {});

  @override
  void onClose() {
    streamController.close();
    timer.cancel();
    super.onClose();
  }
}
```

### 3. SintBuilderとObxの使い分け

```dart
// 頻繁に更新される場合はSintBuilderを使用
SintBuilder<CounterController>(
  builder: (controller) => Text('${controller.count}'),
)

// シンプルな状態にはObxを使用
Obx(() => Text('${count.value}'))
```

## テストロードマップ

### 単体テスト

```dart
void main() {
  test('カウンターのインクリメント', () {
    final controller = CounterController();
    expect(controller.count.value, 0);

    controller.increment();
    expect(controller.count.value, 1);
  });

  test('StateMixinの状態変化', () async {
    final controller = UserController();

    expect(controller.status.isLoading, false);
    controller.fetchUser();
    expect(controller.status.isLoading, true);

    await Future.delayed(Duration(milliseconds: 100));
    expect(controller.status.isSuccess, true);
  });
}
```

### ウィジェットテスト

```dart
void main() {
  testWidgets('Obxウィジェットの更新', (tester) async {
    final controller = Sint.put(CounterController());

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Obx(() => Text('${controller.count.value}')),
      ),
    ));

    expect(find.text('0'), findsOneWidget);

    controller.increment();
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
  });
}
```

### 統合テスト

```dart
void main() {
  testWidgets('完全なユーザーフロー', (tester) async {
    await tester.pumpWidget(MyApp());

    // 初期状態の確認
    expect(find.text('カウント: 0'), findsOneWidget);

    // ボタンをタップ
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // 更新された状態を確認
    expect(find.text('カウント: 1'), findsOneWidget);
  });
}
```

### モックとスタブ

```dart
class MockUserRepository extends SintController implements UserRepository {
  @override
  Future<User> getUser(String id) async {
    return User(id: id, name: 'テストユーザー');
  }
}

void main() {
  setUp(() {
    Sint.put<UserRepository>(MockUserRepository());
  });

  test('モックリポジトリを使用', () async {
    final controller = UserController();
    await controller.fetchUser();

    expect(controller.state?.name, 'テストユーザー');
  });
}
```
