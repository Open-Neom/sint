# 翻訳管理

SINTは、Flutterアプリケーションの国際化（i18n）を簡単にする強力な翻訳システムを提供します。

## 基本設定

### Translationsクラスの作成

```dart
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'ja_JP': {
      'hello': 'こんにちは',
      'welcome': 'ようこそ、@name さん',
      'items_count': '@count 個のアイテム',
      'logout': 'ログアウト',
      'settings': '設定',
    },
    'en_US': {
      'hello': 'Hello',
      'welcome': 'Welcome, @name',
      'items_count': '@count items',
      'logout': 'Logout',
      'settings': 'Settings',
    },
    'zh_CN': {
      'hello': '你好',
      'welcome': '欢迎，@name',
      'items_count': '@count 项',
      'logout': '登出',
      'settings': '设置',
    },
  };
}
```

### アプリケーションの設定

```dart
void main() {
  runApp(
    SintMaterialApp(
      translations: AppTranslations(),
      locale: Locale('ja', 'JP'),
      fallbackLocale: Locale('en', 'US'),
      home: HomePage(),
    ),
  );
}
```

## 翻訳の使用

### .tr 拡張メソッド

```dart
Text('hello'.tr) // 'こんにちは'
Text('logout'.tr) // 'ログアウト'
```

### 動的な値の挿入

```dart
// trParams を使用
Text('welcome'.trParams({'name': '太郎'}))
// 結果: 'ようこそ、太郎さん'

Text('items_count'.trParams({'count': '5'}))
// 結果: '5 個のアイテム'
```

### 複数形の処理

```dart
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'ja_JP': {
      'item': 'アイテム',
      'items': '複数のアイテム',
    },
    'en_US': {
      'item': 'Item',
      'items': 'Items',
    },
  };
}

// trPlural を使用
Text('item'.trPlural('items', 1)) // '1 アイテム'
Text('item'.trPlural('items', 5)) // '5 複数のアイテム'
```

## ロケール管理

### 現在のロケールを取得

```dart
final currentLocale = Sint.locale;
print(currentLocale); // Locale('ja', 'JP')
```

### ロケールの変更

```dart
// ロケールを変更
Sint.updateLocale(Locale('en', 'US'));

// ボタンから変更
ElevatedButton(
  onPressed: () => Sint.updateLocale(Locale('zh', 'CN')),
  child: Text('中文に変更'),
)
```

### デバイスのロケールを使用

```dart
SintMaterialApp(
  locale: Sint.deviceLocale,
  fallbackLocale: Locale('en', 'US'),
)
```

### サポートされているロケールのリスト

```dart
SintMaterialApp(
  translations: AppTranslations(),
  locale: Locale('ja', 'JP'),
  fallbackLocale: Locale('en', 'US'),
  localizationsDelegates: [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: [
    Locale('ja', 'JP'),
    Locale('en', 'US'),
    Locale('zh', 'CN'),
    Locale('ko', 'KR'),
  ],
)
```

## 翻訳ファイルの整理

### 複数ファイルに分割

```dart
// translations/ja_jp.dart
class JaJP {
  static const Map<String, String> messages = {
    'hello': 'こんにちは',
    'goodbye': 'さようなら',
  };

  static const Map<String, String> errors = {
    'network_error': 'ネットワークエラー',
    'invalid_input': '無効な入力',
  };
}

// translations/en_us.dart
class EnUS {
  static const Map<String, String> messages = {
    'hello': 'Hello',
    'goodbye': 'Goodbye',
  };

  static const Map<String, String> errors = {
    'network_error': 'Network Error',
    'invalid_input': 'Invalid Input',
  };
}

// translations/app_translations.dart
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'ja_JP': {
      ...JaJP.messages,
      ...JaJP.errors,
    },
    'en_US': {
      ...EnUS.messages,
      ...EnUS.errors,
    },
  };
}
```

### 名前空間を使用

```dart
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'ja_JP': {
      'app.title': 'マイアプリ',
      'app.version': 'バージョン',
      'auth.login': 'ログイン',
      'auth.register': '登録',
      'auth.forgot_password': 'パスワードを忘れた',
      'profile.edit': 'プロフィール編集',
      'profile.settings': '設定',
      'profile.logout': 'ログアウト',
    },
    'en_US': {
      'app.title': 'My App',
      'app.version': 'Version',
      'auth.login': 'Login',
      'auth.register': 'Register',
      'auth.forgot_password': 'Forgot Password',
      'profile.edit': 'Edit Profile',
      'profile.settings': 'Settings',
      'profile.logout': 'Logout',
    },
  };
}

// 使用
Text('app.title'.tr)
Text('auth.login'.tr)
Text('profile.settings'.tr)
```

