# Material and Cupertino migration guide

**Status: local development preview, SINT 1.7.0-dev.1, September 21, 2026.**
The current source includes `SintApp` using the standalone `material_ui` and
`cupertino_ui` libraries. This document describes that implementation; it does
not claim a stable release has been published or that every pilot build passed.

This version requires **Flutter >=3.44.0 and Dart >=3.12.0**. These requirements
apply to all consumers, including applications using `SintMaterialApp` or
`SintCupertinoApp`, because Pub resolves the new direct dependencies regardless
of which constructor an application uses. Projects staying on older SDKs must
keep a compatible SINT 1.6.x version until they can upgrade.

The previously proposed `sint_material_ui`, `sint_cupertino_ui` and
`package:sint/foundation.dart` are not needed for this implementation. Keep
`import 'package:sint/sint.dart';` and choose the appropriate design-library
imports. The [current design](docs/roadmaps/sint-app-minimal.md) supersedes the
separate-adapter proposal retained in the historical roadmap.

## Choose the application host

| Host | Theme types | Behavior |
| --- | --- | --- |
| `SintApp` | `material_ui.ThemeData`, `cupertino_ui.CupertinoThemeData` | Standalone; automatic Cupertino on iOS and Material on other target platforms. |
| `SintApp(design: SintDesign.material)` | Standalone themes | Material on every platform. |
| `SintApp(design: SintDesign.cupertino)` | Standalone themes | Cupertino on every platform. |
| `SintApp(theme: sdkTheme)` | `flutter/material.dart` `ThemeData` | Transitional, deprecated parameter; uses the legacy Material host, including on iOS. |
| `SintMaterialApp` / `SintCupertinoApp` | Their existing SDK types | Existing integration remains available. |

Automatic selection uses Flutter's `defaultTargetPlatform`. In a browser on
iOS, it selects Cupertino. Use an explicit design to keep a single presentation
across browser platforms. This selects a host, not new widget implementations:
a Material `Scaffold` does not become a `CupertinoPageScaffold` automatically.

Both standalone hosts reuse one `SintRoot`, route configuration, dependency
registry and translation runtime. `SintBuilder` and `Obx` continue handling
state; they do not need platform/theme selection logic.

## Standalone Material example

Declare `sint` using the development source/version being evaluated, and declare
`material_ui` and/or `cupertino_ui` as direct app dependencies when importing
them. For local validation use a `path` dependency pointing at this checkout;
do not assume the preview is available from pub.dev. The current SINT constraints
are `material_ui: ">=1.1.1 <1.3.0"` and
`cupertino_ui: ">=1.0.0 <1.1.0"`; review the resolved versions in the
application's lockfile. The upper bounds preserve the declared Flutter 3.44
baseline: clean resolution to Material 1.3.0 / Cupertino 1.1.0 currently fails
there because those releases use `foundation.awaitNotRequired`, which that
Flutter version does not export. Re-evaluate these bounds when upstream fixes
the requirement or SINT deliberately raises its SDK floor.

```dart
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:sint/sint.dart';

void main() {
  runApp(
    SintApp(
      design: SintDesign.material,
      materialTheme: material.ThemeData.light(),
      materialDarkTheme: material.ThemeData.dark(),
      materialThemeMode: material.ThemeMode.system,
      initialRoute: '/',
      sintPages: [
        SintPage(
          name: '/',
          page: () => const material.Scaffold(
            body: Center(child: Text('SINT')),
          ),
        ),
      ],
    ),
  );
}
```

For adaptive presentation, remove the explicit `design` above and optionally
add `cupertinoTheme` using the following import and type:

```dart
import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;

// Inside SintApp(...):
cupertinoTheme: const cupertino.CupertinoThemeData(
  brightness: Brightness.dark,
),
```

That fragment is configuration, not a complete Dart program. `cupertinoTheme`
controls the Cupertino host; Material's `materialThemeMode` controls its Material
host. A host uses its own default theme when its theme argument is omitted.
`SintApp.router` provides the same design choices and accepts an explicit router.
Do not combine `routerConfig` with separate router arguments.

## Theme API changes

Migrate imports and typed calls together. These are replacements when moving to
the standalone host, not automatic conversions of existing theme objects.

| SDK Material integration | Standalone integration |
| --- | --- |
| `theme: ThemeData(...)` | `materialTheme: material.ThemeData(...)` |
| `darkTheme: ThemeData.dark()` | `materialDarkTheme: material.ThemeData.dark()` |
| `themeMode: ThemeMode.system` | `materialThemeMode: material.ThemeMode.system` |
| `highContrastTheme` / `highContrastDarkTheme` | `materialHighContrastTheme` / `materialHighContrastDarkTheme` |
| `scaffoldMessengerKey` | `materialScaffoldMessengerKey`, typed as `GlobalKey<material.ScaffoldMessengerState>` |
| `Sint.changeTheme(...)` | `Sint.changeMaterialTheme(...)` or `Sint.changeCupertinoTheme(...)` with the matching type |
| `Sint.changeThemeMode(...)` | `Sint.changeMaterialThemeMode(material.ThemeMode.dark)` |
| `Sint.theme` / `context.theme` | `Sint.materialTheme` / `context.materialTheme`, or their `cupertinoTheme` equivalents |
| `context.textTheme` | `context.materialTextTheme` |

