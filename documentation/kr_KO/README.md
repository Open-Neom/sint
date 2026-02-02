# SINT

**State, Injection, Navigation, Translation — 고충실도 Flutter 인프라의 네 가지 기둥.**

[![pub package](https://img.shields.io/pub/v/sint.svg?label=sint&color=blue)](https://pub.dev/packages/sint)

<div align="center">

**언어:**

[![English](https://img.shields.io/badge/Language-English-blueviolet?style=for-the-badge)](../../README.md)
[![Spanish](https://img.shields.io/badge/Language-Spanish-blueviolet?style=for-the-badge)](../es_ES/README.md)
[![Arabic](https://img.shields.io/badge/Language-Arabic-blueviolet?style=for-the-badge)](../ar_EG/README.md)
[![French](https://img.shields.io/badge/Language-French-blueviolet?style=for-the-badge)](../fr_FR/README.md)
[![Portuguese](https://img.shields.io/badge/Language-Portuguese-blueviolet?style=for-the-badge)](../pt_BR/README.md)
[![Russian](https://img.shields.io/badge/Language-Russian-blueviolet?style=for-the-badge)](../ru_RU/README.md)
[![Japanese](https://img.shields.io/badge/Language-Japanese-blueviolet?style=for-the-badge)](../ja_JP/README.md)
[![Chinese](https://img.shields.io/badge/Language-Chinese-blueviolet?style=for-the-badge)](../zh_CN/README.md)
[![Korean](https://img.shields.io/badge/Language-Korean-blueviolet?style=for-the-badge)](#)
[![Indonesian](https://img.shields.io/badge/Language-Indonesian-blueviolet?style=for-the-badge)](../id_ID/README.md)
[![Turkish](https://img.shields.io/badge/Language-Turkish-blueviolet?style=for-the-badge)](../tr_TR/README.md)
[![Vietnamese](https://img.shields.io/badge/Language-Vietnamese-blueviolet?style=for-the-badge)](../vi_VI/README.md)

</div>

---

- [SINT 소개](#sint-소개)
- [설치](#설치)
- [네 가지 기둥](#네-가지-기둥)
  - [상태 관리 (S)](#상태-관리-s)
  - [의존성 주입 (I)](#의존성-주입-i)
  - [내비게이션 (N)](#내비게이션-n)
  - [번역 (T)](#번역-t)
- [SINT를 사용한 카운터 앱](#sint를-사용한-카운터-앱)
- [GetX에서 마이그레이션](#getx에서-마이그레이션)
- [기원과 철학](#기원과-철학)

---

## SINT 소개

SINT는 GetX (v5.0.0-rc)의 아키텍처적 진화로, 네 가지 기둥에만 집중하는 프레임워크로 구축되었습니다:

| 기둥 | 책임 |
|---|---|
| **S** — 상태 관리 | `SintController`, `SintBuilder`, `Obx`, `.obs`, Rx 타입, Workers |
| **I** — 의존성 주입 | `Sint.put`, `Sint.find`, `Sint.lazyPut`, Bindings, SmartManagement |
| **N** — 내비게이션 | `SintPage`, `Sint.toNamed`, middleware, `SintMaterialApp`, 전환 효과 |
| **T** — 번역 | `.tr` 확장, `Translations` 클래스, 로케일 관리 |

이 네 가지 기둥 외의 모든 것이 제거되었습니다: HTTP 클라이언트, 애니메이션, 문자열 검증기, 범용 유틸리티가 없습니다. 결과는 GetX보다 **37.7% 적은 코드** — 12,849 LOC vs 20,615 LOC.

**핵심 원칙:**

- **성능:** Streams 또는 ChangeNotifier 오버헤드 없음. 최소 RAM 소비.
- **생산성:** 간단한 구문. 단일 임포트: `import 'package:sint/sint.dart';`
- **조직화:** 클린 아키텍처 구조. 5개 모듈, 각각 기둥에 매핑.

---

## 설치

`pubspec.yaml`에 SINT 추가:

```yaml
dependencies:
  sint: ^1.0.0
```

임포트:

```dart
import 'package:sint/sint.dart';
```

---

## 네 가지 기둥

### 상태 관리 (S)

두 가지 접근 방식: **반응형** (`.obs` + `Obx`) 및 **단순형** (`SintBuilder`).

```dart
// 반응형
var count = 0.obs;
Obx(() => Text('${count.value}'));

// 단순형
SintBuilder<Controller>(
  builder: (_) => Text('${_.counter}'),
)
```

[전체 문서](state_management.md)

### 의존성 주입 (I)

context 없는 의존성 주입:

```dart
Sint.put(AuthController());
final controller = Sint.find<AuthController>();
```

[전체 문서](injection_management.md)

### 내비게이션 (N)

context 없는 라우트 관리:

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

[전체 문서](navigation_management.md)

### 번역 (T)

`.tr`을 사용한 국제화:

```dart
Text('hello'.tr);
Text('welcome'.trParams({'name': 'Serzen'}));
Sint.updateLocale(Locale('ko', 'KR'));
```

[전체 문서](translation_management.md)

---

## SINT를 사용한 카운터 앱

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

## GetX에서 마이그레이션

1. `pubspec.yaml`에서 `get:`을 `sint:`로 교체
2. `import 'package:get/get.dart'`를 `import 'package:sint/sint.dart'`로 교체
3. 기존 `Get.` 호출은 작동합니다 — 지원 중단 경고를 제거하려면 점진적으로 `Sint.`로 교체
4. `GetMaterialApp` → `SintMaterialApp`
5. `GetPage` → `SintPage`

---

## 기원과 철학

SINT는 GetX v5.0.0-rc의 하드 포크입니다. 8년간 축적된 코드 후, GetX 저장소는 비활성화되었고 상당한 미사용 무게를 지니고 있었습니다. SINT는 네 가지 기둥에 기여하지 않는 모든 것을 제거하여 클린 아키텍처 원칙으로 구축된 깨끗하고 유지 관리 가능한 기반을 제공합니다.

**GetX:** "모든 것을 하라."
**SINT:** "올바른 것을 하라."

**S + I + N + T** — State, Injection, Navigation, Translation. 그 이상도 이하도 아닙니다.

---

## 라이선스

SINT는 [MIT 라이선스](../../LICENSE) 하에 배포됩니다.

[Open Neom](https://github.com/Open-Neom) 생태계의 일부입니다.