## 高度な使用例

### 動的翻訳の読み込み

```dart
class DynamicTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => _translations;

  static Map<String, Map<String, String>> _translations = {};

  static Future<void> loadTranslations(String locale) async {
    final response = await http.get(
      Uri.parse('https://api.example.com/translations/$locale'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _translations[locale] = Map<String, String>.from(data);
    }
  }
}

// 使用
await DynamicTranslations.loadTranslations('ja_JP');
Sint.updateLocale(Locale('ja', 'JP'));
```

### 日付と数値のフォーマット

```dart
import 'package:intl/intl.dart';

class LocaleService {
  String formatDate(DateTime date) {
    final locale = Sint.locale?.toString() ?? 'en_US';

    switch (locale) {
      case 'ja_JP':
        return DateFormat('yyyy年MM月dd日', 'ja').format(date);
      case 'en_US':
        return DateFormat('MMM dd, yyyy', 'en').format(date);
      default:
        return DateFormat.yMMMd(locale).format(date);
    }
  }

  String formatCurrency(double amount) {
    final locale = Sint.locale?.toString() ?? 'en_US';

    switch (locale) {
      case 'ja_JP':
        return NumberFormat.currency(locale: 'ja', symbol: '¥').format(amount);
      case 'en_US':
        return NumberFormat.currency(locale: 'en_US', symbol: '\$').format(amount);
      default:
        return NumberFormat.currency(locale: locale).format(amount);
    }
  }
}
```

### 言語選択ウィジェット

```dart
class LanguageSwitcher extends StatelessWidget {
  final List<LocaleOption> locales = [
    LocaleOption(
      locale: Locale('ja', 'JP'),
      name: '日本語',
      flag: '🇯🇵',
    ),
    LocaleOption(
      locale: Locale('en', 'US'),
      name: 'English',
      flag: '🇺🇸',
    ),
    LocaleOption(
      locale: Locale('zh', 'CN'),
      name: '中文',
      flag: '🇨🇳',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButton<Locale>(
      value: Sint.locale,
      items: locales.map((option) {
        return DropdownMenuItem<Locale>(
          value: option.locale,
          child: Row(
            children: [
              Text(option.flag),
              SizedBox(width: 8),
              Text(option.name),
            ],
          ),
        );
      }).toList(),
      onChanged: (locale) {
        if (locale != null) {
          Sint.updateLocale(locale);
        }
      },
    );
  }
}

class LocaleOption {
  final Locale locale;
  final String name;
  final String flag;

  LocaleOption({
    required this.locale,
    required this.name,
    required this.flag,
  });
}
```

### RTL（右から左）言語のサポート

```dart
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'ar_EG': {
      'hello': 'مرحبا',
      'welcome': 'أهلا بك',
    },
  };
}

// RTLの検出
bool isRTL(Locale locale) {
  return locale.languageCode == 'ar' ||
         locale.languageCode == 'he' ||
         locale.languageCode == 'fa';
}

// 使用
SintMaterialApp(
  builder: (context, child) {
    return Directionality(
      textDirection: isRTL(Sint.locale!)
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: child!,
    );
  },
)
```

## ベストプラクティス

### 1. キーの命名規則

```dart
// 良い例 - 階層的な命名
'screens.home.title': 'ホーム',
'screens.home.subtitle': 'ようこそ',
'buttons.save': '保存',
'buttons.cancel': 'キャンセル',
'errors.network': 'ネットワークエラー',

// 悪い例 - 曖昧な命名
'title': 'タイトル',
'text1': 'テキスト1',
'msg': 'メッセージ',
```

### 2. デフォルト値の使用

```dart
extension SafeTranslation on String {
  String trSafe([String? defaultValue]) {
    try {
      return tr;
    } catch (e) {
      return defaultValue ?? this;
    }
  }
}

// 使用
Text('unknown_key'.trSafe('デフォルトテキスト'))
```

### 3. 翻訳の欠落チェック

