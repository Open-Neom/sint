# SINT

**State, Injection, Navigation, Translation — Flutter高保真基础设施的四大支柱。**

[![pub package](https://img.shields.io/pub/v/sint.svg?label=sint&color=blue)](https://pub.dev/packages/sint)

<div align="center">

**语言:**

[![English](https://img.shields.io/badge/Language-English-blueviolet?style=for-the-badge)](../../README.md)
[![Spanish](https://img.shields.io/badge/Language-Spanish-blueviolet?style=for-the-badge)](../es_ES/README.md)
[![Arabic](https://img.shields.io/badge/Language-Arabic-blueviolet?style=for-the-badge)](../ar_EG/README.md)
[![French](https://img.shields.io/badge/Language-French-blueviolet?style=for-the-badge)](../fr_FR/README.md)
[![Portuguese](https://img.shields.io/badge/Language-Portuguese-blueviolet?style=for-the-badge)](../pt_BR/README.md)
[![Russian](https://img.shields.io/badge/Language-Russian-blueviolet?style=for-the-badge)](../ru_RU/README.md)
[![Japanese](https://img.shields.io/badge/Language-Japanese-blueviolet?style=for-the-badge)](../ja_JP/README.md)
[![Chinese](https://img.shields.io/badge/Language-Chinese-blueviolet?style=for-the-badge)](#)
[![Korean](https://img.shields.io/badge/Language-Korean-blueviolet?style=for-the-badge)](../kr_KO/README.md)
[![Indonesian](https://img.shields.io/badge/Language-Indonesian-blueviolet?style=for-the-badge)](../id_ID/README.md)
[![Turkish](https://img.shields.io/badge/Language-Turkish-blueviolet?style=for-the-badge)](../tr_TR/README.md)
[![Vietnamese](https://img.shields.io/badge/Language-Vietnamese-blueviolet?style=for-the-badge)](../vi_VI/README.md)

</div>

---

- [关于 SINT](#关于-sint)
- [安装](#安装)
- [四大支柱](#四大支柱)
  - [状态管理 (S)](#状态管理-s)
  - [依赖注入 (I)](#依赖注入-i)
  - [导航 (N)](#导航-n)
  - [翻译 (T)](#翻译-t)
- [使用 SINT 的计数器应用](#使用-sint-的计数器应用)
- [从 GetX 迁移](#从-getx-迁移)
- [起源与哲学](#起源与哲学)

---

## 关于 SINT

SINT 是 GetX (v5.0.0-rc) 的架构演进版本,构建为仅专注于四大支柱的框架:

| 支柱 | 职责 |
|---|---|
| **S** — 状态管理 | `SintController`, `SintBuilder`, `Obx`, `.obs`, Rx 类型, Workers |
| **I** — 依赖注入 | `Sint.put`, `Sint.find`, `Sint.lazyPut`, Bindings, SmartManagement |
| **N** — 导航 | `SintPage`, `Sint.toNamed`, middleware, `SintMaterialApp`, 转场动画 |
| **T** — 翻译 | `.tr` 扩展, `Translations` 类, 语言环境管理 |

这四大支柱之外的所有内容都已被移除:没有 HTTP 客户端、没有动画、没有字符串验证器、没有通用工具。结果是比 GetX **减少 37.7% 的代码** — 12,849 LOC vs 20,615 LOC。

**核心原则:**

- **性能:** 无 Streams 或 ChangeNotifier 开销。最小化 RAM 消耗。
- **生产力:** 简单的语法。单个导入: `import 'package:sint/sint.dart';`
- **组织性:** 清晰架构结构。5 个模块,每个映射到一个支柱。

---

## 安装

在 `pubspec.yaml` 中添加 SINT:

```yaml
dependencies:
  sint: ^1.0.0
```

导入它:

```dart
import 'package:sint/sint.dart';
```

---

## 四大支柱

### 状态管理 (S)

两种方法:**响应式** (`.obs` + `Obx`) 和 **简单式** (`SintBuilder`)。

```dart
// 响应式
var count = 0.obs;
Obx(() => Text('${count.value}'));

// 简单式
SintBuilder<Controller>(
  builder: (_) => Text('${_.counter}'),
)
```

[完整文档](state_management.md)

### 依赖注入 (I)

无需 context 的依赖注入:

```dart
Sint.put(AuthController());
final controller = Sint.find<AuthController>();
```

[完整文档](injection_management.md)

### 导航 (N)

无需 context 的路由管理:

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

[完整文档](navigation_management.md)

### 翻译 (T)

使用 `.tr` 的国际化:

```dart
Text('hello'.tr);
Text('welcome'.trParams({'name': 'Serzen'}));
Sint.updateLocale(Locale('zh', 'CN'));
```

[完整文档](translation_management.md)

---

## 使用 SINT 的计数器应用

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

## 从 GetX 迁移

1. 在 `pubspec.yaml` 中将 `get:` 替换为 `sint:`
2. 将 `import 'package:get/get.dart'` 替换为 `import 'package:sint/sint.dart'`
3. 现有的 `Get.` 调用仍可工作 — 逐步替换为 `Sint.` 以消除弃用警告
4. `GetMaterialApp` → `SintMaterialApp`
5. `GetPage` → `SintPage`

---

## 起源与哲学

SINT 是 GetX v5.0.0-rc 的硬分叉。经过 8 年的代码积累,GetX 存储库变得不活跃并承载了大量未使用的代码。SINT 剥离了所有不服务于四大支柱的内容,形成了一个基于清晰架构原则构建的干净、可维护的基础。

**GetX:** "做所有事情。"
**SINT:** "做正确的事情。"

**S + I + N + T** — State, Injection, Navigation, Translation。不多不少。

---

## 许可证

SINT 采用 [MIT 许可证](../../LICENSE) 发布。

[Open Neom](https://github.com/Open-Neom) 生态系统的一部分。
