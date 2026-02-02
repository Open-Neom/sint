# 导航管理

SINT提供了强大的导航系统,简化了Flutter的导航,并允许在路由之间导航而无需context。

## SintMaterialApp

要使用SINT的导航功能,请使用`SintMaterialApp`代替`MaterialApp`。

```dart
void main() {
  runApp(SintMaterialApp(
    home: HomePage(),
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
  ));
}
```

## 基本导航

### Sint.to() - 导航到页面

导航到新页面。

```dart
Sint.to(NextPage());

// 带参数
Sint.to(
  ProfilePage(),
  transition: Transition.fade,
  duration: Duration(milliseconds: 300),
);
```

### Sint.back() - 返回上一页

```dart
Sint.back();

// 返回结果
Sint.back(result: {'success': true});
```

### Sint.off() - 替换当前页面

用新页面替换当前页面。

```dart
Sint.off(HomePage());
```

### Sint.offAll() - 删除所有页面并导航

清除整个导航栈。

```dart
Sint.offAll(LoginPage());

// 有条件地保留路由
Sint.offAll(HomePage(), predicate: (route) => route.isFirst);
```

## 命名路由

### 定义路由

```dart
void main() {
  runApp(SintMaterialApp(
    initialRoute: '/',
    getPages: [
      SintPage(name: '/', page: () => HomePage()),
      SintPage(name: '/profile', page: () => ProfilePage()),
      SintPage(name: '/settings', page: () => SettingsPage()),
      SintPage(name: '/product/:id', page: () => ProductPage()),
    ],
  ));
}
```

### 使用命名路由导航

```dart
// 基本导航
Sint.toNamed('/profile');

// 带参数
Sint.toNamed('/product/123');

// 查询参数
Sint.toNamed('/search?query=flutter&page=1');

// 发送参数
Sint.toNamed('/profile', arguments: {'userId': '123'});
```

### 接收参数

```dart
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 获取参数
    final args = Sint.arguments;
    final userId = args['userId'];

    // 获取路径参数
    final productId = Sint.parameters['id'];

    return Scaffold(
      appBar: AppBar(title: Text('个人资料: $userId')),
    );
  }
}
```

### 命名路由的其他方法

```dart
// 替换
Sint.offNamed('/login');

// 全部清除
Sint.offAllNamed('/home');

// 返回到指定路由
Sint.until((route) => route.settings.name == '/home');

// 返回到命名路由
Sint.offNamedUntil('/home', (route) => false);
```

## 动态URL

### 路径参数

```dart
SintPage(
  name: '/user/:userId/post/:postId',
  page: () => PostDetailPage(),
)

// 导航
Sint.toNamed('/user/123/post/456');

// 获取
final userId = Sint.parameters['userId']; // '123'
final postId = Sint.parameters['postId']; // '456'
```

### 查询参数

```dart
Sint.toNamed('/search?query=flutter&category=widgets');

// 获取
final query = Sint.parameters['query']; // 'flutter'
final category = Sint.parameters['category']; // 'widgets'
```

## Middleware

使用中间件控制对路由的访问。

```dart
class AuthMiddleware extends SintMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authService = Sint.find<AuthService>();

    if (!authService.isAuthenticated) {
      return RouteSettings(name: '/login');
    }

    return null;
  }

  @override
  SintPage? onPageCalled(SintPage? page) {
    print('页面被调用: ${page?.name}');
    return page;
  }

  @override
  Widget onPageBuilt(Widget page) {
    print('页面已构建');
    return page;
  }
}

// 使用方法
SintPage(
  name: '/admin',
  page: () => AdminPage(),
  middlewares: [AuthMiddleware()],
)
```

### 带优先级的中间件

```dart
class LoggingMiddleware extends SintMiddleware {
  @override
  int? get priority => 1; // 优先级高

  @override
  RouteSettings? redirect(String? route) {
    print('路由: $route');
    return null;
  }
}

class AuthMiddleware extends SintMiddleware {
  @override
  int? get priority => 2; // 优先级低

  @override
  RouteSettings? redirect(String? route) {
    // 身份验证检查
    return null;
  }
}
```

## 过渡动画

### 内置过渡

```dart
Sint.to(
  NextPage(),
  transition: Transition.fade,
);

// 可用过渡:
// - Transition.fade
// - Transition.rightToLeft
// - Transition.leftToRight
// - Transition.topToBottom
// - Transition.bottomToTop
// - Transition.scale
// - Transition.rotate
// - Transition.size
// - Transition.zoom
// - Transition.cupertino
```

### 自定义过渡

```dart
SintPage(
  name: '/custom',
  page: () => CustomPage(),
  customTransition: CustomTransition(),
  transitionDuration: Duration(milliseconds: 500),
)

class CustomTransition extends CustomTransitionBuilder {
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

## SnackBars

```dart
Sint.snackbar(
  '标题',
  '消息内容',
  snackPosition: SnackPosition.BOTTOM,
  backgroundColor: Colors.blue,
  colorText: Colors.white,
  duration: Duration(seconds: 3),
);

// 带操作
Sint.snackbar(
  '错误',
  '发生网络错误',
  mainButton: TextButton(
    onPressed: () => retry(),
    child: Text('重试'),
  ),
);

// 自定义SnackBar
Sint.showSnackbar(SintSnackBar(
  title: '自定义',
  message: '自定义提示条',
  icon: Icon(Icons.check_circle),
  shouldIconPulse: true,
  barBlur: 20,
  isDismissible: true,
  duration: Duration(seconds: 4),
));
```

## 对话框

### 基本对话框

```dart
Sint.defaultDialog(
  title: '确认',
  middleText: '确定要删除吗?',
  textConfirm: '是',
  textCancel: '否',
  onConfirm: () => delete(),
  onCancel: () => Sint.back(),
);

