# ادارة الترجمة

## المقدمة

إدارة الترجمة هي أحد الأعمدة الأربعة لإطار عمل SINT. توفر SINT نظام ترجمة قوي وسهل الاستخدام يدعم تعدد اللغات، الترجمة الديناميكية، والتبديل بين اللغات في وقت التشغيل.

## إعداد الترجمات

### إنشاء ملف الترجمات

```dart
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      'hello': 'Hello',
      'welcome': 'Welcome to our app',
      'login': 'Login',
      'logout': 'Logout',
      'save': 'Save',
      'cancel': 'Cancel',
    },
    'ar_EG': {
      'hello': 'مرحبا',
      'welcome': 'مرحباً بك في تطبيقنا',
      'login': 'تسجيل الدخول',
      'logout': 'تسجيل الخروج',
      'save': 'حفظ',
      'cancel': 'إلغاء',
    },
    'es_ES': {
      'hello': 'Hola',
      'welcome': 'Bienvenido a nuestra aplicación',
      'login': 'Iniciar sesión',
      'logout': 'Cerrar sesión',
      'save': 'Guardar',
      'cancel': 'Cancelar',
    },
  };
}
```

### تفعيل الترجمات في التطبيق

```dart
void main() {
  runApp(
    SintMaterialApp(
      translations: AppTranslations(),
      locale: Locale('ar', 'EG'), // اللغة الافتراضية
      fallbackLocale: Locale('en', 'US'), // اللغة الاحتياطية
      home: HomePage(),
    ),
  );
}
```

## استخدام الترجمات

### الامتداد .tr

```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('hello'.tr), // سيتم ترجمتها حسب اللغة الحالية
      ),
      body: Center(
        child: Column(
          children: [
            Text('welcome'.tr),
            ElevatedButton(
              onPressed: () {},
              child: Text('login'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
```

### الوصول المباشر

```dart
// إذا كنت لا تريد استخدام الامتداد
Text(Sint.tr('hello'))

// مع fallback
Text(Sint.tr('missing_key', fallbackKey: 'hello'))
```

## الترجمات مع المعاملات

### trParams - استبدال المتغيرات

```dart
// في ملف الترجمات
'greeting': 'Hello @name, you have @count messages',
'greeting_ar': 'مرحباً @name، لديك @count رسالة',

// الاستخدام
Text('greeting'.trParams({
  'name': 'أحمد',
  'count': '5',
}))
// النتيجة: "مرحباً أحمد، لديك 5 رسالة"
```

### أمثلة متقدمة

```dart
// في الترجمات
Map<String, Map<String, String>> get keys => {
  'ar_EG': {
    'order_status': 'طلبك رقم @orderId في حالة @status',
    'user_profile': '@username - @age سنة - @city',
    'price': 'السعر: @amount @currency',
  },
};

// الاستخدام
Text('order_status'.trParams({
  'orderId': '12345',
  'status': 'قيد التوصيل',
}))

Text('user_profile'.trParams({
  'username': 'محمد',
  'age': '28',
  'city': 'القاهرة',
}))

Text('price'.trParams({
  'amount': '299',
  'currency': 'ريال',
}))
```

## الترجمات الجمعية

### trPlural - التعامل مع الأعداد

```dart
// في ملف الترجمات
Map<String, Map<String, String>> get keys => {
  'ar_EG': {
    'items_0': 'لا توجد عناصر',
    'items_1': 'عنصر واحد',
    'items_2': 'عنصران',
    'items_few': '@count عناصر', // 3-10
    'items_many': '@count عنصر', // 11-99
    'items_other': '@count عنصر', // 100+
  },
  'en_US': {
    'items_0': 'No items',
    'items_1': 'One item',
    'items_other': '@count items',
  },
};

// الاستخدام
Text('items'.trPlural('items', 0)) // "لا توجد عناصر"
Text('items'.trPlural('items', 1)) // "عنصر واحد"
Text('items'.trPlural('items', 2)) // "عنصران"
Text('items'.trPlural('items', 5)) // "5 عناصر"
Text('items'.trPlural('items', 15)) // "15 عنصر"
Text('items'.trPlural('items', 100)) // "100 عنصر"
```

### أمثلة واقعية للجمع

```dart
// الرسائل
'messages_0': 'لا توجد رسائل',
'messages_1': 'رسالة واحدة',
'messages_2': 'رسالتان',
'messages_few': '@count رسائل',
'messages_many': '@count رسالة',
'messages_other': '@count رسالة',

// المنتجات
'products_0': 'لا توجد منتجات',
'products_1': 'منتج واحد',
'products_2': 'منتجان',
'products_few': '@count منتجات',
'products_many': '@count منتج',
'products_other': '@count منتج',

// الاستخدام
Text('messages'.trPlural('messages', messageCount))
Text('products'.trPlural('products', productCount))
```

