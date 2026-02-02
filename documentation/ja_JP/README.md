# SINT

**State, Injection, Navigation, Translation — 高忠実度Flutterインフラストラクチャの4つの柱。**

[![pub package](https://img.shields.io/pub/v/sint.svg?label=sint&color=blue)](https://pub.dev/packages/sint)

<div align="center">

**言語:**

[![English](https://img.shields.io/badge/Language-English-blueviolet?style=for-the-badge)](../../README.md)
[![Spanish](https://img.shields.io/badge/Language-Spanish-blueviolet?style=for-the-badge)](../es_ES/README.md)
[![Arabic](https://img.shields.io/badge/Language-Arabic-blueviolet?style=for-the-badge)](../ar_EG/README.md)
[![French](https://img.shields.io/badge/Language-French-blueviolet?style=for-the-badge)](../fr_FR/README.md)
[![Portuguese](https://img.shields.io/badge/Language-Portuguese-blueviolet?style=for-the-badge)](../pt_BR/README.md)
[![Russian](https://img.shields.io/badge/Language-Russian-blueviolet?style=for-the-badge)](../ru_RU/README.md)
[![Japanese](https://img.shields.io/badge/Language-Japanese-blueviolet?style=for-the-badge)](#)
[![Chinese](https://img.shields.io/badge/Language-Chinese-blueviolet?style=for-the-badge)](../zh_CN/README.md)
[![Korean](https://img.shields.io/badge/Language-Korean-blueviolet?style=for-the-badge)](../kr_KO/README.md)
[![Indonesian](https://img.shields.io/badge/Language-Indonesian-blueviolet?style=for-the-badge)](../id_ID/README.md)
[![Turkish](https://img.shields.io/badge/Language-Turkish-blueviolet?style=for-the-badge)](../tr_TR/README.md)
[![Vietnamese](https://img.shields.io/badge/Language-Vietnamese-blueviolet?style=for-the-badge)](../vi_VI/README.md)

</div>

---

- [SINTについて](#sintについて)
- [インストール](#インストール)
- [4つの柱](#4つの柱)
  - [状態管理 (S)](#状態管理-s)
  - [依存性注入 (I)](#依存性注入-i)
  - [ナビゲーション (N)](#ナビゲーション-n)
  - [翻訳 (T)](#翻訳-t)
- [SINTを使ったカウンターアプリ](#sintを使ったカウンターアプリ)
- [GetXからの移行](#getxからの移行)
- [起源と哲学](#起源と哲学)

---

## SINTについて

SINTはGetX (v5.0.0-rc)のアーキテクチャ的進化であり、4つの柱のみに焦点を当てたフレームワークとして構築されています:

| 柱 | 責任 |
|---|---|
| **S** — 状態管理 | `SintController`, `SintBuilder`, `Obx`, `.obs`, Rx型, Workers |
| **I** — 依存性注入 | `Sint.put`, `Sint.find`, `Sint.lazyPut`, Bindings, SmartManagement |
| **N** — ナビゲーション | `SintPage`, `Sint.toNamed`, middleware, `SintMaterialApp`, トランジション |
| **T** — 翻訳 | `.tr`拡張, `Translations`クラス, ロケール管理 |

これら4つの柱の外にあるものはすべて削除されました: HTTPクライアント、アニメーション、文字列バリデーター、汎用ユーティリティはありません。結果は**GetXより37.7%少ないコード** — 12,849 LOC vs 20,615 LOC。

**主要原則:**

- **パフォーマンス:** StreamsやChangeNotifierのオーバーヘッドなし。最小限のRAM消費。
- **生産性:** シンプルな構文。1つのインポート: `import 'package:sint/sint.dart';`
- **組織化:** クリーンアーキテクチャ構造。5つのモジュール、各々が柱にマッピング。

---

## インストール

`pubspec.yaml`にSINTを追加:

```yaml
dependencies:
  sint: ^1.0.0
```

インポート:

```dart
import 'package:sint/sint.dart';
```

---

## 4つの柱

### 状態管理 (S)

2つのアプローチ: **リアクティブ** (`.obs` + `Obx`) と **シンプル** (`SintBuilder`)。

```dart
// リアクティブ
var count = 0.obs;
Obx(() => Text('${count.value}'));

// シンプル
SintBuilder<Controller>(
  builder: (_) => Text('${_.counter}'),
)
```

[完全なドキュメント](state_management.md)

### 依存性注入 (I)

contextなしの依存性注入:

```dart
Sint.put(AuthController());
final controller = Sint.find<AuthController>();
```

[完全なドキュメント](injection_management.md)

### ナビゲーション (N)

contextなしのルート管理:

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

[完全なドキュメント](navigation_management.md)

### 翻訳 (T)

`.tr`による国際化:

```dart
Text('hello'.tr);
Text('welcome'.trParams({'name': 'Serzen'}));
Sint.updateLocale(Locale('ja', 'JP'));
```

[完全なドキュメント](translation_management.md)

---

## SINTを使ったカウンターアプリ

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

## GetXからの移行

1. `pubspec.yaml`の`get:`を`sint:`に置き換え
2. `import 'package:get/get.dart'`を`import 'package:sint/sint.dart'`に置き換え
3. 既存の`Get.`呼び出しは動作します — 非推奨警告を削除するために徐々に`Sint.`に置き換え
4. `GetMaterialApp` → `SintMaterialApp`
5. `GetPage` → `SintPage`

---

## 起源と哲学

SINTはGetX v5.0.0-rcのハードフォークです。8年間の蓄積されたコードの後、GetXのリポジトリは非アクティブになり、使用されていない重要な重量を抱えていました。SINTは4つの柱に奉仕しないすべてを削除し、クリーンアーキテクチャの原則で構築されたクリーンで保守可能な基盤をもたらします。

**GetX:** 「すべてをする。」
**SINT:** 「正しいことをする。」

**S + I + N + T** — State, Injection, Navigation, Translation。それ以上でも以下でもない。

---

## ライセンス

SINTは[MITライセンス](../../LICENSE)の下でリリースされています。

[Open Neom](https://github.com/Open-Neom)エコシステムの一部。
