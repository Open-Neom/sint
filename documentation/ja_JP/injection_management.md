# 依存性注入管理

SINTは、依存性注入（DI）のための強力でシンプルなシステムを提供します。これにより、アプリケーション全体でインスタンスを簡単に管理および共有できます。

## 基本的な依存性注入

### Sint.put

インスタンスを即座に作成し、アプリケーション全体で利用可能にします。

```dart
class ApiController extends SintController {
  void fetchData() {
    print('データを取得中...');
  }
}

// 依存性を注入
Sint.put(ApiController());

// どこからでもアクセス可能
final controller = Sint.find<ApiController>();
controller.fetchData();
```

### Sint.lazyPut

インスタンスを遅延初期化します。最初に`Sint.find()`が呼ばれるまでインスタンスは作成されません。

```dart
Sint.lazyPut(() => DatabaseController());

// この時点でインスタンスが作成される
final db = Sint.find<DatabaseController>();
```

### Sint.putAsync

非同期でインスタンスを作成します。

```dart
Sint.putAsync<SharedPreferences>(() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs;
});

// 使用時
final prefs = await Sint.findAsync<SharedPreferences>();
```

### Sint.create

`Sint.find()`が呼ばれるたびに新しいインスタンスを作成します。

```dart
Sint.create(() => TransactionController());

final transaction1 = Sint.find<TransactionController>();
final transaction2 = Sint.find<TransactionController>();
// transaction1とtransaction2は異なるインスタンス
```

## インスタンスの検索

### Sint.find

登録された依存性を取得します。

```dart
final controller = Sint.find<UserController>();
```

### タグ付きインスタンス

同じ型の複数のインスタンスを管理できます。

```dart
Sint.put(ApiController(), tag: 'products');
Sint.put(ApiController(), tag: 'users');

final productsApi = Sint.find<ApiController>(tag: 'products');
final usersApi = Sint.find<ApiController>(tag: 'users');
```

## インスタンスの削除

### Sint.delete

特定のインスタンスを削除します。

```dart
Sint.delete<UserController>();

// タグ付きインスタンスの削除
Sint.delete<ApiController>(tag: 'products');
```

### Sint.reset

すべての登録された依存性を削除します。

```dart
Sint.reset();
```

## Bindings

Bindingsは、依存性をグループ化して管理するためのクラスです。

### 基本的なBinding

```dart
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Sint.lazyPut(() => HomeController());
    Sint.lazyPut(() => ProductService());
    Sint.lazyPut(() => CartController());
  }
}

// ルートで使用
Sint.to(HomePage(), binding: HomeBinding());
```

### 複数のBindings

```dart
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // グローバルな依存性
    Sint.put(AuthService(), permanent: true);
    Sint.put(StorageService(), permanent: true);
  }
}

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Sint.lazyPut(() => HomeController());
  }
}

// アプリの起動時
void main() {
  runApp(SintMaterialApp(
    initialBinding: InitialBinding(),
    home: HomePage(),
  ));
}
```

### BindingsBuilderの使用

```dart
BindingsBuilder(() {
  Sint.lazyPut(() => Controller1());
  Sint.lazyPut(() => Controller2());
})
```

## SmartManagement

SINTは、依存性のライフサイクルを自動的に管理します。

### SmartManagement.full（デフォルト）

使用されていないコントローラーを自動的に破棄します。

```dart
SintMaterialApp(
  smartManagement: SmartManagement.full,
)
```

### SmartManagement.onlyBuilder

`SintBuilder`、`GetX`、`Obx`でのみ使用されるコントローラーを管理します。

```dart
SintMaterialApp(
  smartManagement: SmartManagement.onlyBuilder,
)
```

### SmartManagement.keepFactory

ファクトリー（`Sint.create`）のみを保持します。

```dart
SintMaterialApp(
  smartManagement: SmartManagement.keepFactory,
)
```

## 永続的な依存性

### permanent パラメータ

自動的に削除されないインスタンスを作成します。

```dart
Sint.put(AuthService(), permanent: true);
Sint.put(ConfigService(), permanent: true);
```

これらのインスタンスは、明示的に削除されるまで存続します。

```dart
Sint.delete<AuthService>(force: true);
```

## 実践例

### サービスレイヤーアーキテクチャ

```dart
// Services
class ApiService extends SintController {
  Future<Response> get(String url) async {
    // APIリクエスト
  }
}

class StorageService extends SintController {
  Future<void> save(String key, dynamic value) async {
    // データ保存
  }
}

// Repository
class UserRepository {
  final ApiService api = Sint.find();
  final StorageService storage = Sint.find();

  Future<User> getUser(String id) async {
    final response = await api.get('/users/$id');
    return User.fromJson(response.body);
  }
}

// Controller
class UserController extends SintController {
  final UserRepository repository = Sint.find();
  final user = Rx<User?>(null);

  Future<void> loadUser(String id) async {
    user.value = await repository.getUser(id);
  }
}

// Binding
class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Services（永続的）
    Sint.put(ApiService(), permanent: true);
    Sint.put(StorageService(), permanent: true);

    // Repository
    Sint.lazyPut(() => UserRepository());

    // Controller
    Sint.lazyPut(() => UserController());
  }
}
```

