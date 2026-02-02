# 状态管理

SINT为Flutter应用程序的状态管理提供了简单而强大的解决方案。支持响应式编程、简单状态更新、状态混合等多种方法。

## 响应式状态管理

### Observable变量 (.obs)

在SINT中,可以使用`.obs`将任何变量变为响应式。

```dart
var count = 0.obs;
var name = ''.obs;
var isLogged = false.obs;
var balance = 0.0.obs;
var items = <String>[].obs;
var user = User().obs;
```

### Obx小部件

`Obx`小部件会自动监听observable变量的变化并更新UI。

```dart
class CounterPage extends StatelessWidget {
  final count = 0.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('计数器')),
      body: Center(
        child: Obx(() => Text(
          '点击次数: ${count.value}',
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

对于更复杂的状态管理,使用`SintController`。

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
        child: Obx(() => Text('计数: ${controller.count.value}')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.increment,
        child: Icon(Icons.add),
      ),
    );
  }
}
```

### 生命周期方法

```dart
class LifecycleController extends SintController {
  @override
  void onInit() {
    super.onInit();
    print('控制器已初始化');
  }

  @override
  void onReady() {
    super.onReady();
    print('控制器准备就绪');
  }

  @override
  void onClose() {
    print('控制器即将销毁');
    super.onClose();
  }
}
```

## 简单状态管理

### SintBuilder

当不需要响应式并希望手动更新时,使用`SintBuilder`。

```dart
class SimpleController extends SintController {
  int count = 0;

  void increment() {
    count++;
    update(); // 更新UI
  }

  void incrementWithId() {
    count++;
    update(['counter']); // 只更新特定ID
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
          return Text('计数: ${controller.count}');
        },
      ),
    );
  }
}
```

### 使用ID更新

```dart
SintBuilder<SimpleController>(
  id: 'counter',
  builder: (controller) {
    return Text('计数: ${controller.count}');
  },
)
```

## StateMixin

`StateMixin`是管理API调用或数据加载状态的便捷方法。

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
      change(null, status: RxStatus.error('获取用户失败'));
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
            onError: (error) => Text('错误: $error'),
            onEmpty: Text('未找到用户'),
          );
        },
      ),
    );
  }
}
```

### StateMixin状态

- `RxStatus.loading()` - 数据加载中
- `RxStatus.success()` - 数据加载成功
- `RxStatus.error(message)` - 发生错误
- `RxStatus.empty()` - 数据为空

## Workers

Workers是响应observable变量变化的监听器。

### ever

每次值改变时都会调用。

```dart
class WorkerController extends SintController {
  final count = 0.obs;

  @override
  void onInit() {
    super.onInit();

    ever(count, (value) {
      print('计数已更改: $value');
    });
  }
}
```

### once

仅在第一次改变时调用。

```dart
once(count, (value) {
  print('计数首次更改: $value');
});
```

### debounce

在用户停止输入指定时间后调用。

```dart
final searchText = ''.obs;

debounce(searchText, (value) {
  // 调用搜索API
  performSearch(value);
}, time: Duration(milliseconds: 500));
```

### interval

只要有变化,就会以指定间隔调用。

```dart
interval(count, (value) {
  print('间隔更新: $value');
}, time: Duration(seconds: 1));
```

## 最佳实践

### 1. 控制器分离

```dart
// 良好示例
class UserController extends SintController {
  final userRepository = Sint.find<UserRepository>();
  final user = Rx<User?>(null);

  Future<void> loadUser(String id) async {
    user.value = await userRepository.getUser(id);
  }
}

// 不良示例 - UI内包含业务逻辑
class UserPage extends StatelessWidget {
  final user = Rx<User?>(null);

  void loadUser() async {
    user.value = await http.get(...); // UI和逻辑混合
  }
}
```

### 2. 适当销毁资源

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

### 3. SintBuilder与Obx的选择

```dart
// 频繁更新时使用SintBuilder
SintBuilder<CounterController>(
  builder: (controller) => Text('${controller.count}'),
)

// 简单状态使用Obx
Obx(() => Text('${count.value}'))
```

## 测试路线图

### 单元测试

```dart
void main() {
  test('计数器递增', () {
    final controller = CounterController();
    expect(controller.count.value, 0);

    controller.increment();
    expect(controller.count.value, 1);
  });

  test('StateMixin状态变化', () async {
    final controller = UserController();

    expect(controller.status.isLoading, false);
    controller.fetchUser();
    expect(controller.status.isLoading, true);

    await Future.delayed(Duration(milliseconds: 100));
    expect(controller.status.isSuccess, true);
  });
}
```

### 小部件测试

```dart
void main() {
  testWidgets('Obx小部件更新', (tester) async {
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

### 集成测试

```dart
void main() {
  testWidgets('完整用户流程', (tester) async {
    await tester.pumpWidget(MyApp());

    // 验证初始状态
    expect(find.text('计数: 0'), findsOneWidget);

    // 点击按钮
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // 验证更新后的状态
    expect(find.text('计数: 1'), findsOneWidget);
  });
}
```

### 模拟和存根

```dart
class MockUserRepository extends SintController implements UserRepository {
  @override
  Future<User> getUser(String id) async {
    return User(id: id, name: '测试用户');
  }
}

void main() {
  setUp(() {
    Sint.put<UserRepository>(MockUserRepository());
  });

  test('使用模拟仓库', () async {
    final controller = UserController();
    await controller.fetchUser();

    expect(controller.state?.name, '测试用户');
  });
}
```
