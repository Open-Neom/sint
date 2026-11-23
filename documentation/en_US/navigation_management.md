# Navigation Management (Pillar N)

- [App Host Setup (`SintApp`)](#app-host-setup-sintapp)
- [Named & Typed Navigation (`SintRoute`)](#named--typed-navigation-sintroute)
- [Dismissing Pages vs. Overlays (`Sint.back` vs `Sint.pop` vs `Sint.maybePop`)](#dismissing-pages-vs-overlays-sintback-vs-sintpop-vs-sintmaybepop)
- [Extended Route Templates & Precedence](#extended-route-templates--precedence)
- [Middlewares (`SintMiddleware` & `globalMiddlewares`)](#middlewares-sintmiddleware--globalmiddlewares)
- [Context-Free Overlays (SnackBars, Dialogs, BottomSheets)](#context-free-overlays-snackbars-dialogs-bottomsheets)
- [Nested Navigation (`SintRouterOutlet`)](#nested-navigation-sintrouteroutlet)
- [Transitions & Runtime Inspection](#transitions--runtime-inspection)

---

SINT's **Navigation** pillar combines a **Multi-Level Prefix Trie** router (`O(depth)` matching — **97.8× faster** on 1,000 shared-prefix routes), deterministic route-bound DI teardown, Navigator 2.0 middlewares, and context-free overlays with automatic fallback to plain `MaterialApp` / `CupertinoApp` widget-test harnesses.

---

## App Host Setup (`SintApp`)

`SintApp` is the modern standalone host for Flutter 3.47+ (`material_ui` and `cupertino_ui`). `SintMaterialApp` and `SintCupertinoApp` remain supported throughout `2.x`.

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

> Always prefer `initialRoute:` + `sintPages:` over the deprecated `home:` parameter or legacy `getPages:`.

---

## Named & Typed Navigation (`SintRoute`)

### String-Based Navigation

```dart
Sint.toNamed('/details');
Sint.toNamed('/profile/:userId', pathParams: {'userId': '42'}, queryParams: {'tab': 'posts'});
Sint.offNamed('/home');
Sint.offAndToNamed('/checkout');
Sint.offAllNamed('/login');

// Anonymous page push (always pass a closure `() => Widget` for proper lifecycle & transitions):
final result = await Sint.to(() => const PaymentScreen());
Sint.off(() => const ReceiptScreen());
```

Read parameters cleanly separated:

```dart
Sint.pathParams['userId'];       // '42' (path segments only; always takes precedence)
Sint.queryParams['tab'];         // 'posts' (query string only)
Sint.argumentsAs<ProfileArgs>(); // Safe typed lookup (null on mismatch or headless tests)
```

### Compile-Time Typed Routes (`SintRoute<TArgs, TResult>`)

```dart
const profileRoute = SintRoute<ProfileArgs, bool>('/profile/:id');

// Register in sintPages:
profileRoute.page(
  binds: [Bind.lazyPut(() => ProfileController())],
  page: () => const ProfilePage(),
);

// Navigate with compile-time argument & return types:
final saved = await profileRoute.to(
  arguments: const ProfileArgs(tab: 1),
  pathParams: {'id': '42'},
  queryParams: {'ref': 'feed'},
);
```

---

## Dismissing Pages vs. Overlays (`Sint.back` vs `Sint.pop` vs `Sint.maybePop`)

Never call `Navigator.of(context).*` directly in a SINT app:

| Action | API | Notes |
| --- | --- | --- |
| **Dismiss a Dialog or BottomSheet** | `Sint.pop(result)` | Pops the top overlay safely without accidentally popping the underlying page route (`canPop`-guarded). |
| **Pop a page route** | `Sint.back(result: value)` | Pops the current page route and auto-disposes its route-bound controllers. |
| **Honor `PopScope` / root-safe pop** | `await Sint.maybePop(result)` | Closes active overlays first, honors `PopScope(canPop: false)`, and returns `false` safely on root routes. |
| **Check if poppable** | `Sint.canPop` / `Sint.canBack` | Context-free check before showing custom back buttons. |

---

## Extended Route Templates & Precedence

```dart
SintPage(name: '/user/:id', page: () => const UserPage()),          // required param
SintPage(name: '/user/:id?', page: () => const UserPage()),         // optional param
SintPage(name: '/user/:id(\\d+)', page: () => const UserPage()),    // regex-constrained param
SintPage(name: '/docs/:slug*', page: () => const DocsPage()),       // 0+ remaining segments
SintPage(name: '/files/:path+', page: () => const FilesPage()),     // 1+ remaining segments
```

Precedence order: **literal > regex param > simple param > wildcard**.

---

## Middlewares (`SintMiddleware` & `globalMiddlewares`)

Override `redirect` (synchronous) or `redirectDelegate` (async). Guards are enforced consistently before stack mutations across `toNamed`, `offNamed`, `offNamedUntil`, `offAndToNamed`, `offAllNamed`, `off`, and `offAll`:

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

Attach globally via `SintApp(globalMiddlewares: [AuthGuard()])` or per-page via `SintPage(middlewares: [...])`.

---

## Context-Free Overlays (SnackBars, Dialogs, BottomSheets)

```dart
Sint.snackbar(
  'Saved',
  'Track exported successfully',
  duration: const Duration(seconds: 3),
);

final confirmed = await Sint.dialog<bool>(
  AlertDialog(
    title: const Text('Confirm'),
    actions: [
      TextButton(onPressed: () => Sint.pop(false), child: const Text('Cancel')),
      TextButton(onPressed: () => Sint.pop(true), child: const Text('Confirm')),
    ],
  ),
);

await Sint.bottomSheet(const MixerSheet());
```

All overlay APIs also fall back automatically to a mounted `MaterialApp` / `CupertinoApp` `NavigatorState` when testing modular widgets in isolation.

---

## Nested Navigation (`SintRouterOutlet`)

```dart
SintRouterOutlet(
  anchorRoute: '/dashboard',
  initialRoute: '/dashboard/overview',
)
```

Use `IndexedRouteBuilder` for persistent tab stacks synchronized with imperative `Sint.toNamed` calls.

---

## Transitions & Runtime Inspection

All 11 built-in transitions (`Transition.fade`, `Transition.fadeIn`, `Transition.cupertino`, `Transition.rightToLeft`, `Transition.downToUp`, `Transition.zoom`, etc.) are `const` with zero per-frame `Tween` allocations, and respect `materialTheme.pageTransitionsTheme`.

Inspect the live navigation stack at runtime via:

```dart
final nav = Sint.diagnostics.routesSnapshot();
// { treeInitialized, currentRoute, previousRoute, canBack, canPop, activePages, ... }
```