### 環境別の設定

```dart
abstract class Environment {
  String get apiUrl;
  bool get debug;
}

class DevEnvironment extends Environment {
  @override
  String get apiUrl => 'https://dev.api.example.com';

  @override
  bool get debug => true;
}

class ProdEnvironment extends Environment {
  @override
  String get apiUrl => 'https://api.example.com';

  @override
  bool get debug => false;
}

// 設定
void configureApp({required bool isDev}) {
  if (isDev) {
    Sint.put<Environment>(DevEnvironment());
  } else {
    Sint.put<Environment>(ProdEnvironment());
  }
}

// 使用
class ApiService {
  final env = Sint.find<Environment>();

  void request() {
    print('API URL: ${env.apiUrl}');
  }
}
```

## ベストプラクティス

### 1. SintControllerの使用

長期間存続するサービスには`SintController`を使用します。

```dart
class DatabaseService extends SintController {
  @override
  void onInit() {
    super.onInit();
    // データベース初期化
  }

  @override
  void onClose() {
    // データベースクローズ
    super.onClose();
  }
}
```

### 2. 依存性の階層化

```dart
// 下位レイヤー（永続的）
Sint.put(HttpClient(), permanent: true);
Sint.put(DatabaseService(), permanent: true);

// 中位レイヤー（遅延読み込み）
Sint.lazyPut(() => UserRepository());
Sint.lazyPut(() => ProductRepository());

// 上位レイヤー（必要時に作成）
Sint.lazyPut(() => HomeController());
```

### 3. インターフェースの使用

```dart
abstract class IStorageService {
  Future<void> save(String key, dynamic value);
  Future<dynamic> read(String key);
}

class LocalStorageService implements IStorageService {
  @override
  Future<void> save(String key, dynamic value) async {
    // ローカルストレージに保存
  }

  @override
  Future<dynamic> read(String key) async {
    // ローカルストレージから読み込み
  }
}

// 注入
Sint.put<IStorageService>(LocalStorageService());

// 使用
class UserController extends SintController {
  final IStorageService storage = Sint.find();
}
```

## テストロードマップ

### 単体テスト

```dart
void main() {
  setUp(() {
    // テスト用の依存性を注入
    Sint.put(MockApiService());
    Sint.put(UserRepository());
  });

  tearDown(() {
    // テスト後にクリーンアップ
    Sint.reset();
  });

  test('依存性の注入と取得', () {
    final service = Sint.find<MockApiService>();
    expect(service, isNotNull);
  });

  test('遅延読み込みの確認', () {
    Sint.lazyPut(() => LazyController());

    // まだインスタンスは作成されていない
    expect(Sint.isRegistered<LazyController>(), true);

    final controller = Sint.find<LazyController>();
    expect(controller, isNotNull);
  });
}
```

### モックの使用

```dart
class MockApiService extends SintController {
  Future<Response> get(String url) async {
    return Response(
      body: {'data': 'テストデータ'},
      statusCode: 200,
    );
  }
}

class MockUserRepository extends UserRepository {
  @override
  Future<User> getUser(String id) async {
    return User(id: id, name: 'テストユーザー');
  }
}

void main() {
  test('モックを使用したコントローラーテスト', () async {
    Sint.put(MockApiService());
    Sint.put(MockUserRepository());

    final controller = UserController();
    await controller.loadUser('123');

    expect(controller.user.value?.name, 'テストユーザー');
  });
}
```

### 統合テスト

```dart
void main() {
  testWidgets('Bindingを使用した完全フロー', (tester) async {
    // 初期Bindingを設定
    await tester.pumpWidget(
      SintMaterialApp(
        initialBinding: AppBinding(),
        home: HomePage(),
      ),
    );

    // 依存性が正しく注入されているか確認
    expect(Sint.isRegistered<ApiService>(), true);
    expect(Sint.isRegistered<StorageService>(), true);

    // UIインタラクション
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    // 結果の確認
    expect(find.text('データ読み込み完了'), findsOneWidget);
  });
}
```

### タグ付きインスタンスのテスト

```dart
void main() {
  test('タグ付きインスタンスの管理', () {
    Sint.put(ApiController(), tag: 'v1');
    Sint.put(ApiController(), tag: 'v2');

    final v1 = Sint.find<ApiController>(tag: 'v1');
    final v2 = Sint.find<ApiController>(tag: 'v2');

    expect(identical(v1, v2), false);

    Sint.delete<ApiController>(tag: 'v1');
    expect(Sint.isRegistered<ApiController>(tag: 'v1'), false);
    expect(Sint.isRegistered<ApiController>(tag: 'v2'), true);
  });
}
```
