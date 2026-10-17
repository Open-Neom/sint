# SINT

<p align="center">
  <img src="https://raw.githubusercontent.com/Open-Neom/sint/main/assets/SINT%20-%20Logo%20-%202026.png" alt="SINT Framework" width="240"/>
</p>

<p align="center">
  <strong>State · Injection · Navigation · Translation</strong><br/>
  Micro-framework de alto rendimiento y Clean Architecture para Flutter.
</p>

<p align="center">
  <a href="https://pub.dev/packages/sint"><img src="https://img.shields.io/pub/v/sint.svg?label=sint&color=blue" alt="pub package"/></a>
  <a href="../../LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License: MIT"/></a>
</p>

---

## Los Cuatro Pilares

SINT se enfoca estrictamente en cuatro pilares fundamentales — sin clientes HTTP, validadores ni código innecesario:

| Pilar | APIs Principales | Guía |
| --- | --- | --- |
| **S — State** | `SintController`, `Obx`, `.obs`, `Sint.computed`, `Sint.batch`, `Sint.untrack`, `everSync` | [Documentación de Estado](state_management.md) |
| **I — Injection** | `Sint.put`, `Sint.lazyPut`, `Sint.putAsync`, `Sint.find`, `Bind`, `SmartManagement` | [Documentación de Inyección](injection_management.md) |
| **N — Navigation** | `SintApp`, `SintPage`, `SintRouterOutlet`, `Sint.toNamed`, `Sint.back`, `pathParams`, `queryParams` | [Documentación de Navegación](navigation_management.md) |
| **T — Translation** | `.tr`, `.trParams`, `Translations`, `Sint.updateLocale`, `Sint.loadTranslations`, `translateEndpoints` | [Documentación de Traducción](translation_management.md) |

---

## Novedades en 2.0.0

- **Sistemas de Diseño Independientes (`SintApp`)**: Soporte nativo para los paquetes independientes `material_ui` y `cupertino_ui` de Flutter 3.47+ (`Flutter >=3.44.0 / Dart >=3.12.0`), manteniendo `SintMaterialApp` y `SintCupertinoApp` para proyectos con el SDK clásico. Ver [MIGRATION_DESIGN_SYSTEMS.md](../../MIGRATION_DESIGN_SYSTEMS.md).
- **Motor SOTA de Signals (`Obx` $O(1)$ + `batch` + `computed` + `untrack`)**: Lleva la tríada moderna de Signals (inspirada en **SolidJS**, **Preact Signals** y **Angular Signals**) a Flutter — reconciliación incremental $O(1)$ en `Obx` con poda de ramas condicionales, `Sint.batch` sin asignaciones, `Sint.computed`, `Sint.untrack` / `rx.peek`, y `everSync` / `autoDispose` acoplados al controlador.
- **Router con Trie de Prefijos Multinivel**: Indexa todos los segmentos literales iniciales y reutiliza plantillas `PathDecoded` compiladas (**97.8× más rápido** en 1,000 rutas con prefijo compartido: `250.48 µs → 2.56 µs/op`).
- **Navegación Anidada (`SintRouterOutlet`)**: Outlets declarativos e `IndexedRouteBuilder` sincronizados con el historial imperativo.

---

## Inicio Rápido

```yaml
dependencies:
  sint: ^2.0.0
```

```dart
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sint/sint.dart';

class CartController extends SintController {
  final items = 1.obs;
  final price = 25.obs;
  late final total = computed(() => items.value * price.value); // Auto-disposed al cerrar la ruta

  void addBundle() => Sint.batch(() {
    items.value += 2;
    price.value = 20;
  });
}

void main() => runApp(
  SintApp(
    materialTheme: ThemeData(),
    initialRoute: '/',
    sintPages: [
      SintPage(
        name: '/',
        binds: [Bind.put(CartController())],
        page: () {
          final c = Sint.find<CartController>();
          return Scaffold(
            body: Center(child: Obx(() => Text('Total: \$${c.total.value}'))),
            floatingActionButton: FloatingActionButton(
              onPressed: c.addBundle,
              child: const Text('+'),
            ),
          );
        },
      ),
    ],
  ),
);
```

---

## Posicionamiento Arquitectónico y Benchmark de los 4 Pilares

