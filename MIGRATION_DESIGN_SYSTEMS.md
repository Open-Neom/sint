# Material and Cupertino migration guide

**Status: preparation notice, September 12, 2026.** SINT 1.6.2 uses the
Material and Cupertino libraries included in the Flutter SDK. These integrations
remain supported. Their future SINT deprecation is planned only after stable
replacements and an actionable migration path are available.

This notice is documentation, including API documentation shown by IDEs. It does
not introduce a Dart `@Deprecated` diagnostic, a runtime warning, a dependency
change, or a requirement to migrate an existing application now.

The proposed `sint_material_ui`, `sint_cupertino_ui`, and
`package:sint/foundation.dart` entry point are **not available in this release**.
Do not add these proposed packages or imports to an application yet. Follow the
[implementation roadmap](https://github.com/Open-Neom/sint/blob/main/docs/roadmaps/design-systems-migration.md) and
[issue #12](https://github.com/Open-Neom/sint/issues/12) for the planned work.

The target is SINT **1.7.0** with opt-in standalone support and compatible legacy
APIs. This is a development target, not an available release. The current design
is being simplified around an adaptive `SintApp`; separate adapters are an
earlier proposal, not a requirement. Direct standalone dependencies would raise
the SDK minimum. See the [revised design](https://github.com/Open-Neom/sint/blob/main/docs/roadmaps/sint-app-minimal.md).
The preparation advice below still applies; exact replacement APIs and package
requirements will be documented with the implementation.

## What is changing

Flutter provides standalone design libraries alongside its SDK libraries:

| Design family | SDK library used by SINT today | Standalone library |
| --- | --- | --- |
| Material | `package:flutter/material.dart` | `package:material_ui/material_ui.dart` |
| Cupertino | `package:flutter/cupertino.dart` | `package:cupertino_ui/cupertino_ui.dart` |

Flutter 3.47 documents standalone adoption as opt-in. Its announcement plans
deprecation of the SDK design libraries for November 2026; that is not an
announcement that they have already been removed. Flutter's schedule and SINT's
support policy are separate. See the
[Flutter 3.47 announcement](https://flutter.dev/blog/whats-new-in-flutter-3-47)
and the [official migration guide](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui).

## What works today

Keep using SDK Material types with `SintMaterialApp`, its `.router` constructor,
and SINT's current theme APIs. For example:

```dart
import 'package:flutter/material.dart';
import 'package:sint/sint.dart';

void main() {
  runApp(
    SintMaterialApp(
      theme: ThemeData(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      sintPages: [
        SintPage(
          name: '/',
          page: () => const Scaffold(
            body: Center(child: Text('SINT')),
          ),
        ),
      ],
    ),
  );
}
```

Likewise, continue using SDK Cupertino types from
`package:flutter/cupertino.dart` with `SintCupertinoApp`. Upgrading Flutter
alone does not require replacing those imports throughout an existing SINT app.

SINT 1.6.2 declares Flutter >=3.32.0 and Dart >=3.8.0. The standalone packages
currently require Flutter >=3.44.0 and Dart >=3.12.0. Future adapters will publish
their own tested version ranges; this preparation notice does not raise SINT's
minimum SDK requirements. Check the [SINT manifest](pubspec.yaml),
[Material manifest](https://raw.githubusercontent.com/flutter/packages/main/packages/material_ui/pubspec.yaml),
and [Cupertino manifest](https://raw.githubusercontent.com/flutter/packages/main/packages/cupertino_ui/pubspec.yaml).

## Why changing an import can fail

`ThemeData` from the SDK and `ThemeData` from `material_ui` are different Dart
types, despite sharing a name. The same applies to `ThemeMode` and other
design-specific classes. Supplying a standalone theme to the current
`SintMaterialApp` can therefore produce a compile-time argument-type error.

This issue can affect Android, iOS, web, macOS, Windows, and Linux. Choosing
`Platform.isIOS`, `kIsWeb`, a phone model, or debug/profile/release mode cannot
convert those types. Dependencies and imports select the integration before
compilation. Platform checks still serve their normal purpose for presentation,
input behavior, and gestures.

An official compatibility bridge can supply inherited theme and localization
data to supported legacy widget subtrees. It cannot convert the parameters,
return types, or callbacks of a public API. It therefore does not fix a
standalone `ThemeData` passed to the legacy `SintMaterialApp` constructor.
Overlays may also appear outside a bridged subtree and need separate validation.
See [bridge capabilities and limitations](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui#bridge-capabilities-and-limitations).

## Prepare an application without changing its behavior

1. Inventory `SintMaterialApp` / `SintCupertinoApp`, including `.router`, themes,
   high-contrast themes, localization delegates, and scaffold keys.
2. Locate `Sint.changeTheme()`, `Sint.changeThemeMode()`, `Sint.theme`,
   `context.theme`, `context.textTheme`, and other theme-dependent extensions.
3. Review dialogs, bottom sheets, snackbars, page transitions, and any direct
   access to `Sint.rootController` or `ConfigData`.
4. Inspect your own packages and dependencies for public Material/Cupertino
   types. A service accepting `GlobalKey<ScaffoldState>` is a migration boundary
   even when the service itself does not render a widget. Coordinate both sides
   of that API rather than changing only the application's `main.dart`.
5. Record the SDK versions, supported platforms, and existing behavior of each
   app. Add or retain regression coverage around the boundaries above.

Avoid applying `dart fix --apply --code=migrate_design_widgets` across a SINT app
as a complete solution today. Flutter's migration can update imports while
SINT's public signatures still require SDK types. If evaluating that migration,
use an isolated branch and review every package boundary before adopting it.
For the supported configuration today, keep matching SDK types on both sides
of SINT's legacy APIs.

## Adoption steps after stable SINT adapters are released

These are planned steps, not instructions for installing a currently published
adapter. Exact package names, imports, and API replacements will be documented
with the release that implements them.

1. Select a released adapter and verify its SDK/dependency compatibility matrix.
   Applications that cannot meet those requirements can retain the supported
   legacy integration according to the published maintenance policy.
2. Add its documented dependencies and adopt its application host and visual
   imports together. Do not combine a standalone theme with a legacy host.
3. Migrate theme operations, extensions, keys, overlays, and shared package APIs
   to the adapter's documented equivalents. Existing SINT visual getters will
   not automatically change their return types when another package is imported.
4. Keep one shared SINT state/DI/navigation/translation runtime. The roadmap
   proposes adapters over the same canonical types, not duplicate controller
   registries. Verify that modules resolve the same registered instances.
5. Use documented bridges only for supported legacy subtrees. Do not assume two
   independent SINT application roots, or arbitrary mixed visual APIs, are safe.
6. Run the checks below, then roll out to a pilot app before other consumers.

## Checks before adopting an adapter

| Scope | What to verify |
| --- | --- |
| SDK and dependencies | Resolve and analyze at the documented minimum and a supported stable SDK; verify shared packages without local dependency overrides. |
| Themes and localization | Light/dark/system mode, runtime theme changes, high contrast, theme extensions, locale changes, translations, and RTL. |
| Navigation and lifecycle | Deep links, nested routes, returned results, controller identity, and disposal exactly once. |
| Overlays | Dialogs, sheets, snackbars, theme/locale inheritance, focus, accessibility, and dismissal. |
| Target platforms | Android back behavior, iOS swipe gestures, browser URLs/history, and desktop keyboard/mouse behavior on the platforms the app supports. |
| Build modes and devices | Debug correctness; profile/release builds and smoke checks; representative physical devices for gestures and rendering performance. |

Platform and device checks validate the chosen integration; they do not select
it. Compare performance under equivalent SDK, device, renderer, build mode, and
workload conditions. Moving libraries alone does not guarantee faster updates
or a smaller application.

## When formal deprecation will appear

SINT plans to add targeted `@Deprecated` annotations only after stable visual
replacements exist. Each notice should identify the exact replacement and link
to migration instructions and the announced support window. This does not
deprecate SINT's state, injection, or translation APIs, or the entire `sint.dart`
library.

Dart deprecation does not itself stop execution, but analyzer diagnostics can
fail consumer CI: `flutter analyze` treats infos as fatal by default. Introducing
those diagnostics requires a communicated transition, even when runtime
behavior stays compatible. This initial documentation notice avoids imposing
that migration pressure before a usable alternative is available.

There is no SINT removal date in this notice. Replacing public types or removing
legacy APIs requires an explicitly announced breaking release. See
[Dart's deprecation documentation](https://api.dart.dev/dart-core/Deprecated-class.html),
[Flutter's analyzer command](https://github.com/flutter/flutter/blob/stable/packages/flutter_tools/lib/src/commands/analyze.dart),
and [Flutter's guidance for package authors](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui#guidance-for-package-authors).
