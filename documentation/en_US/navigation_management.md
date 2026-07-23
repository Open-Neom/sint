# Navigation Management

- [Setup](#setup)
- [Navigation without named routes](#navigation-without-named-routes)
- [Navigation with named routes](#navigation-with-named-routes)
  - [Dynamic URLs](#dynamic-urls)
  - [Extended route syntax](#extended-route-syntax)
  - [Route matching precedence](#route-matching-precedence)
  - [pathParams and queryParams](#pathparams-and-queryparams)
  - [Middleware](#middleware)
- [Navigation without context](#navigation-without-context)
  - [SnackBars](#snackbars)
  - [Dialogs](#dialogs)
  - [BottomSheets](#bottomsheets)
- [Nested Navigation](#nested-navigation)
- [SintPage Middleware](#sintpage-middleware)
- [Web navigation](#web-navigation)
- [Transitions](#transitions)
- [Test Roadmap](#test-roadmap)

---

SINT's **Navigation** pillar provides route management, dialogs, snackbars, and bottomsheets — all without requiring `BuildContext`.

---

## Setup

Replace `MaterialApp` with `SintMaterialApp`:

```dart
SintMaterialApp(
  home: MyHome(),
)
```

---

## Navigation without named routes

```dart
// Navigate forward
Sint.to(NextScreen());

// Go back
Sint.back();

// Navigate and remove previous screen
Sint.off(NextScreen());

// Navigate and remove all previous screens
Sint.offAll(NextScreen());

// Navigate and receive data on return
var result = await Sint.to(PaymentScreen());
```

Return data from a screen:

```dart
Sint.back(result: 'success');
```

---

## Navigation with named routes

```dart
Sint.toNamed('/details');
Sint.offNamed('/home');
Sint.offAllNamed('/login');
```

Define routes:

```dart
SintMaterialApp(
  initialRoute: '/',
  getPages: [
    SintPage(name: '/', page: () => HomePage()),
    SintPage(name: '/details', page: () => DetailsPage()),
    SintPage(
      name: '/profile/:userId',
      page: () => ProfilePage(),
      transition: Transition.cupertino,
    ),
  ],
  unknownRoute: SintPage(name: '/404', page: () => NotFoundPage()),
)
```

### Dynamic URLs

```dart
Sint.toNamed('/profile/34954?flag=true&country=mx');
```

```dart
print(Sint.parameters['userId']); // 34954
print(Sint.parameters['flag']);   // true
print(Sint.parameters['country']); // mx
```

Path parameters are decoded per segment: a literal `+` stays a plus
(only `%20` decodes to a space — use `%20` or query parameters for
spaces), and `%2F` decodes to `/` after the segment split.

### Extended route syntax

Beyond simple `:param` segments, route names support:

```dart
SintPage(name: '/user/:id', page: () => UserPage()),          // simple param
SintPage(name: '/user/:id?', page: () => UserPage()),         // optional param: matches '/user' and '/user/42'
SintPage(name: '/user/:id(\d+)', page: () => UserPage()),     // pattern param: digits only
SintPage(name: '/docs/:path*', page: () => DocsPage()),       // wildcard: one or more remaining segments
```

- **Optional params** (`:id?`) match the route with or without the
  segment; when absent, the param is simply not present.
- **Pattern params** (`:id(\d+)`) only match when the segment satisfies
  the custom constraint — `/user/42` matches, `/user/abc` does not.
- **Wildcards** (`:path*`) capture one or more remaining segments,
  `/` separators included: `/docs/a/b/c` gives `pathParams['path'] ==
  'a/b/c'`. At least one segment is required (`/docs` alone does not
  match).
- In dotted params (`/file.:ext`) the `.` is a literal separator, not a
  regex wildcard.

Registering two routes that compile to the same pattern logs a warning
via `Sint.log` — the first registered route still wins.

### Route matching precedence

When several routes could match a URL, the router evaluates candidates
in this order (registration order is preserved within each type):

**literal > param with pattern > simple param > wildcard**

> Behavior note: a literal registered *after* a param route now wins for
> its exact URL (e.g. `/user/new` resolves to the literal even if
> `/user/:id` was registered first). In earlier versions the first
> registered route always won. This is an intentional change.

### pathParams and queryParams

Build concrete URLs from route templates with correct per-segment
encoding:

```dart
Sint.toNamed(
  '/user/:id',
  pathParams: {'id': '42'},
  queryParams: {'tab': 'posts'},
);
// navigates to /user/42?tab=posts
```

`pathParams` and `queryParams` are also available on `Sint.offNamed` and
`Sint.offAllNamed`. Values are encoded per segment — a `/` inside a path
param value becomes `%2F` and decodes back correctly.

Read path and query parameters separately:

```dart
Sint.pathParams['id'];   // '42'  (path segments only)
Sint.queryParams['tab']; // 'posts' (query string only)
Sint.parameters['id'];   // '42'  (legacy merged view, unchanged)
```

The same separation exists on `PageSettings.pathParams` /
`PageSettings.queryParams` (and `RouteDecoder`). The merged
`Sint.parameters` keeps its previous behavior.

### Middleware

```dart
SintMaterialApp(
  routingCallback: (routing) {
    if (routing.current == '/premium') {
      checkSubscription();
    }
  },
)
```

---

## Navigation without context

### SnackBars

```dart
Sint.snackbar('Title', 'Message');
```

With customization:

```dart
Sint.snackbar(
  'Alert',
  'Something happened',
  icon: Icon(Icons.warning),
  duration: Duration(seconds: 3),
  isDismissible: true,
);
```

### Dialogs

```dart
Sint.dialog(MyDialogWidget());

Sint.defaultDialog(
  onConfirm: () => print('Confirmed'),
  middleText: 'Are you sure?',
);
```

### BottomSheets

```dart
Sint.bottomSheet(
  Container(
    child: Wrap(
      children: [
        ListTile(
          leading: Icon(Icons.music_note),
          title: Text('Music'),
          onTap: () {},
        ),
      ],
    ),
  ),
);
```

---

## Nested Navigation

```dart
Navigator(
  key: Sint.nestedKey(1),
  initialRoute: '/',
  onGenerateRoute: (settings) {
    if (settings.name == '/') {
      return SintPageRoute(
        page: () => MainScreen(),
      );
    }
    return null;
  },
)
```

Navigate within a nested navigator:

```dart
Sint.toNamed('/details', id: 1);
```

---

## SintPage Middleware

Attach middleware to routes:

```dart
SintPage(
  name: '/admin',
  page: () => AdminPanel(),
  middlewares: [AuthMiddleware()],
)
```

Middleware hooks:
- `redirect` — redirect before page loads
- `onPageCalled` — modify page before creation
- `onBindingsStart` — modify bindings before initialization
- `onPageBuildStart` — called after bindings, before page build
- `onPageBuilt` — called after page is built
- `onPageDispose` — called when page is disposed

Middlewares run ordered by their `priority` (lower first) in both
middleware pipelines. The sort is stable: among equal priorities the
declaration order is preserved.

```dart
class AuthMiddleware extends SintMiddleware {
  AuthMiddleware() : super(priority: -8); // runs before priority 0
}
```

Redirect chains are guarded against cycles: if redirects (via
`redirect` or `redirectDelegate`) chain beyond a depth of 5, navigation
fails with a clear `Redirect loop detected` error instead of looping
forever.

---

## Web navigation

### URL strategy

Control the browser URL strategy explicitly in `main()`, BEFORE
`runApp()`:

```dart
void main() {
  SintUrlStrategy.setPath(); // path-based URLs: /home (no '#')
  // or SintUrlStrategy.setHash(); // hash-based URLs: /#/home
  runApp(MyApp());
}
```

When a strategy is configured this way, `SintDelegate` respects it and
does not override it. On non-web platforms both calls are no-ops.

### Browser back/forward

The browser history and the internal navigation stack stay in sync:
when the browser asks for a URL that already exists in the stack (Back/
Forward buttons), the router pops the entries above it — completing
their completers through the normal pop path — instead of pushing a
duplicate.

### State restoration

`RouteInformation` now carries the route state (its arguments), and
`SintPage.copyWith` preserves `restorationId`, so state restoration can
recover route state correctly.

---

## Transitions

SINT includes built-in page transitions:

- `Transition.fade`
- `Transition.cupertino`
- `Transition.leftToRight` / `Transition.rightToLeft`
- `Transition.leftToRightWithFade` / `Transition.rightToLeftWithFade`
- `Transition.downToUp` / `Transition.upToDown`
- `Transition.zoom`
- `Transition.circularReveal`
- `Transition.size`
- `Transition.noTransition`

```dart
SintPage(
  name: '/details',
  page: () => DetailsPage(),
  transition: Transition.circularReveal,
  transitionDuration: Duration(milliseconds: 400),
)
```

---

## Test Roadmap

Tests for Navigation are retained from the original GetX test suite. Middleware chain tests (priority ordering, redirect guard) and named route parameter parsing tests (pattern params, wildcards, optional params) ship since 1.5.0. Future enhancements:

- **Deep link standardization** across AppInUse
- **Route analytics** integration with `neom_analytics`
- **Nested navigation improvements** for tab-based flows
- **VR/XR/AR spatial routing** via SintPage and middleware extensions
- Transition animation tests
- SnackBar/Dialog/BottomSheet lifecycle tests
