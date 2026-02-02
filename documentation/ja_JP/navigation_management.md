# ナビゲーション管理

SINTは、Flutterのナビゲーションを簡素化し、contextを必要とせずにルート間を移動できる強力なナビゲーションシステムを提供します。

## SintMaterialApp

SINTのナビゲーション機能を使用するには、`MaterialApp`の代わりに`SintMaterialApp`を使用します。

```dart
void main() {
  runApp(SintMaterialApp(
    home: HomePage(),
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
  ));
}
```

## 基本的なナビゲーション

### Sint.to() - ページへ移動

新しいページに移動します。

```dart
Sint.to(NextPage());

// パラメータ付き
Sint.to(
  ProfilePage(),
  transition: Transition.fade,
  duration: Duration(milliseconds: 300),
);
```

### Sint.back() - 前のページに戻る

```dart
Sint.back();

// 結果を返す
Sint.back(result: {'success': true});
```

### Sint.off() - 現在のページを置き換え

現在のページを新しいページに置き換えます。

```dart
Sint.off(HomePage());
```

### Sint.offAll() - すべてのページを削除して移動

ナビゲーションスタック全体をクリアします。

```dart
Sint.offAll(LoginPage());

// 条件付きでルートを保持
Sint.offAll(HomePage(), predicate: (route) => route.isFirst);
```

## 名前付きルート

### ルートの定義

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

### 名前付きルートでの移動

```dart
// 基本的な移動
Sint.toNamed('/profile');

// パラメータ付き
Sint.toNamed('/product/123');

// クエリパラメータ
Sint.toNamed('/search?query=flutter&page=1');

// 引数の送信
Sint.toNamed('/profile', arguments: {'userId': '123'});
```

### 引数の受け取り

```dart
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 引数を取得
    final args = Sint.arguments;
    final userId = args['userId'];

    // パスパラメータを取得
    final productId = Sint.parameters['id'];

    return Scaffold(
      appBar: AppBar(title: Text('プロフィール: $userId')),
    );
  }
}
```

### 名前付きルートの他のメソッド

```dart
// 置き換え
Sint.offNamed('/login');

// すべてクリア
Sint.offAllNamed('/home');

// 指定したルートまで戻る
Sint.until((route) => route.settings.name == '/home');

// 名前付きルートまで戻る
Sint.offNamedUntil('/home', (route) => false);
```

## 動的URL

### パスパラメータ

```dart
SintPage(
  name: '/user/:userId/post/:postId',
  page: () => PostDetailPage(),
)

// 移動
Sint.toNamed('/user/123/post/456');

// 取得
final userId = Sint.parameters['userId']; // '123'
final postId = Sint.parameters['postId']; // '456'
```

### クエリパラメータ

```dart
Sint.toNamed('/search?query=flutter&category=widgets');

// 取得
final query = Sint.parameters['query']; // 'flutter'
final category = Sint.parameters['category']; // 'widgets'
```

## Middleware