### Por qué SINT 2.0 no es GetX (y por qué no requerir `BuildContext` es Clean Architecture)
GetX fue criticado por empaquetar utilidades ajenas (`GetConnect` HTTP/sockets, validadores), usar llaves `Type.toString()` vulnerables a la minificación Web/Wasm, dejar suscritas ramas condicionales en `Obx` y carecer de `batch` o `computed`. **SINT 2.0 reemplaza esa arquitectura interna** con:
1. **Alcance Estricto de 4 Pilares (`S · I · N · T`)**: Clean Architecture (`domain`, `engine`, `router`, `ui`) con cero utilidades externas.
2. **DI Tipado por `Type` Reificado y Limpieza $O(M)$ por Ruta**: Seguro ante minificación Web/Wasm; los controladores y señales `computed` se liberan determinísticamente al cerrar su ruta.
3. **Signals Síncronos Zero-Stream**: `StreamController` solo se instancia de forma perezosa si se invoca `.stream`/`.listen`; `Obx`, `Computed`, `Sint.batch` y `everSync` operan sobre listas síncronas de punteros.
4. **Por qué las APIs libres de `BuildContext` (`Sint.toNamed`, `Sint.find`, `.tr`) son seguras por diseño**: En Flutter, la navegación, los snackbars y el idioma pertenecen al host raíz (`NavigatorState` / `ScaffoldMessengerState`), no a los widgets hoja. Pasar `BuildContext` hacia controladores o callbacks asíncronos acopla la lógica de negocio a la UI y provoca errores `use_build_context_synchronously` tras un `await`. SINT vincula el ciclo de vida directamente a las rutas en `SintRoot`, eliminando el paso manual de `BuildContext` sin fugas de estado.

### Resolviendo los 4 Pilares: Velocidad de Desarrollo, Mantenimiento y Ahorro en Auditoría

Implementando una funcionalidad equivalente de 4 pilares (Estado Reactivo + Valor Derivado + DI por Ruta + Ruta con Parámetros + i18n + Snackbar):

