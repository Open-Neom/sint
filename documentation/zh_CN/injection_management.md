# 依赖注入管理

SINT为依赖注入(DI)提供了强大而简单的系统。这使得在整个应用程序中轻松管理和共享实例成为可能。

## 基本依赖注入

### Sint.put

立即创建实例并使其在整个应用程序中可用。

```dart
class ApiController extends SintController {
  void fetchData() {
    print('正在获取数据...');
  }
}

// 注入依赖
Sint.put(ApiController());

// 从任何地方访问
final controller = Sint.find<ApiController>();
controller.fetchData();
```

### Sint.lazyPut

延迟初始化实例。在第一次调用`Sint.find()`之前不会创建实例。

```dart
Sint.lazyPut(() => DatabaseController());

// 此时才创建实例
final db = Sint.find<DatabaseController>();
```

### Sint.putAsync

异步创建实例。

```dart
Sint.putAsync<SharedPreferences>(() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs;
});

// 使用时
final prefs = await Sint.findAsync<SharedPreferences>();
```

### Sint.create

每次调用`Sint.find()`时都会创建新实例。

```dart
Sint.create(() => TransactionController());

final transaction1 = Sint.find<TransactionController>();
final transaction2 = Sint.find<TransactionController>();
// transaction1和transaction2是不同的实例
```

## 查找实例

### Sint.find

获取已注册的依赖。

```dart
final controller = Sint.find<UserController>();
```

### 带标签的实例

可以管理同一类型的多个实例。

```dart
Sint.put(ApiController(), tag: 'products');
Sint.put(ApiController(), tag: 'users');

final productsApi = Sint.find<ApiController>(tag: 'products');
final usersApi = Sint.find<ApiController>(tag: 'users');
```

## 删除实例

### Sint.delete

删除特定实例。

```dart
Sint.delete<UserController>();

// 删除带标签的实例
Sint.delete<ApiController>(tag: 'products');
```

### Sint.reset

删除所有已注册的依赖。

```dart
Sint.reset();
```

## Bindings

Bindings是用于分组管理依赖的类。

### 基本Binding

```dart
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Sint.lazyPut(() => HomeController());
    Sint.lazyPut(() => ProductService());
    Sint.lazyPut(() => CartController());
  }
}

// 在路由中使用
Sint.to(HomePage(), binding: HomeBinding());
```

### 多个Bindings

```dart
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // 全局依赖
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

// 应用启动时
void main() {
  runApp(SintMaterialApp(
    initialBinding: InitialBinding(),
    home: HomePage(),
  ));
}
```

### 使用BindingsBuilder

```dart
BindingsBuilder(() {
  Sint.lazyPut(() => Controller1());
  Sint.lazyPut(() => Controller2());
})
```

## SmartManagement

SINT自动管理依赖的生命周期。

### SmartManagement.full(默认)

自动销毁未使用的控制器。

```dart
SintMaterialApp(
  smartManagement: SmartManagement.full,
)
```

### SmartManagement.onlyBuilder

仅管理在`SintBuilder`、`GetX`、`Obx`中使用的控制器。

```dart
SintMaterialApp(
  smartManagement: SmartManagement.onlyBuilder,
)
```

### SmartManagement.keepFactory

仅保留工厂(`Sint.create`)。

```dart
SintMaterialApp(
  smartManagement: SmartManagement.keepFactory,
)
```

## 持久化依赖

### permanent参数

创建不会自动删除的实例。

```dart
Sint.put(AuthService(), permanent: true);
Sint.put(ConfigService(), permanent: true);
```

这些实例会一直存在,直到显式删除。

```dart
Sint.delete<AuthService>(force: true);
```

## 实践示例

### 服务层架构

```dart
// Services
class ApiService extends SintController {
  Future<Response> get(String url) async {
    // API请求
  }
}

class StorageService extends SintController {
  Future<void> save(String key, dynamic value) async {
    // 保存数据
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
    // Services(持久化)
    Sint.put(ApiService(), permanent: true);
    Sint.put(StorageService(), permanent: true);

    // Repository
    Sint.lazyPut(() => UserRepository());

    // Controller
    Sint.lazyPut(() => UserController());
  }
}
```

### 环境配置

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

// 配置
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

## 最佳实践

### 1. 使用SintController

对于长期存在的服务使用`SintController`。

```dart
class DatabaseService extends SintController {
  @override
  void onInit() {
    super.onInit();
    // 初始化数据库
  }

  @override
  void onClose() {
    // 关闭数据库
    super.onClose();
  }
}
```

### 2. 依赖分层

```dart
// 底层(持久化)
Sint.put(HttpClient(), permanent: true);
Sint.put(DatabaseService(), permanent: true);

// 中层(延迟加载)
Sint.lazyPut(() => UserRepository());
Sint.lazyPut(() => ProductRepository());

// 上层(按需创建)
Sint.lazyPut(() => HomeController());
```

### 3. 使用接口

```dart
abstract class IStorageService {
  Future<void> save(String key, dynamic value);
  Future<dynamic> read(String key);
}

class LocalStorageService implements IStorageService {
  @override
  Future<void> save(String key, dynamic value) async {
    // 保存到本地存储
  }

  @override
  Future<dynamic> read(String key) async {
    // 从本地存储读取
  }
}

// 注入
Sint.put<IStorageService>(LocalStorageService());

// 使用
class UserController extends SintController {
  final IStorageService storage = Sint.find();
}
```

## 测试路线图

### 单元测试

```dart
void main() {
  setUp(() {
    // 注入测试依赖
    Sint.put(MockApiService());
    Sint.put(UserRepository());
  });

  tearDown(() {
    // 测试后清理
    Sint.reset();
  });

  test('依赖注入和获取', () {
    final service = Sint.find<MockApiService>();
    expect(service, isNotNull);
  });

  test('延迟加载验证', () {
    Sint.lazyPut(() => LazyController());

    // 实例尚未创建
    expect(Sint.isRegistered<LazyController>(), true);

    final controller = Sint.find<LazyController>();
    expect(controller, isNotNull);
  });
}
```

### 使用模拟

```dart
class MockApiService extends SintController {
  Future<Response> get(String url) async {
    return Response(
      body: {'data': '测试数据'},
      statusCode: 200,
    );
  }
}

class MockUserRepository extends UserRepository {
  @override
  Future<User> getUser(String id) async {
    return User(id: id, name: '测试用户');
  }
}

void main() {
  test('使用模拟的控制器测试', () async {
    Sint.put(MockApiService());
    Sint.put(MockUserRepository());

    final controller = UserController();
    await controller.loadUser('123');

    expect(controller.user.value?.name, '测试用户');
  });
}
```

### 集成测试

```dart
void main() {
  testWidgets('使用Binding的完整流程', (tester) async {
    // 设置初始Binding
    await tester.pumpWidget(
      SintMaterialApp(
        initialBinding: AppBinding(),
        home: HomePage(),
      ),
    );

    // 验证依赖是否正确注入
    expect(Sint.isRegistered<ApiService>(), true);
    expect(Sint.isRegistered<StorageService>(), true);

    // UI交互
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    // 验证结果
    expect(find.text('数据加载完成'), findsOneWidget);
  });
}
```

### 测试带标签的实例

```dart
void main() {
  test('带标签实例的管理', () {
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