// 自定义内容
Sint.defaultDialog(
  title: '自定义对话框',
  content: Column(
    children: [
      TextField(decoration: InputDecoration(hintText: '姓名')),
      TextField(decoration: InputDecoration(hintText: '邮箱')),
    ],
  ),
  confirm: ElevatedButton(
    onPressed: () => submit(),
    child: Text('提交'),
  ),
);
```

### 自定义对话框

```dart
Sint.dialog(
  AlertDialog(
    title: Text('自定义对话框'),
    content: Text('这是一个自定义对话框'),
    actions: [
      TextButton(
        onPressed: () => Sint.back(),
        child: Text('关闭'),
      ),
    ],
  ),
  barrierDismissible: false,
);

// 等待结果
final result = await Sint.dialog<bool>(
  AlertDialog(
    title: Text('确认'),
    content: Text('继续吗?'),
    actions: [
      TextButton(
        onPressed: () => Sint.back(result: false),
        child: Text('取消'),
      ),
      TextButton(
        onPressed: () => Sint.back(result: true),
        child: Text('确定'),
      ),
    ],
  ),
);

if (result == true) {
  // 继续处理
}
```

## 底部表单

### 简单底部表单

```dart
Sint.bottomSheet(
  Container(
    height: 200,
    color: Colors.white,
    child: Column(
      children: [
        ListTile(
          leading: Icon(Icons.share),
          title: Text('分享'),
          onTap: () => share(),
        ),
        ListTile(
          leading: Icon(Icons.download),
          title: Text('下载'),
          onTap: () => download(),
        ),
      ],
    ),
  ),
);

// 自定义底部表单
Sint.bottomSheet(
  MyCustomBottomSheet(),
  backgroundColor: Colors.white,
  elevation: 8,
  enableDrag: true,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
);
```

## 嵌套导航

```dart
class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
        key: Sint.nestedKey(1),
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (_) => SubPage(),
          );
        },
      ),
    );
  }
}

// 在嵌套导航器内导航
Sint.to(NestedPage(), id: 1);
```

## 实践示例

### 身份验证流程

```dart
class AuthService extends SintController {
  final isAuthenticated = false.obs;

  void login() {
    isAuthenticated.value = true;
    Sint.offAllNamed('/home');
  }

  void logout() {
    isAuthenticated.value = false;
    Sint.offAllNamed('/login');
  }
}

class AuthMiddleware extends SintMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authService = Sint.find<AuthService>();

    if (!authService.isAuthenticated.value) {
      return RouteSettings(name: '/login');
    }

    return null;
  }
}

// 路由配置
getPages: [
  SintPage(name: '/login', page: () => LoginPage()),
  SintPage(
    name: '/home',
    page: () => HomePage(),
    middlewares: [AuthMiddleware()],
  ),
  SintPage(
    name: '/profile',
    page: () => ProfilePage(),
    middlewares: [AuthMiddleware()],
  ),
]
```

### 深度链接

```dart
SintMaterialApp(
  initialRoute: '/',
  getPages: [
    SintPage(name: '/', page: () => HomePage()),
    SintPage(name: '/product/:id', page: () => ProductPage()),
    SintPage(name: '/category/:category', page: () => CategoryPage()),
  ],
  unknownRoute: SintPage(
    name: '/notfound',
    page: () => NotFoundPage(),
  ),
)

// 从外部链接打开: myapp://product/123
// Sint.parameters['id'] 为 '123'
```

## 测试路线图

### 单元测试

```dart
void main() {
  test('导航栈管理', () {
    Sint.to(Page1());
    expect(Sint.currentRoute, '/page1');

    Sint.to(Page2());
    expect(Sint.currentRoute, '/page2');

    Sint.back();
    expect(Sint.currentRoute, '/page1');
  });
}
```

### 小部件测试

```dart
void main() {
  testWidgets('页面导航测试', (tester) async {
    await tester.pumpWidget(
      SintMaterialApp(
        home: HomePage(),
      ),
    );

    await tester.tap(find.text('下一页'));
    await tester.pumpAndSettle();

    expect(find.byType(NextPage), findsOneWidget);
  });

  testWidgets('命名路由测试', (tester) async {
    await tester.pumpWidget(
      SintMaterialApp(
        initialRoute: '/',
        getPages: [
          SintPage(name: '/', page: () => HomePage()),
          SintPage(name: '/details', page: () => DetailsPage()),
        ],
      ),
    );

    Sint.toNamed('/details');
    await tester.pumpAndSettle();

    expect(find.byType(DetailsPage), findsOneWidget);
  });
}
```

### 集成测试

```dart
void main() {
  testWidgets('完整导航流程', (tester) async {
    await tester.pumpWidget(MyApp());

    // 验证主页
    expect(find.byType(HomePage), findsOneWidget);

    // 导航到登录页
    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle();

    // 填写登录表单
    await tester.enterText(find.byType(TextField).first, 'user@example.com');
    await tester.tap(find.text('提交'));
    await tester.pumpAndSettle();

    // 验证已导航到仪表板
    expect(find.byType(DashboardPage), findsOneWidget);
  });
}
```

### 中间件测试

```dart
void main() {
  test('认证中间件测试', () {
    final authService = AuthService();
    Sint.put(authService);

    final middleware = AuthMiddleware();

    // 未认证时
    authService.isAuthenticated.value = false;
    final redirect = middleware.redirect('/admin');
    expect(redirect?.name, '/login');

    // 已认证时
    authService.isAuthenticated.value = true;
    final noRedirect = middleware.redirect('/admin');
    expect(noRedirect, null);
  });
}
```
