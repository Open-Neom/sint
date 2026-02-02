# SINT

**State, Injection, Navigation, Translation — Les Quatre Piliers de l'Infrastructure Flutter Haute-Fidélité.**

[![pub package](https://img.shields.io/pub/v/sint.svg?label=sint&color=blue)](https://pub.dev/packages/sint)

<div align="center">

**Langues:**

[![English](https://img.shields.io/badge/Language-English-blueviolet?style=for-the-badge)](../../README.md)
[![Spanish](https://img.shields.io/badge/Language-Spanish-blueviolet?style=for-the-badge)](../es_ES/README.md)
[![Arabic](https://img.shields.io/badge/Language-Arabic-blueviolet?style=for-the-badge)](../ar_EG/README.md)
[![French](https://img.shields.io/badge/Language-French-blueviolet?style=for-the-badge)](#)
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

- [À propos de SINT](#à-propos-de-sint)
- [Installation](#installation)
- [Les Quatre Piliers](#les-quatre-piliers)
  - [Gestion d'État (S)](#gestion-détat-s)
  - [Injection (I)](#injection-i)
  - [Navigation (N)](#navigation-n)
  - [Traduction (T)](#traduction-t)
- [Application Compteur avec SINT](#application-compteur-avec-sint)
- [Migration depuis GetX](#migration-depuis-getx)
- [Origine et Philosophie](#origine-et-philosophie)

---

## À propos de SINT

SINT est une évolution architecturale de GetX (v5.0.0-rc), construit comme un framework concentré sur quatre piliers uniquement:

| Pilier | Responsabilité |
|---|---|
| **S** — Gestion d'État | `SintController`, `SintBuilder`, `Obx`, `.obs`, types Rx, Workers |
| **I** — Injection | `Sint.put`, `Sint.find`, `Sint.lazyPut`, Bindings, SmartManagement |
| **N** — Navigation | `SintPage`, `Sint.toNamed`, middleware, `SintMaterialApp`, transitions |
| **T** — Traduction | extension `.tr`, classe `Translations`, gestion de locale |

Tout ce qui est en dehors de ces quatre piliers a été supprimé: pas de client HTTP, pas d'animations, pas de validateurs de chaînes, pas d'utilitaires génériques. Le résultat est **37.7% de code en moins** que GetX — 12,849 LOC vs 20,615 LOC.

**Principes clés:**

- **PERFORMANCE:** Pas de surcharge de Streams ou ChangeNotifier. Consommation minimale de RAM.
- **PRODUCTIVITÉ:** Syntaxe simple. Une seule importation: `import 'package:sint/sint.dart';`
- **ORGANISATION:** Structure Clean Architecture. 5 modules, chacun mappé à un pilier.

---

## Installation

Ajoutez SINT à votre `pubspec.yaml`:

```yaml
dependencies:
  sint: ^1.0.0
```

Importez-le:

```dart
import 'package:sint/sint.dart';
```

---

## Les Quatre Piliers

### Gestion d'État (S)

Deux approches: **Réactive** (`.obs` + `Obx`) et **Simple** (`SintBuilder`).

```dart
// Réactive
var count = 0.obs;
Obx(() => Text('${count.value}'));

// Simple
SintBuilder<Controller>(
  builder: (_) => Text('${_.counter}'),
)
```

[Documentation complète](state_management.md)

### Injection (I)

Injection de dépendances sans context:

```dart
Sint.put(AuthController());
final controller = Sint.find<AuthController>();
```

[Documentation complète](injection_management.md)

### Navigation (N)

Gestion des routes sans context:

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

[Documentation complète](navigation_management.md)

### Traduction (T)

Internationalisation avec `.tr`:

```dart
Text('hello'.tr);
Text('welcome'.trParams({'name': 'Serzen'}));
Sint.updateLocale(Locale('fr', 'FR'));
```

[Documentation complète](translation_management.md)

---

## Application Compteur avec SINT

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

## Migration depuis GetX

1. Remplacez `get:` par `sint:` dans `pubspec.yaml`
2. Remplacez `import 'package:get/get.dart'` par `import 'package:sint/sint.dart'`
3. Vos appels `Get.` existants fonctionneront — remplacez-les progressivement par `Sint.` pour supprimer les avertissements de dépréciation
4. `GetMaterialApp` → `SintMaterialApp`
5. `GetPage` → `SintPage`

---

## Origine et Philosophie

SINT est un hard fork de GetX v5.0.0-rc. Après 8 ans de code accumulé, le dépôt GetX est devenu inactif et portait un poids significatif inutilisé. SINT supprime tout ce qui ne sert pas les quatre piliers, résultant en une base propre et maintenable construite avec les principes de Clean Architecture.

**GetX:** "Tout faire."
**SINT:** "Faire les bonnes choses."

**S + I + N + T** — State, Injection, Navigation, Translation. Ni plus, ni moins.

---

## Licence

SINT est publié sous la [Licence MIT](../../LICENSE).

Fait partie de l'écosystème [Open Neom](https://github.com/Open-Neom).
