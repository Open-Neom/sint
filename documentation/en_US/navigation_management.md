# Navigation Management

- [Setup](#setup)
- [Navigation without named routes](#navigation-without-named-routes)
- [Navigation with named routes](#navigation-with-named-routes)
  - [Dynamic URLs](#dynamic-urls)
  - [Middleware](#middleware)
- [Navigation without context](#navigation-without-context)
  - [SnackBars](#snackbars)
  - [Dialogs](#dialogs)
  - [BottomSheets](#bottomsheets)
- [Nested Navigation](#nested-navigation)
- [SintPage Middleware](#sintpage-middleware)
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

Tests for Navigation are retained from the original GetX test suite. Future enhancements:

- **Deep link standardization** across Cyberneom, EMXI, and Gigmeout
- **Route analytics** integration with `neom_analytics`
- **Nested navigation improvements** for tab-based flows
- **VR/XR/AR spatial routing** via SintPage and middleware extensions
- Middleware chain tests (priority ordering, redirect)
- Named route parameter parsing tests
- Transition animation tests
- SnackBar/Dialog/BottomSheet lifecycle tests
