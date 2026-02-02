# SINT

**الحالة، الحقن، التنقل، الترجمة — الأعمدة الأربعة للبنية التحتية عالية الدقة في Flutter.**

[![pub package](https://img.shields.io/pub/v/sint.svg?label=sint&color=blue)](https://pub.dev/packages/sint)

<div align="center">

**اللغات:**

[![English](https://img.shields.io/badge/Language-English-blueviolet?style=for-the-badge)](../../README.md)
[![Spanish](https://img.shields.io/badge/Language-Spanish-blueviolet?style=for-the-badge)](../es_ES/README.md)
[![Arabic](https://img.shields.io/badge/Language-Arabic-blueviolet?style=for-the-badge)](#)
[![French](https://img.shields.io/badge/Language-French-blueviolet?style=for-the-badge)](../fr_FR/README.md)
[![Portuguese](https://img.shields.io/badge/Language-Portuguese-blueviolet?style=for-the-badge)](../pt_BR/README.md)
[![Russian](https://img.shields.io/badge/Language-Russian-blueviolet?style=for-the-badge)](../ru_RU/README.md)
[![Japanese](https://img.shields.io/badge/Language-Japanese-blueviolet?style=for-the-badge)](../ja_JP/README.md)
[![Chinese](https://img.shields.io/badge/Language-Chinese-blueviolet?style=for-the-badge)](../zh_CN/README.md)
[![Korean](https://img.shields.io/badge/Language-Korean-blueviolet?style=for-the-badge)](../kr_KO/README.md)
[![Indonesian](https://img.shields.io/badge/Language-Indonesian-blueviolet?style=for-the-badge)](../id_ID/README.md)
[![Turkish](https://img.shields.io/badge/Language-Turkish-blueviolet?style=for-the-badge)](../tr_TR/README.md)
[![Vietnamese](https://img.shields.io/badge/Language-Vietnamese-blueviolet?style=for-the-badge)](../vi_VI/README.md)

</div>

---

- [حول SINT](#حول-sint)
- [التثبيت](#التثبيت)
- [الأعمدة الأربعة](#الأعمدة-الأربعة)
  - [إدارة الحالة (S)](#إدارة-الحالة-s)
  - [الحقن (I)](#الحقن-i)
  - [التنقل (N)](#التنقل-n)
  - [الترجمة (T)](#الترجمة-t)
- [تطبيق العداد مع SINT](#تطبيق-العداد-مع-sint)
- [الترحيل من GetX](#الترحيل-من-getx)
- [الأصل والفلسفة](#الأصل-والفلسفة)

---

## حول SINT

SINT هو تطور معماري لـ GetX (v5.0.0-rc)، تم بناؤه كإطار عمل مركز على أربعة أعمدة فقط:

| العمود | المسؤولية |
|---|---|
| **S** — إدارة الحالة | `SintController`, `SintBuilder`, `Obx`, `.obs`, أنواع Rx, Workers |
| **I** — الحقن | `Sint.put`, `Sint.find`, `Sint.lazyPut`, Bindings, SmartManagement |
| **N** — التنقل | `SintPage`, `Sint.toNamed`, middleware, `SintMaterialApp`, انتقالات |
| **T** — الترجمة | امتداد `.tr`, فئة `Translations`, إدارة اللغة |

تم إزالة كل شيء خارج هذه الأعمدة الأربعة: لا يوجد عميل HTTP، لا رسوم متحركة، لا أدوات تحقق من النصوص، لا أدوات عامة. النتيجة هي **37.7% أقل من الكود** مقارنة بـ GetX — 12,849 LOC مقابل 20,615 LOC.

**المبادئ الأساسية:**

- **الأداء:** لا توجد عبء إضافي من Streams أو ChangeNotifier. استهلاك أدنى للذاكرة.
- **الإنتاجية:** صياغة بسيطة. استيراد واحد: `import 'package:sint/sint.dart';`
- **التنظيم:** بنية Clean Architecture. 5 وحدات، كل واحدة مرتبطة بعمود.

---

## التثبيت

أضف SINT إلى `pubspec.yaml`:

```yaml
dependencies:
  sint: ^1.0.0
```

استورده:

```dart
import 'package:sint/sint.dart';
```

---

## الأعمدة الأربعة

### إدارة الحالة (S)

نهجان: **تفاعلي** (`.obs` + `Obx`) و **بسيط** (`SintBuilder`).

```dart
// تفاعلي
var count = 0.obs;
Obx(() => Text('${count.value}'));

// بسيط
SintBuilder<Controller>(
  builder: (_) => Text('${_.counter}'),
)
```

[التوثيق الكامل](state_management.md)

### الحقن (I)

حقن التبعيات بدون context:

```dart
Sint.put(AuthController());
final controller = Sint.find<AuthController>();
```

[التوثيق الكامل](injection_management.md)

### التنقل (N)

إدارة المسارات بدون context:

```dart
SintMaterialApp(
  getPages: [
    SintPage(name: '/', page: () => Home()),
    SintPage(name: '/details', page: () => Details()),
  ],
)

Sint.toNamed('/details');
Sint.back();
Sint.snackbar('Title', 'Message');
```

[التوثيق الكامل](navigation_management.md)

### الترجمة (T)

التدويل مع `.tr`:

```dart
Text('hello'.tr);
Text('welcome'.trParams({'name': 'Serzen'}));
Sint.updateLocale(Locale('ar', 'EG'));
```

[التوثيق الكامل](translation_management.md)

---

## تطبيق العداد مع SINT

```dart
void main() => runApp(SintMaterialApp(home: Home()));

class Controller extends SintController {
  var count = 0.obs;
  increment() => count++;
}

class Home extends StatelessWidget {
  @override
  Widget build(context) {
    final c = Sint.put(Controller());
    return Scaffold(
      appBar: AppBar(title: Obx(() => Text("Clicks: ${c.count}"))),
      body: Center(
        child: ElevatedButton(
          child: Text("Go to Other"),
          onPressed: () => Sint.to(Other()),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: c.increment,
      ),
    );
  }
}

class Other extends StatelessWidget {
  final Controller c = Sint.find();
  @override
  Widget build(context) {
    return Scaffold(body: Center(child: Text("${c.count}")));
  }
}
```

---

## الترحيل من GetX

1. استبدل `get:` بـ `sint:` في `pubspec.yaml`
2. استبدل `import 'package:get/get.dart'` بـ `import 'package:sint/sint.dart'`
3. استدعاءات `Get.` الحالية ستعمل — استبدلها تدريجياً بـ `Sint.` لإزالة تحذيرات الإيقاف
4. `GetMaterialApp` → `SintMaterialApp`
5. `GetPage` → `SintPage`

---

## الأصل والفلسفة

SINT هو نسخة مستقلة (hard fork) من GetX v5.0.0-rc. بعد 8 سنوات من الكود المتراكم، أصبح مستودع GetX غير نشط وحمل وزناً كبيراً غير مستخدم. تزيل SINT كل ما لا يخدم الأعمدة الأربعة، مما يؤدي إلى أساس نظيف وقابل للصيانة مبني على مبادئ Clean Architecture.

**GetX:** "افعل كل شيء."
**SINT:** "افعل الأشياء الصحيحة."

**S + I + N + T** — الحالة، الحقن، التنقل، الترجمة. لا أكثر، لا أقل.

---

## الترخيص

تم إصدار SINT بموجب [ترخيص MIT](../../LICENSE).

جزء من نظام [Open Neom](https://github.com/Open-Neom).