## تغيير اللغة

### updateLocale - تغيير اللغة في وقت التشغيل

```dart
class LanguageController extends SintController {
  void changeLanguage(String languageCode, String countryCode) {
    var locale = Locale(languageCode, countryCode);
    Sint.updateLocale(locale);
  }

  void toArabic() {
    changeLanguage('ar', 'EG');
  }

  void toEnglish() {
    changeLanguage('en', 'US');
  }

  void toSpanish() {
    changeLanguage('es', 'ES');
  }
}
```

### واجهة اختيار اللغة

```dart
class LanguageSelector extends StatelessWidget {
  final controller = Sint.put(LanguageController());

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: Text('🇸🇦'),
          title: Text('العربية'),
          onTap: controller.toArabic,
        ),
        ListTile(
          leading: Text('🇺🇸'),
          title: Text('English'),
          onTap: controller.toEnglish,
        ),
        ListTile(
          leading: Text('🇪🇸'),
          title: Text('Español'),
          onTap: controller.toSpanish,
        ),
      ],
    );
  }
}
```

### حفظ اللغة المختارة

```dart
class LanguageController extends SintController {
  final storage = Sint.find<StorageService>();

  @override
  void onInit() {
    super.onInit();
    loadSavedLanguage();
  }

  void loadSavedLanguage() async {
    final languageCode = storage.read('language_code') ?? 'ar';
    final countryCode = storage.read('country_code') ?? 'EG';

    Sint.updateLocale(Locale(languageCode, countryCode));
  }

  void changeLanguage(String languageCode, String countryCode) async {
    await storage.write('language_code', languageCode);
    await storage.write('country_code', countryCode);

    Sint.updateLocale(Locale(languageCode, countryCode));
  }
}
```

## الوصول للغة الحالية

### معلومات اللغة

```dart
// اللغة الحالية
final currentLocale = Sint.locale; // Locale('ar', 'EG')

// رمز اللغة
final languageCode = Sint.locale?.languageCode; // 'ar'

// رمز البلد
final countryCode = Sint.locale?.countryCode; // 'EG'

// اللغة الاحتياطية
final fallback = Sint.fallbackLocale; // Locale('en', 'US')
```

### التحقق من اللغة

```dart
bool isArabic() {
  return Sint.locale?.languageCode == 'ar';
}

bool isEnglish() {
  return Sint.locale?.languageCode == 'en';
}

bool isRTL() {
  return ['ar', 'he', 'fa', 'ur'].contains(Sint.locale?.languageCode);
}
```

### استخدام معلومات اللغة

```dart
class DirectionAwareWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isRTL() ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text('title'.tr),
          leading: isRTL()
              ? null
              : IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () => Sint.back(),
                ),
          actions: isRTL()
              ? [
                  IconButton(
                    icon: Icon(Icons.arrow_forward),
                    onPressed: () => Sint.back(),
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
```

## تنظيم الترجمات

### فصل الترجمات لملفات مختلفة

```dart
// translations/ar_translations.dart
class ArTranslations {
  static Map<String, String> get keys => {
    'hello': 'مرحباً',
    'welcome': 'أهلاً وسهلاً',
    ...authKeys,
    ...homeKeys,
    ...profileKeys,
  };

  static Map<String, String> get authKeys => {
    'login': 'تسجيل الدخول',
    'logout': 'تسجيل الخروج',
    'register': 'إنشاء حساب',
    'forgot_password': 'نسيت كلمة المرور',
  };

  static Map<String, String> get homeKeys => {
    'home_title': 'الرئيسية',
    'search': 'بحث',
    'notifications': 'الإشعارات',
  };

  static Map<String, String> get profileKeys => {
    'profile': 'الملف الشخصي',
    'edit_profile': 'تعديل الملف الشخصي',
    'settings': 'الإعدادات',
  };
}

// translations/en_translations.dart
class EnTranslations {
  static Map<String, String> get keys => {
    'hello': 'Hello',
    'welcome': 'Welcome',
    ...authKeys,
    ...homeKeys,
    ...profileKeys,
  };

  static Map<String, String> get authKeys => {
    'login': 'Login',
    'logout': 'Logout',
    'register': 'Register',
    'forgot_password': 'Forgot Password',
  };

  static Map<String, String> get homeKeys => {
    'home_title': 'Home',
    'search': 'Search',
    'notifications': 'Notifications',
  };

  static Map<String, String> get profileKeys => {
    'profile': 'Profile',
    'edit_profile': 'Edit Profile',
    'settings': 'Settings',
  };
}

// translations/app_translations.dart
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'ar_EG': ArTranslations.keys,
    'en_US': EnTranslations.keys,
  };
}
```

### استخدام JSON للترجمات

