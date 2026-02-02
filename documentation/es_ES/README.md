# SINT

**State, Injection, Navigation, Translation — Los Cuatro Pilares de la Infraestructura Flutter de Alta Fidelidad.**

[![pub package](https://img.shields.io/pub/v/sint.svg?label=sint&color=blue)](https://pub.dev/packages/sint)

<div align="center">

**Idiomas:**

[![English](https://img.shields.io/badge/Language-English-blueviolet?style=for-the-badge)](../../README.md)
[![Spanish](https://img.shields.io/badge/Language-Spanish-blueviolet?style=for-the-badge)](#)
[![Arabic](https://img.shields.io/badge/Language-Arabic-blueviolet?style=for-the-badge)](../ar_EG/README.md)
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

- [Acerca de SINT](#acerca-de-sint)
- [Instalación](#instalación)
- [Los Cuatro Pilares](#los-cuatro-pilares)
  - [Gestión de Estado (S)](#gestión-de-estado-s)
  - [Inyección (I)](#inyección-i)
  - [Navegación (N)](#navegación-n)
  - [Traducción (T)](#traducción-t)
- [Aplicación Contador con SINT](#aplicación-contador-con-sint)
- [Migración desde GetX](#migración-desde-getx)
- [Origen y Filosofía](#origen-y-filosofía)

---

## Acerca de SINT

SINT es una evolución arquitectónica de GetX (v5.0.0-rc), construido como un framework enfocado en solo cuatro pilares:

| Pilar | Responsabilidad                                                         |
|---|-------------------------------------------------------------------------|
| **S** — Gestión de Estado | `SintController`, `SintBuilder`, `Obx`, `.obs`, tipos Rx, Workers       |
| **I** — Inyección | `Sint.put`, `Sint.find`, `Sint.lazyPut`, Bindings, SmartManagement      |
| **N** — Navegación | `SintPage`, `Sint.toNamed`, middleware, `SintMaterialApp`, transiciones |
| **T** — Traducción | extensión `.tr`, clase `Translations`, gestión de locale                |

Todo lo que está fuera de estos cuatro pilares ha sido eliminado: sin cliente HTTP, sin animaciones, sin validadores de cadenas, sin utilidades genéricas. El resultado es **37.7% menos código** que GetX — 12,849 LOC vs 20,615 LOC.

**Principios clave:**

- **RENDIMIENTO:** Sin sobrecarga de Streams o ChangeNotifier. Consumo mínimo de RAM.
- **PRODUCTIVIDAD:** Sintaxis simple. Una sola importación: `import 'package:sint/sint.dart';`
- **ORGANIZACIÓN:** Estructura de Clean Architecture. 5 módulos, cada uno mapeado a un pilar.

---

## Instalación

Añade SINT a tu `pubspec.yaml`:

```yaml
dependencies:
  sint: ^1.0.0
```

Impórtalo:

```dart
import 'package:sint/sint.dart';
```

---

## Los Cuatro Pilares

### Gestión de Estado (S)

Dos enfoques: **Reactivo** (`.obs` + `Obx`) y **Simple** (`SintBuilder`).

```dart
// Reactivo
var count = 0.obs;
Obx(() => Text('${count.value}'));

// Simple
SintBuilder<Controller>(
  builder: (_) => Text('${_.counter}'),
)
```

[Documentación completa](state_management.md)

### Inyección (I)

Inyección de dependencias sin context:

```dart
Sint.put(AuthController());
final controller = Sint.find<AuthController>();
```

[Documentación completa](injection_management.md)

### Navegación (N)

Gestión de rutas sin context:

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

[Documentación completa](navigation_management.md)

### Traducción (T)

Internacionalización con `.tr`:

```dart
Text('hello'.tr);
Text('welcome'.trParams({'name': 'Serzen'}));
Sint.updateLocale(Locale('es', 'ES'));
```

[Documentación completa](translation_management.md)

---

## Aplicación Contador con SINT

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

## Migración desde GetX

1. Reemplaza `get:` con `sint:` en `pubspec.yaml`
2. Reemplaza `import 'package:get/get.dart'` con `import 'package:sint/sint.dart'`
3. Tus llamadas existentes a `Get.` funcionarán — reemplázalas gradualmente con `Sint.` para eliminar advertencias de deprecación
4. `GetMaterialApp` → `SintMaterialApp`
5. `GetPage` → `SintPage`

---

## Origen y Filosofía

SINT es un hard fork de GetX v5.0.0-rc. Después de 8 años de código acumulado, el repositorio de GetX se volvió inactivo y cargaba con un peso significativo sin usar. SINT elimina todo lo que no sirve a los cuatro pilares, resultando en una base limpia y mantenible construida con principios de Clean Architecture.

**GetX:** "Hacer todo."
**SINT:** "Hacer las cosas correctas."

**S + I + N + T** — State, Injection, Navigation, Translation. Nada más, nada menos.

---

## Licencia

SINT está publicado bajo la [Licencia MIT](../../LICENSE).

Parte del ecosistema [Open Neom](https://github.com/Open-Neom).