```dart
class TranslationValidator {
  static void validateTranslations(Translations translations) {
    final keys = translations.keys;
    final languages = keys.keys.toList();

    if (languages.isEmpty) {
      print('警告: 翻訳が定義されていません');
      return;
    }

    final referenceKeys = keys[languages.first]!.keys.toSet();

    for (final lang in languages.skip(1)) {
      final langKeys = keys[lang]!.keys.toSet();
      final missing = referenceKeys.difference(langKeys);
      final extra = langKeys.difference(referenceKeys);

      if (missing.isNotEmpty) {
        print('警告: $lang に欠落しているキー: $missing');
      }

      if (extra.isNotEmpty) {
        print('警告: $lang に余分なキー: $extra');
      }
    }
  }
}
```

## 実践例

### 完全な多言語アプリ

```dart
// main.dart
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SintMaterialApp(
      translations: AppTranslations(),
      locale: Locale('ja', 'JP'),
      fallbackLocale: Locale('en', 'US'),
      home: HomePage(),
    );
  }
}

// home_page.dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app.title'.tr),
        actions: [
          IconButton(
            icon: Icon(Icons.language),
            onPressed: () => _showLanguageDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Text('hello'.tr),
          Text('welcome'.trParams({'name': 'ユーザー'})),
          ElevatedButton(
            onPressed: () {},
            child: Text('buttons.save'.tr),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    Sint.defaultDialog(
      title: 'settings.language'.tr,
      content: Column(
        children: [
          ListTile(
            title: Text('日本語'),
            onTap: () {
              Sint.updateLocale(Locale('ja', 'JP'));
              Sint.back();
            },
          ),
          ListTile(
            title: Text('English'),
            onTap: () {
              Sint.updateLocale(Locale('en', 'US'));
              Sint.back();
            },
          ),
        ],
      ),
    );
  }
}
```

## テストロードマップ

### 単体テスト

```dart
void main() {
  test('翻訳キーの検証', () {
    final translations = AppTranslations();
    final keys = translations.keys;

    expect(keys.containsKey('ja_JP'), true);
    expect(keys.containsKey('en_US'), true);
    expect(keys['ja_JP']!.containsKey('hello'), true);
  });

  test('すべての言語で同じキーが存在するか確認', () {
    final translations = AppTranslations();
    final languages = translations.keys.keys.toList();
    final referenceKeys = translations.keys[languages.first]!.keys.toSet();

    for (final lang in languages) {
      final langKeys = translations.keys[lang]!.keys.toSet();
      expect(langKeys, equals(referenceKeys),
          reason: '$lang に欠落または余分なキーがあります');
    }
  });
}
```

### ウィジェットテスト

```dart
void main() {
  testWidgets('翻訳が正しく表示される', (tester) async {
    await tester.pumpWidget(
      SintMaterialApp(
        translations: AppTranslations(),
        locale: Locale('ja', 'JP'),
        home: Scaffold(
          body: Text('hello'.tr),
        ),
      ),
    );

    expect(find.text('こんにちは'), findsOneWidget);
  });

  testWidgets('ロケール変更のテスト', (tester) async {
    await tester.pumpWidget(
      SintMaterialApp(
        translations: AppTranslations(),
        locale: Locale('ja', 'JP'),
        home: LocaleTestPage(),
      ),
    );

    expect(find.text('こんにちは'), findsOneWidget);

    // ロケールを変更
    Sint.updateLocale(Locale('en', 'US'));
    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsOneWidget);
  });
}
```

### パラメータ化された翻訳のテスト

```dart
void main() {
  test('trParamsのテスト', () {
    Sint.testMode = true;

    final translations = AppTranslations();
    Sint.put(translations);

    Sint.updateLocale(Locale('ja', 'JP'));

    final result = 'welcome'.trParams({'name': '太郎'});
    expect(result, 'ようこそ、太郎さん');
  });

  test('trPluralのテスト', () {
    Sint.testMode = true;

    final result1 = 'item'.trPlural('items', 1);
    expect(result1.contains('1'), true);

    final result5 = 'item'.trPlural('items', 5);
    expect(result5.contains('5'), true);
  });
}
```

### 統合テスト

```dart
void main() {
  testWidgets('完全な言語切り替えフロー', (tester) async {
    await tester.pumpWidget(MyApp());

    // 初期言語（日本語）を確認
    expect(find.text('こんにちは'), findsOneWidget);

    // 言語設定を開く
    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();

    // 英語を選択
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    // 英語に変更されたか確認
    expect(find.text('Hello'), findsOneWidget);
  });
}
```