```dart
class JsonTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {};

  static Future<void> loadTranslations() async {
    final arJson = await rootBundle.loadString('assets/translations/ar.json');
    final enJson = await rootBundle.loadString('assets/translations/en.json');

    final arMap = json.decode(arJson) as Map<String, dynamic>;
    final enMap = json.decode(enJson) as Map<String, dynamic>;

    // تحويل ودمج الترجمات
  }
}
```

## الترجمات المتقدمة

### الترجمات المتداخلة

```dart
// في ملف الترجمات
Map<String, Map<String, String>> get keys => {
  'ar_EG': {
    'errors.network': 'خطأ في الاتصال بالشبكة',
    'errors.server': 'خطأ في الخادم',
    'errors.validation': 'خطأ في التحقق من البيانات',
    'user.name': 'الاسم',
    'user.email': 'البريد الإلكتروني',
    'user.phone': 'رقم الهاتف',
  },
};

// الاستخدام
Text('errors.network'.tr)
Text('user.name'.tr)
```

### الترجمات الشرطية

```dart
String getWelcomeMessage() {
  final hour = DateTime.now().hour;

  if (hour < 12) {
    return 'good_morning'.tr;
  } else if (hour < 18) {
    return 'good_afternoon'.tr;
  } else {
    return 'good_evening'.tr;
  }
}
```

### الترجمات مع التنسيق

```dart
// في الترجمات
'formatted_date': 'التاريخ: @date',
'formatted_price': '@amount @currency',
'formatted_time': 'الساعة @hour:@minute',

// الاستخدام
String formatDate(DateTime date) {
  return 'formatted_date'.trParams({
    'date': DateFormat('yyyy-MM-dd').format(date),
  });
}

String formatPrice(double amount, String currency) {
  return 'formatted_price'.trParams({
    'amount': amount.toStringAsFixed(2),
    'currency': currency,
  });
}
```

## الترجمة التلقائية حسب الجهاز

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // الحصول على لغة الجهاز
  final deviceLocale = WidgetsBinding.instance.window.locale;

  runApp(
    SintMaterialApp(
      translations: AppTranslations(),
      locale: deviceLocale, // استخدام لغة الجهاز
      fallbackLocale: Locale('en', 'US'),
      home: HomePage(),
    ),
  );
}
```

### مع دعم اللغات المحدودة

```dart
Locale? getInitialLocale() {
  final deviceLocale = WidgetsBinding.instance.window.locale;
  final supportedLanguages = ['ar', 'en', 'es'];

  if (supportedLanguages.contains(deviceLocale.languageCode)) {
    return deviceLocale;
  }

  return Locale('en', 'US'); // اللغة الافتراضية
}

void main() {
  runApp(
    SintMaterialApp(
      translations: AppTranslations(),
      locale: getInitialLocale(),
      fallbackLocale: Locale('en', 'US'),
      home: HomePage(),
    ),
  );
}
```

## أفضل الممارسات

### 1. استخدم مفاتيح واضحة

```dart
// جيد - مفاتيح وصفية
'login_button': 'تسجيل الدخول',
'error_invalid_email': 'البريد الإلكتروني غير صحيح',
'success_profile_updated': 'تم تحديث الملف الشخصي',

// سيء - مفاتيح غامضة
'btn1': 'تسجيل الدخول',
'err1': 'البريد الإلكتروني غير صحيح',
```

### 2. نظم الترجمات بشكل هرمي

```dart
// جيد - تنظيم هرمي
'auth.login': 'تسجيل الدخول',
'auth.logout': 'تسجيل الخروج',
'home.title': 'الرئيسية',
'home.search': 'بحث',
'profile.edit': 'تعديل',
'profile.settings': 'الإعدادات',
```

### 3. استخدم fallback دائماً

```dart
// جيد - مع fallback
Text('missing_key'.tr) // سيعرض النص من fallbackLocale