The legacy getters and setters keep their original signatures. They do not
change return/parameter types according to the selected device. Update theme
operations when adopting the new host; a call to the legacy setter does not
update the standalone theme configuration. Call the standalone setters after
mounting a standalone `SintApp`; they reject a legacy host.

Review nested design-specific values too: `TextTheme`, `TimePickerThemeData`,
`ColorScheme`, `ThemeMode`, `ScaffoldState` and `ScaffoldMessengerState` must
come from the matching library. Shared Flutter contracts such as `Widget`,
`BuildContext`, `NavigatorState`, `Color` and `Brightness` retain their identity.

## Keep a legacy application working during migration

`SintMaterialApp` and `SintCupertinoApp` remain available with SDK imports.
Updating to this development version does not switch their presentation. The
SDK requirement of this SINT version still applies.

The new facade also provides `SintApp(theme: sdkTheme)` as a temporary legacy
Material path. It emits an analyzer deprecation notice explaining the type
mismatch and pointing to `materialTheme` / `cupertinoTheme`. The legacy object
is never cast to a standalone type. Combining `theme` with standalone themes,
`materialScaffoldMessengerKey` or `SintDesign.cupertino` throws a configuration
error, including in release mode.

The targeted annotation on `SintApp.theme` does not deprecate all of SINT, the
existing app classes, or the state/injection/translation APIs. There is no
announced removal date. Dart deprecation does not stop execution, but
`flutter analyze` can treat deprecation diagnostics as fatal in consumer CI.
Plan the import/API update instead of suppressing diagnostics across the app.

## Mixed widget trees and overlays

`SintApp` enables temporary legacy compatibility by default. Its bridges supply
SDK themes/localizations to legacy descendants, including the app's `builder`,
and provide an SDK scaffold messenger. This supports gradual migration of
shared modules while the host uses standalone libraries.

These utilities map common inherited data. They do not convert public method
parameters, callback signatures, widget keys or every component theme. A
service accepting `GlobalKey<ScaffoldState>` remains a cross-package migration
boundary. Migrate both sides of that API together. See Flutter's
[bridge capabilities and limitations](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui#bridge-capabilities-and-limitations).

Keep `enableLegacyCompatibility: true` while application pages or dependencies
need SDK widgets. Opt out only after checking those subtrees and the overlay
operations actually used by the application. Validate dialogs, sheets,
snackbars, localization and theme inheritance in both host modes. A successful
compilation does not prove those inherited-widget requirements at runtime.

In this preview, `Sint.dialog` and `Sint.bottomSheet` select the standalone
infrastructure under `SintApp`. `Sint.defaultDialog` still builds SDK Material
widgets, and `Sint.snackbar(mainButton:)` still accepts the SDK `TextButton`
type. Keep compatibility enabled for these convenience APIs. To supply a
standalone action widget, `Sint.rawSnackbar(mainButton:)` accepts `Widget`;
alternatively use the standalone library's snackbar through its scaffold
messenger. A bridge cannot convert the `mainButton` parameter's Dart type.

Custom `localizationsDelegates` precede the standalone default delegates, so
applications can override their types. When migrating custom localization APIs,
use the standalone library's types and delegates. SINT translation dictionaries
and `.tr` are independent of that change.

## Migration sequence and validation

1. Upgrade the application's Flutter/Dart SDK and resolve SINT's current
   dependency graph; check shared modules and lockfiles.
2. Adopt `SintApp` and matching theme types. Fix the presentation explicitly to
   Material if the application should remain Material on iOS.
3. Update theme queries/setters, keys and custom localization types. Review
   app builders, failure/bootstrap screens and any wrapper such as `SentinelApp`.
4. Migrate shared UI modules gradually, retaining compatibility bridges while
   they contain SDK widgets. Do not apply an import migration blindly across
   package boundaries with different public types.
5. Run package and application validation separately. Record the SDK, commit,
   target and build mode for each result before distributing a stable release.

| Scope | Required evidence |
| --- | --- |
| SDK | Package resolution, analysis and tests on the supported baseline and a current stable SDK. |
| Host/themes | iOS vs other-platform selection, explicit overrides, both theme families, theme updates, dark/system/high contrast and legacy fallback. |
| Shared runtime | One controller/DI registry, route results and controller disposal without duplication. |
| Mixed UI | Legacy and standalone pages, builder overlays, theme/localization inheritance, dialogs, sheets and snackbars. |
| Pilots | Cyberneom and Gigmeout on Android and web; Giglab's example application for native macOS. |
| Runtime | Launch/smoke checks, Android back, browser history/deep links and desktop input; widget tests are not equivalent to launching a compiled app. |

The package CI targets Flutter 3.44.4 and the latest stable Flutter 3.x. The
manifest floor remains 3.44.0; validating the exact floor remains part of the
release checklist. No performance improvement follows automatically from
moving libraries: compare equivalent SDK/device/build/workload configurations.

Flutter's SDK-library deprecation schedule and SINT's support policy are
separate. The [Flutter 3.47 announcement](https://flutter.dev/blog/whats-new-in-flutter-3-47)
describes opt-in adoption and planned SDK deprecation; it does not remove the
legacy libraries today. See also the [SINT manifest](pubspec.yaml),
[Dart deprecation documentation](https://api.dart.dev/dart-core/Deprecated-class.html)
and [package migration guidance](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui#guidance-for-package-authors).
