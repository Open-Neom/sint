# SINT

**State, Injection, Navigation, Translation — Os Quatro Pilares da Infraestrutura Flutter de Alta Fidelidade.**

[![pub package](https://img.shields.io/pub/v/sint.svg?label=sint&color=blue)](https://pub.dev/packages/sint)

<div align="center">

**Idiomas:**

[![English](https://img.shields.io/badge/Language-English-blueviolet?style=for-the-badge)](../../README.md)
[![Spanish](https://img.shields.io/badge/Language-Spanish-blueviolet?style=for-the-badge)](../es_ES/README.md)
[![Arabic](https://img.shields.io/badge/Language-Arabic-blueviolet?style=for-the-badge)](../ar_EG/README.md)
[![French](https://img.shields.io/badge/Language-French-blueviolet?style=for-the-badge)](../fr_FR/README.md)
[![Portuguese](https://img.shields.io/badge/Language-Portuguese-blueviolet?style=for-the-badge)](#)
[![Russian](https://img.shields.io/badge/Language-Russian-blueviolet?style=for-the-badge)](../ru_RU/README.md)
[![Japanese](https://img.shields.io/badge/Language-Japanese-blueviolet?style=for-the-badge)](../ja_JP/README.md)
[![Chinese](https://img.shields.io/badge/Language-Chinese-blueviolet?style=for-the-badge)](../zh_CN/README.md)
[![Korean](https://img.shields.io/badge/Language-Korean-blueviolet?style=for-the-badge)](../kr_KO/README.md)
[![Indonesian](https://img.shields.io/badge/Language-Indonesian-blueviolet?style=for-the-badge)](../id_ID/README.md)
[![Turkish](https://img.shields.io/badge/Language-Turkish-blueviolet?style=for-the-badge)](../tr_TR/README.md)
[![Vietnamese](https://img.shields.io/badge/Language-Vietnamese-blueviolet?style=for-the-badge)](../vi_VI/README.md)

</div>

---

- [Sobre SINT](#sobre-sint)
- [Instalação](#instalação)
- [Os Quatro Pilares](#os-quatro-pilares)
  - [Gerenciamento de Estado (S)](#gerenciamento-de-estado-s)
  - [Injeção (I)](#injeção-i)
  - [Navegação (N)](#navegação-n)
  - [Tradução (T)](#tradução-t)
- [Aplicativo Contador com SINT](#aplicativo-contador-com-sint)
- [Migração do GetX](#migração-do-getx)
- [Origem e Filosofia](#origem-e-filosofia)

---

## Sobre SINT

SINT é uma evolução arquitetônica do GetX (v5.0.0-rc), construído como um framework focado em apenas quatro pilares:

| Pilar | Responsabilidade |
|---|---|
| **S** — Gerenciamento de Estado | `SintController`, `SintBuilder`, `Obx`, `.obs`, tipos Rx, Workers |
| **I** — Injeção | `Sint.put`, `Sint.find`, `Sint.lazyPut`, Bindings, SmartManagement |
| **N** — Navegação | `SintPage`, `Sint.toNamed`, middleware, `SintMaterialApp`, transições |
| **T** — Tradução | extensão `.tr`, classe `Translations`, gerenciamento de locale |

Tudo fora desses quatro pilares foi removido: sem cliente HTTP, sem animações, sem validadores de strings, sem utilitários genéricos. O resultado é **37.7% menos código** que GetX — 12,849 LOC vs 20,615 LOC.

**Princípios-chave:**

- **PERFORMANCE:** Sem sobrecarga de Streams ou ChangeNotifier. Consumo mínimo de RAM.
- **PRODUTIVIDADE:** Sintaxe simples. Uma única importação: `import 'package:sint/sint.dart';`
- **ORGANIZAÇÃO:** Estrutura de Clean Architecture. 5 módulos, cada um mapeado para um pilar.

---

## Instalação

Adicione SINT ao seu `pubspec.yaml`:

```yaml
dependencies:
  sint: ^1.0.0
```

Importe-o:

```dart
import 'package:sint/sint.dart';
```

---

## Os Quatro Pilares

### Gerenciamento de Estado (S)

Duas abordagens: **Reativa** (`.obs` + `Obx`) e **Simples** (`SintBuilder`).

```dart
// Reativa
var count = 0.obs;
Obx(() => Text('${count.value}'));

// Simples
SintBuilder<Controller>(
  builder: (_) => Text('${_.counter}'),
)
```

[Documentação completa](state_management.md)

### Injeção (I)

Injeção de dependências sem context:

```dart
Sint.put(AuthController());
final controller = Sint.find<AuthController>();
```

[Documentação completa](injection_management.md)

### Navegação (N)

Gerenciamento de rotas sem context:

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

[Documentação completa](navigation_management.md)

### Tradução (T)

Internacionalização com `.tr`:

```dart
Text('hello'.tr);
Text('welcome'.trParams({'name': 'Serzen'}));
Sint.updateLocale(Locale('pt', 'BR'));
```

[Documentação completa](translation_management.md)

---

## Aplicativo Contador com SINT

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

## Migração do GetX

1. Substitua `get:` por `sint:` no `pubspec.yaml`
2. Substitua `import 'package:get/get.dart'` por `import 'package:sint/sint.dart'`
3. Suas chamadas existentes de `Get.` funcionarão — substitua gradualmente por `Sint.` para remover avisos de depreciação
4. `GetMaterialApp` → `SintMaterialApp`
5. `GetPage` → `SintPage`

---

## Origem e Filosofia

SINT é um hard fork do GetX v5.0.0-rc. Após 8 anos de código acumulado, o repositório GetX tornou-se inativo e carregava peso significativo não utilizado. SINT remove tudo o que não serve aos quatro pilares, resultando em uma base limpa e sustentável construída com princípios de Clean Architecture.

**GetX:** "Fazer tudo."
**SINT:** "Fazer as coisas certas."

**S + I + N + T** — State, Injection, Navigation, Translation. Nada mais, nada menos.

---

## Licença

SINT é lançado sob a [Licença MIT](../../LICENSE).

Parte do ecossistema [Open Neom](https://github.com/Open-Neom).