| Dimensión | **SINT 2.0** | **Stack BLoC** (`bloc` + `get_it` + `go_router` + `intl`) | **Stack Riverpod** (`riverpod` + `go_router` + `intl`) | **Stack Provider** (`provider` + `go_router` + `intl`) | **GetX Legacy** |
| --- | --- | --- | --- | --- | --- |
| **Paquetes a Mantener y Auditar** | **1 (`sint`)** | 5+ paquetes externos | 4+ paquetes + `build_runner` | 4+ paquetes externos | 1 (con bloat HTTP/utils) |
| **Archivos Tocados por Feature** | **1–2 archivos** | 5–6 archivos (`event`, `state`, `bloc`, `locator`, `router`, `.arb`) | 4–5 archivos (`provider`, `.g.dart`, `router`, `.arb`) | 4 archivos (`notifier`, `MultiProvider`, `router`, `.arb`) | 1–2 archivos |
| **Codegen (`build_runner`)** | **0 archivos generados** | Opcional (`freezed`/`injectable`) + ARB | Obligatorio (`.g.dart` + ARB) | Codegen ARB | 0 archivos generados |
| **Boilerplate por Feature (LoC)** | **~35 LoC** | **~165 LoC** *(4.7× más código)* | **~115 LoC** *(3.3× más código + `.g.dart`)* | **~105 LoC** *(3.0× más código)* | ~40 LoC (sin `batch`/`computed`) |
| **Superficie de Auditoría y PR Review** | **Mínima (~70–80% menos código a auditar)** | Alta (eventos, `copyWith`, limpieza DI manual, 5 árboles de deps) | Media–Alta (`.g.dart` generados + paso de `WidgetRef`) | Media (`notifyListeners` manual + paso de `BuildContext`) | Alta (fugas globales, llaves String) |
| **Granularidad de Estado (S)** | **Signals finos (`Obx` $O(1)$, `batch`, `computed`, `untrack`)** | Stream asíncrono + `copyWith` inmutable | Grafo de providers (`ConsumerWidget`) | Objeto completo (`ChangeNotifier`) | `.obs` sin batch (fugas en ramas `if/else`) |
| **Ciclo DI ↔ Router (I ↔ N)** | **Nativo (auto-dispose $O(M)$ al salir de la ruta)** | Manual (`BlocProvider` / `GetIt`) | Acoplado al desmontaje del widget | Acoplado al `BuildContext` | Escaneo $O(N \times M)$ / llaves String |
| **Matching de Rutas (N)** | **Trie Multinivel ($O(\text{depth})$)** | Externo (`go_router`) | Externo (`go_router`) | Externo (`go_router`) | Escaneo lineal / 1er segmento |
| **Flutter 3.47+ Standalone UI** | **Nativo (`SintApp`)** | Configuración manual | Configuración manual | Configuración manual | Sin soporte (#3469) |

> **Impacto en Tiempo de Desarrollo y Auditoría:** Consolidar `S · I · N · T` bajo un único contrato determinístico reduce el volumen de código por feature en un **70%–78%**, elimina los tiempos de espera de `build_runner`, y reduce el **tiempo de revisión de PRs y auditoría de seguridad en ~3×–4×**: el auditor verifica **1 archivo cohesivo de ~35 LoC** con liberación automática atada a la ruta (`onClose`) y **1 solo árbol de dependencias**, en lugar de rastrear mutaciones, cierres manuales y compatibilidad de versiones a través de 5–6 archivos y 5 paquetes de terceros.

### Benchmarks Verificados de los 4 Pilares ([`four_pillars_benchmark_test.dart`](../../test/benchmarks/four_pillars_benchmark_test.dart))

> **¿Cómo es posible que `Sint.batch` sea más rápido tanto que `Rx` sin batch como que `ChangeNotifier` / `BLoC`?**
> 1. **Dentro de SINT (`0.23 µs` con batch vs `0.37 µs` sin batch — 1.6× más rápido):** Mutar 4 campos (`items`, `price`, `tax`, `discount`) sin `Sint.batch` recalcula inmediatamente el estado derivado (`total`) y ejecuta los listeners de `Obx` **4 veces seguidas**. Dentro de `Sint.batch`, cada mutación activa una bandera booleana sin asignaciones (`_queuedInBatch = true`, ~1ns) y pospone la evaluación hasta salir del bloque, recalculando `total` **1 sola vez** y notificando a `Obx` **1 sola vez** (**75% menos trabajo**).
> 2. **Contra `ChangeNotifier` (`0.90 µs`) y `BLoC` (`1.02 µs`) — 4.0× a 4.5× más rápido:** En una pantalla de 20 widgets donde solo 1 lee `total`, los modelos basados en objeto completo o streams notifican a los 20 widgets en cada mutación ($4 \times 20 = \mathbf{80\text{ callbacks de widgets}}$). El grafo fino por señal de SINT notifica **0 veces** a los 19 widgets no relacionados y **1 sola vez** al widget objetivo ($\mathbf{1\text{ callback vs }80}$).

| Carga de Trabajo | Mediana SINT 2.0 | Mediana Alternativa / Línea Base | Resultado |
| --- | ---: | ---: | --- |
| **Pilar S** — Pantalla de 20 Widgets, Transacción de 4 Campos + Total Derivado | **`0.23 µs/op`** (`Sint.batch` + `Computed`) | `0.37 µs/op` (`Rx` sin batch)<br/>`0.90 µs/op` (`ChangeNotifier`)<br/>`1.02 µs/op` (Copia Inmutable) | **1.6× más rápido** que `Rx` sin batch<br/>**4.0× – 4.5× más rápido** que `ChangeNotifier` / `BLoC` |
| **Pilar N** — 1,000 Rutas con Prefijo Compartido (`/api/item999/:id`) | **`2.56 µs/op`** (Trie Multinivel) | `250.48 µs/op` (Escaneo regex 1er segmento / lineal) | **97.8× más rápido** (escalado constante $O(\text{depth})$) |
| **Pilar I** — Búsqueda Caliente Tipada/Etiquetada (`Sint.find<T>`) | **`0.021 µs/op`** (Registro `Type` reificado) | — | **~47M búsquedas/seg** (seguro en Web/Wasm) |
| **Ciclo Completo S·I·N·T** (Match Ruta + `Sint.find` + `batch`/`computed` + `.trParams`) | **`3.57 µs/op`** | — | **~280,000 ciclos completos de 4 pilares/seg** |

---

## Migración desde GetX

1. Reemplaza `get:` por `sint: ^2.0.0` en tu `pubspec.yaml`.
2. Reemplaza `import 'package:get/get.dart';` por `import 'package:sint/sint.dart';`.
3. **Compatibilidad directa en `2.x`**: Tus llamadas existentes a `Get.`, `GetxController`, `GetMaterialApp`, `GetPage`, `GetBuilder` y `GetRouterOutlet` siguen compilando mediante alias `@Deprecated`, permitiéndote migrar gradualmente a símbolos `Sint*` antes de `3.0.0`.

---

## Documentación y Recursos

- **Guías por Pilar**: [Estado](state_management.md) · [Inyección](injection_management.md) · [Navegación](navigation_management.md) · [Traducción](translation_management.md)
- **Migración Material / Cupertino Standalone**: [MIGRATION_DESIGN_SYSTEMS.md](../../MIGRATION_DESIGN_SYSTEMS.md)
- **Benchmarks y Metodología**: [test/benchmarks/README.md](../../test/benchmarks/README.md) · [performance/README.md](../../performance/README.md)
- **Historial y Roadmap**: [CHANGELOG.md](../../CHANGELOG.md) · [ROADMAP.md](../../ROADMAP.md)

---

## Licencia

Distribuido bajo la [Licencia MIT](../../LICENSE). Parte del ecosistema [Open Neom](https://github.com/Open-Neom).