ミドルウェアを使用して、ルートへのアクセスを制御できます。

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
    print('ページが呼ばれました: ${page?.name}');
    return page;
  }

  @override
  Widget onPageBuilt(Widget page) {
    print('ページがビルドされました');
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

### 優先度付きミドルウェア

```dart
class LoggingMiddleware extends SintMiddleware {
  @override
  int? get priority => 1; // 優先度が高い

  @override
  RouteSettings? redirect(String? route) {
    print('ルート: $route');
    return null;
  }
}

class AuthMiddleware extends SintMiddleware {
  @override
  int? get priority => 2; // 優先度が低い

  @override
  RouteSettings? redirect(String? route) {
    // 認証チェック
    return null;
  }
}
```

## トランジション

### ビルトイントランジション

```dart
Sint.to(
  NextPage(),
  transition: Transition.fade,
);

// 利用可能なトランジション:
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

### カスタムトランジション

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
  'タイトル',
  'メッセージ内容',
  snackPosition: SnackPosition.BOTTOM,
  backgroundColor: Colors.blue,
  colorText: Colors.white,
  duration: Duration(seconds: 3),
);

// アクション付き
Sint.snackbar(
  'エラー',
  'ネットワークエラーが発生しました',
  mainButton: TextButton(
    onPressed: () => retry(),
    child: Text('再試行'),
  ),
);

// カスタムSnackBar
Sint.showSnackbar(SintSnackBar(
  title: 'カスタム',
  message: 'カスタムスナックバー',
  icon: Icon(Icons.check_circle),
  shouldIconPulse: true,
  barBlur: 20,
  isDismissible: true,
  duration: Duration(seconds: 4),
));
```

## ダイアログ

### 基本的なダイアログ

```dart
Sint.defaultDialog(
  title: '確認',
  middleText: '本当に削除しますか?',
  textConfirm: 'はい',
  textCancel: 'いいえ',
  onConfirm: () => delete(),
  onCancel: () => Sint.back(),
);

// カスタムコンテンツ
Sint.defaultDialog(
  title: 'カスタムダイアログ',
  content: Column(
    children: [
      TextField(decoration: InputDecoration(hintText: '名前')),
      TextField(decoration: InputDecoration(hintText: 'メール')),
    ],
  ),
  confirm: ElevatedButton(
    onPressed: () => submit(),
    child: Text('送信'),
  ),
);
```

### カスタムダイアログ

```dart
Sint.dialog(
  AlertDialog(
    title: Text('カスタムダイアログ'),
    content: Text('これはカスタムダイアログです'),
    actions: [
      TextButton(
        onPressed: () => Sint.back(),
        child: Text('閉じる'),
      ),
    ],
  ),
  barrierDismissible: false,
);

// 結果を待つ
final result = await Sint.dialog<bool>(
  AlertDialog(
    title: Text('確認'),
    content: Text('続けますか?'),
    actions: [
      TextButton(
        onPressed: () => Sint.back(result: false),
        child: Text('キャンセル'),
      ),
      TextButton(
        onPressed: () => Sint.back(result: true),
        child: Text('OK'),
      ),
    ],
  ),
);

if (result == true) {
  // 処理を続行
}
```

## ボトムシート

### シンプルなボトムシート

```dart
Sint.bottomSheet(
  Container(
    height: 200,
    color: Colors.white,
    child: Column(
      children: [
        ListTile(
          leading: Icon(Icons.share),
          title: Text('共有'),
          onTap: () => share(),
        ),
        ListTile(
          leading: Icon(Icons.download),
          title: Text('ダウンロード'),
          onTap: () => download(),
        ),
      ],
    ),
  ),
);

// カスタマイズされたボトムシート
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

## ネストされたナビゲーション

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

// ネストされたナビゲーター内で移動
Sint.to(NestedPage(), id: 1);
```

## 実践例

### 認証フロー

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

// ルート設定
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

### ディープリンク

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

// 外部リンクから開く: myapp://product/123
// Sint.parameters['id'] は '123'
```

## テストロードマップ

### 単体テスト

```dart
void main() {
  test('ナビゲーションスタックの管理', () {
    Sint.to(Page1());
    expect(Sint.currentRoute, '/page1');

    Sint.to(Page2());
    expect(Sint.currentRoute, '/page2');

    Sint.back();
    expect(Sint.currentRoute, '/page1');
  });
}
```

### ウィジェットテスト

```dart
void main() {
  testWidgets('ページ遷移のテスト', (tester) async {
    await tester.pumpWidget(
      SintMaterialApp(
        home: HomePage(),
      ),
    );

    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();

    expect(find.byType(NextPage), findsOneWidget);
  });

  testWidgets('名前付きルートのテスト', (tester) async {
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

### 統合テスト

```dart
void main() {
  testWidgets('完全なナビゲーションフロー', (tester) async {
    await tester.pumpWidget(MyApp());

    // ホームページを確認
    expect(find.byType(HomePage), findsOneWidget);

    // ログインページへ移動
    await tester.tap(find.text('ログイン'));
    await tester.pumpAndSettle();

    // ログインフォームを入力
    await tester.enterText(find.byType(TextField).first, 'user@example.com');
    await tester.tap(find.text('送信'));
    await tester.pumpAndSettle();

    // ダッシュボードに移動したか確認
    expect(find.byType(DashboardPage), findsOneWidget);
  });
}
```

### Middlewareのテスト

```dart
void main() {
  test('認証ミドルウェアのテスト', () {
    final authService = AuthService();
    Sint.put(authService);

    final middleware = AuthMiddleware();

    // 未認証の場合
    authService.isAuthenticated.value = false;
    final redirect = middleware.redirect('/admin');
    expect(redirect?.name, '/login');

    // 認証済みの場合
    authService.isAuthenticated.value = true;
    final noRedirect = middleware.redirect('/admin');
    expect(noRedirect, null);
  });
}
```