// أفضل - مع رسالة افتراضية
Text(Sint.tr('missing_key', fallbackKey: 'default_message'))
```

### 4. اختبر جميع اللغات

```dart
void testAllLanguages() {
  final languages = ['ar_EG', 'en_US', 'es_ES'];

  for (var lang in languages) {
    final parts = lang.split('_');
    Sint.updateLocale(Locale(parts[0], parts[1]));

    print('Testing $lang:');
    print('hello'.tr);
    print('welcome'.tr);
  }
}
```

## خارطة طريق الاختبارات

### اختبار إعداد الترجمات

```dart
void main() {
  test('يجب أن تحتوي على جميع اللغات', () {
    final translations = AppTranslations();
    final keys = translations.keys;

    expect(keys.containsKey('ar_EG'), true);
    expect(keys.containsKey('en_US'), true);
  });

  test('يجب أن تحتوي على نفس المفاتيح في جميع اللغات', () {
    final translations = AppTranslations();
    final arKeys = translations.keys['ar_EG']!.keys.toSet();
    final enKeys = translations.keys['en_US']!.keys.toSet();

    expect(arKeys, equals(enKeys));
  });
}
```

### اختبار الترجمة الأساسية

```dart
testWidgets('يجب أن تترجم النص', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(
      translations: AppTranslations(),
      locale: Locale('ar', 'EG'),
      home: Scaffold(
        body: Text('hello'.tr),
      ),
    ),
  );

  expect(find.text('مرحباً'), findsOneWidget);
});
```

### اختبار trParams

```dart
test('يجب أن تستبدل المعاملات', () {
  Sint.updateLocale(Locale('ar', 'EG'));

  final result = 'greeting'.trParams({
    'name': 'أحمد',
    'count': '5',
  });

  expect(result, contains('أحمد'));
  expect(result, contains('5'));
});
```

### اختبار trPlural

```dart
test('يجب أن تتعامل مع الجمع بشكل صحيح', () {
  Sint.updateLocale(Locale('ar', 'EG'));

  expect('items'.trPlural('items', 0), 'لا توجد عناصر');
  expect('items'.trPlural('items', 1), 'عنصر واحد');
  expect('items'.trPlural('items', 2), 'عنصران');
  expect('items'.trPlural('items', 5), contains('5'));
});
```

### اختبار تغيير اللغة

```dart
testWidgets('يجب أن تحدث الواجهة عند تغيير اللغة', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(
      translations: AppTranslations(),
      locale: Locale('en', 'US'),
      home: Scaffold(
        body: Text('hello'.tr),
      ),
    ),
  );

  expect(find.text('Hello'), findsOneWidget);

  Sint.updateLocale(Locale('ar', 'EG'));
  await tester.pumpAndSettle();

  expect(find.text('مرحباً'), findsOneWidget);
});
```

### اختبار اللغة الاحتياطية

```dart
testWidgets('يجب أن تستخدم اللغة الاحتياطية للمفاتيح المفقودة', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(
      translations: AppTranslations(),
      locale: Locale('fr', 'FR'), // لغة غير مدعومة
      fallbackLocale: Locale('en', 'US'),
      home: Scaffold(
        body: Text('hello'.tr),
      ),
    ),
  );

  expect(find.text('Hello'), findsOneWidget); // من اللغة الاحتياطية
});
```

### اختبار حفظ واسترجاع اللغة

```dart
test('يجب أن تحفظ اللغة المختارة', () async {
  final controller = LanguageController();
  await controller.changeLanguage('ar', 'EG');

  final storage = Sint.find<StorageService>();
  expect(storage.read('language_code'), 'ar');
  expect(storage.read('country_code'), 'EG');
});

test('يجب أن تسترجع اللغة المحفوظة', () async {
  final storage = Sint.find<StorageService>();
  storage.write('language_code', 'ar');
  storage.write('country_code', 'EG');

  final controller = LanguageController();
  controller.loadSavedLanguage();

  expect(Sint.locale?.languageCode, 'ar');
  expect(Sint.locale?.countryCode, 'EG');
});
```

### اختبار اتجاه النص

```dart
testWidgets('يجب أن يستخدم الاتجاه الصحيح', (tester) async {
  await tester.pumpWidget(
    SintMaterialApp(
      translations: AppTranslations(),
      locale: Locale('ar', 'EG'),
      home: Scaffold(
        body: Text('hello'.tr),
      ),
    ),
  );

  final textWidget = tester.widget<Text>(find.text('مرحباً'));
  final directionality = tester.widget<Directionality>(
    find.ancestor(
      of: find.text('مرحباً'),
      matching: find.byType(Directionality),
    ).first,
  );

  expect(directionality.textDirection, TextDirection.rtl);
});
```

### اختبار الترجمات المتداخلة

```dart
test('يجب أن تدعم المفاتيح المتداخلة', () {
  Sint.updateLocale(Locale('ar', 'EG'));

  expect('errors.network'.tr, 'خطأ في الاتصال بالشبكة');
  expect('user.name'.tr, 'الاسم');
});
```

### استراتيجية الاختبار الشاملة

1. **اختبار الإعداد**: Translations class, keys structure
2. **اختبار الترجمة الأساسية**: .tr extension
3. **اختبار المعاملات**: trParams مع قيم مختلفة
4. **اختبار الجمع**: trPlural مع أعداد مختلفة
5. **اختبار تغيير اللغة**: updateLocale وتحديث الواجهة
6. **اختبار اللغة الاحتياطية**: fallbackLocale
7. **اختبار الحفظ**: storage integration
8. **اختبار RTL/LTR**: text direction
9. **اختبار المفاتيح المفقودة**: missing keys handling
10. **اختبار الأداء**: سرعة الترجمة مع آلاف المفاتيح
11. **اختبار التوافق**: device locale detection
12. **اختبار الترجمات المتداخلة**: nested keys
