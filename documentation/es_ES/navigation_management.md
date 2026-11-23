# Gestión de Navegación (Pilar N)

- [Configuración del Host (`SintApp`)](#configuración-del-host-sintapp)
- [Navegación por Nombre y Rutas Tipadas (`SintRoute`)](#navegación-por-nombre-y-rutas-tipadas-sintroute)
- [Cerrar Páginas vs. Overlays (`Sint.back`, `Sint.pop`, `Sint.maybePop`)](#cerrar-páginas-vs-overlays-sintback-sintpop-sintmaybepop)
- [Sintaxis Extendida y Precedencia](#sintaxis-extendida-y-precedencia)
- [Middlewares (`SintMiddleware` y `globalMiddlewares`)](#middlewares-sintmiddleware-y-globalmiddlewares)
- [Overlays Sin Contexto (SnackBars, Dialogs, BottomSheets)](#overlays-sin-contexto-snackbars-dialogs-bottomsheets)
- [Navegación Anidada (`SintRouterOutlet`) y Diagnóstico](#navegación-anidada-sintrouteroutlet-y-diagnóstico)

---

El pilar **Navigation** de SINT combina un router basado en **Trie de Prefijos Multinivel** (`O(depth)` — **97.8× más rápido** en 1,000 rutas compartidas), liberación automática de DI ligada a rutas, middlewares Navigator 2.0 y overlays sin `BuildContext`.

---

## Configuración del Host (`SintApp`)

```dart
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sint/sint.dart';

void main() => runApp(
  SintApp(
    materialTheme: ThemeData(),
    initialRoute: '/',
    globalMiddlewares: [AuthGuard()],
    sintPages: [
      SintPage(name: '/', page: () => const HomePage()),
      SintPage(
        name: '/profile/:userId',
        page: () => const ProfilePage(),
        transition: Transition.cupertino,
      ),
    ],
    unknownRoute: SintPage(name: '/404', page: () => const NotFoundPage()),
  ),
);
```

> Usa siempre `initialRoute:` + `sintPages:` (evita el parámetro deprecado `home:` o el nombre heredado `getPages:`).

---

## Navegación por Nombre y Rutas Tipadas (`SintRoute`)

```dart
Sint.toNamed('/details');
Sint.toNamed('/profile/:userId', pathParams: {'userId': '42'}, queryParams: {'tab': 'posts'});
Sint.offNamed('/home');
Sint.offAndToNamed('/checkout');
Sint.offAllNamed('/login');

// Navegación anónima (pasa siempre una closure `() => Widget`):
final result = await Sint.to(() => const PaymentScreen());
Sint.off(() => const ReceiptScreen());

// Lectura segura de argumentos y parámetros (funciona incluso sin SintRoot en tests):
final args = Sint.argumentsAs<ProfileArgs>(); // null si no coincide el tipo
final userId = Sint.pathParams['userId'];
final tab = Sint.queryParams['tab'];
```

### Rutas Tipadas en Compilación (`SintRoute<TArgs, TResult>`)

```dart
const profileRoute = SintRoute<ProfileArgs, bool>('/profile/:id');

profileRoute.page(
  binds: [Bind.lazyPut(() => ProfileController())],
  page: () => const ProfilePage(),
);

final saved = await profileRoute.to(
  arguments: const ProfileArgs(tab: 1),
  pathParams: {'id': '42'},
);
```

---

## Cerrar Páginas vs. Overlays (`Sint.back`, `Sint.pop`, `Sint.maybePop`)

Nunca llames a `Navigator.of(context).*` directamente:

| Acción | API | Notas |
| --- | --- | --- |
| **Cerrar Dialog o BottomSheet** | `Sint.pop(result)` | Cierra el overlay activo con protección `canPop` sin cerrar la página subyacente. |
| **Cerrar una página** | `Sint.back(result: value)` | Saca la página actual del stack y libera sus controladores. |
| **Respetar `PopScope` / ruta raíz** | `await Sint.maybePop(result)` | Cierra overlays primero, respeta `PopScope(canPop: false)` y retorna `false` en raíz. |
| **Verificar si hay historial** | `Sint.canPop` / `Sint.canBack` | Comprobación sin `BuildContext`. |

---

## Sintaxis Extendida y Precedencia

```dart
SintPage(name: '/user/:id', page: () => const UserPage()),          // parámetro requerido
SintPage(name: '/user/:id?', page: () => const UserPage()),         // parámetro opcional
SintPage(name: '/user/:id(\\d+)', page: () => const UserPage()),    // parámetro con regex
SintPage(name: '/docs/:slug*', page: () => const DocsPage()),       // 0+ segmentos restantes
SintPage(name: '/files/:path+', page: () => const FilesPage()),     // 1+ segmentos restantes
```

Precedencia: **literal > parámetro con regex > parámetro simple > comodín**.

---

## Middlewares (`SintMiddleware` y `globalMiddlewares`)

```dart
class AuthGuard extends SintMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Sint.find<AuthService>();
    if (!auth.isLoggedIn && route != '/login') {
      return const RouteSettings(name: '/login');
    }
    return null;
  }
}
```

---

## Overlays Sin Contexto (SnackBars, Dialogs, BottomSheets)

```dart
Sint.snackbar('Guardado', 'Pista exportada con éxito');

final confirmed = await Sint.dialog<bool>(
  AlertDialog(
    title: const Text('Confirmar'),
    actions: [
      TextButton(onPressed: () => Sint.pop(false), child: const Text('Cancelar')),
      TextButton(onPressed: () => Sint.pop(true), child: const Text('Confirmar')),
    ],
  ),
);

await Sint.bottomSheet(const MixerSheet());
```

---

## Navegación Anidada (`SintRouterOutlet`) y Diagnóstico

```dart
SintRouterOutlet(
  anchorRoute: '/dashboard',
  initialRoute: '/dashboard/overview',
)

// Inspección del stack activo:
final nav = Sint.diagnostics.routesSnapshot();
```
