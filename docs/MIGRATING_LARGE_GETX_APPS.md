# Migrating large GetX apps to SINT 2.3.0

This guide is for teams moving multi-module or 100+ file production GetX apps to
SINT 2.3.0 **without a big-bang rewrite or downtime**. SINT covers only the four
pillars (State, Injection, Navigation, Translation): it deliberately ships no
HTTP client, storage layer, or general-purpose utilities. Those responsibilities
move to your own services or to the packages you already use.

The `sint:migrate` CLI rewrites `pubspec.yaml` and safe `Get*` → `Sint*` symbols;
the `sint:audit` CLI reports the architectural findings that need a human
decision. Neither rewrites business logic, so plan on **incremental, reviewable
commits** rather than one automated pass.

> Target: SINT `^2.3.0`. The `@Deprecated` `Get*` aliases listed at the end
> remain functional throughout `2.x`, so state, DI, navigation and translation
> can be migrated module by module before `3.0.0`.

## 1. Establish a pre-migration baseline

Run both CLIs in read-only mode before changing code, and keep their output as
the "before" snapshot in your tracking issue:

```bash
# Preview every pubspec/symbol rewrite without touching disk.
dart run sint:migrate . --dry-run

# Read-only architectural lint (10 rules; --strict adds Flutter UI checks).
dart run sint:audit . --fail-on-warnings --strict

# Machine-readable report for CI / diffing between migration steps.
dart run sint:audit . --json > audit-before.json
```

Use `--rule=<code>` to focus on one finding type, and inline
`// sint-ignore: <code>` only when a finding is an intentional, documented
exception. Apply the mechanical part once the baseline is green:

```bash
dart run sint:migrate . --apply
dart run sint:audit . --fail-on-warnings --strict
```

Do not treat a clean audit as "migration complete": `sint_no_get_connect` and
`sint_back_inside_modal` findings need the manual changes described below
because SINT intentionally excludes their GetX implementations.

## 2. Replace `GetConnect` with `dio` or `http` inside a `SintService`

SINT has no HTTP pillar. Wrap `package:dio` (interceptors, retries, cancel
tokens) or `package:http` (minimal, testable) in a `SintService`, then inject
that service through the existing DI pillar. A `SintService` registered with
`Sint.put` is permanent by default, so it survives route pops like a GetX
`GetxService`.

```dart
import 'package:dio/dio.dart';
import 'package:sint/sint.dart';

abstract class ApiClient {
  Future<Map<String, dynamic>> getJson(String path);
}

class DioApiClient extends SintService implements ApiClient {
  DioApiClient({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: 'https://api.example.com'));

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> getJson(String path) async =>
      (await _dio.get<Map<String, dynamic>>(path)).data ?? {};

  @override
  void onClose() {
    _dio.close(force: true); // Cancel in-flight requests on Sint.reset().
    super.onClose();
  }
}

// Register once at startup, bind under the contract used by callers.
Sint.put<ApiClient>(DioApiClient());
```

Replace `GetConnect` + `GetPage` controllers by resolving the contract from
`SintController`/`SintService` constructors instead of mixing HTTP into state:

```dart
class ProfileController extends SintController {
  ProfileController(this._api);
  final ApiClient _api;

  Future<void> load() async => profile.value = await _api.getJson('/profile');
}
```

For a staged rollout (for example, keeping a legacy client behind a feature
flag), use `Bind.contract<S, I>` / `Bind.putContract<S, I>` so every caller
depends on `ApiClient`, never on the concrete transport. Swapping the
implementation then needs one registration change, not edits across modules.

## 3. Coexist with, then replace, `get_storage`

SINT does not provide a storage layer, so `get_storage` can keep running
unchanged during the first migration waves. Isolate it behind your own
contract before removing it, which keeps callers stable and makes the final
swap a single registration:

```dart
abstract class TokenStore {
  String? readToken();
  Future<void> writeToken(String token);
}

class LegacyGetStorageTokens extends SintService implements TokenStore {
  LegacyGetStorageTokens(this._box);
  final GetStorage _box; // existing get_storage dependency, untouched

  @override
  String? readToken() => _box.read<String>('token');

  @override
  Future<void> writeToken(String token) => _box.write('token', token);
}

Sint.put<TokenStore>(LegacyGetStorageTokens(GetStorage()));
```

Once the contract is in place, register a different backend (for example
`shared_preferences` or `flutter_secure_storage`) under the same type and
delete the `get_storage` dependency in a separate, easily revertable commit.
Migrating stored data, if needed, should be an explicit one-time step that
reads the old keys and writes the new ones — never an implicit fallback inside
every getter.

## 4. `GetPlatform`, `GetUtils` and manual `Worker` fields

These GetX conveniences live outside SINT's four pillars. Replace them with
standard Flutter/Dart APIs:

| GetX API | Migration |
| --- | --- |
| `GetPlatform.isWeb` / `kIsWeb` | `import 'package:flutter/foundation.dart';` and use `kIsWeb`. |
| `GetPlatform.isAndroid`, `.isIOS`, `.isMobile`, … | Use `defaultTargetPlatform` (same `foundation.dart`) with `TargetPlatform.*`; keep an explicit design on `SintApp` when the browser must not follow `defaultTargetPlatform`. |
| `GetUtils.isEmail(...)`, `.isURL(...)`, `.isNum(...)` | Use `RegExp`, `Uri.tryParse(...)`, `num.tryParse(...)` or your validation package inside a `SintService`. |

Reactive workers change more than their names. In SINT 2.3.0,
`SintController.ever`, `once`, `debounce` and `interval` return `void` — there
is no `Worker` handle to store or dispose. The controller tracks those
subscriptions and cancels them (along with pending `debounce`/`interval`
timers) in `onClose()`:

```dart
// GetX: keep a handle and dispose it manually.
// Worker _searchWorker = debounce(query, _fetch);
// @override void onClose() { _searchWorker.dispose(); super.onClose(); }

// SINT: register the worker and let the controller own its lifecycle.
class SearchController extends SintController {
  final query = ''.obs;

  @override
  void onInit() {
    super.onInit();
    debounce(query, (value) => _fetch(value)); // auto-disposed on close
  }
}
```

Keep `autoDispose` / `onClose()` overrides only for resources SINT cannot own
(HTTP clients, `StreamController`s you created, `TextEditingController`s).
`everSync` and `everAll` return a `Disposer` when you need an early unsubscribe.

## 5. Use `Sint.pop()` inside dialogs and bottom sheets

`Sint.back()` pops the **route stack**, which is too aggressive from a modal
and is reported as `sint_back_inside_modal`. `Sint.pop()` dismisses the
topmost dialog, bottom sheet or modal without navigating away:

```dart
// Before (GetX inside a dialog / bottom sheet): Get.back(result: value);
// After:
Sint.pop(value);
```

Keep `Sint.back()` only for real page navigation. After changing modal call
sites, re-run `dart run sint:audit . --fail-on-warnings --strict` to confirm
the `sint_back_inside_modal` findings are gone.

## 6. Phased rollout with SINT 2.x compatibility aliases

Migrate one bounded context at a time and rely on the `@Deprecated` aliases to
keep the app compiling between steps. They all emit deprecation warnings, so
they double as a to-do list; `[ ]` → `[x]` each module as it moves to the
preferred API:

- `Get` → `Sint` (`final Get = Sint;`)
- `GetxController` → `SintController`, `GetxService` → `SintService`
- `GetMaterialApp` / `GetCupertinoApp` → `SintMaterialApp` / `SintCupertinoApp`
  (or `SintApp`, see [`MIGRATION_DESIGN_SYSTEMS.md`](../MIGRATION_DESIGN_SYSTEMS.md))
- `GetPage` → `SintPage`, `GetBuilder` → `SintBuilder`
- `GetRouterOutlet` → `SintRouterOutlet`
- `getPages:` → `sintPages:`

A safe order for a 100+ file app:

1. Baseline: `sint:migrate --dry-run` + `sint:audit --json`, then
   `sint:migrate --apply` in its own commit.
2. Replace `GetConnect` calls with `SintService` transports and clear the
   `sint_no_get_connect` findings.
3. Replace `Get.back()` inside modals with `Sint.pop()` and clear the
   `sint_back_inside_modal` findings.
4. Remove manual `Worker` fields and hand `GetPlatform`/`GetUtils` call sites to
   Flutter/Dart APIs.
5. Swap feature flags and DI registrations module by module, resolving
   deprecation warnings until none remain.
6. Migrate the app host to `SintApp` only after its modules are stable, then
   drop `get:` and any replaced storage dependency.

Run `dart analyze`, `dart format .` and `flutter test` after every step and
compare each `sint:audit --json` report against `audit-before.json` so the
number of findings only decreases. See
[`CONTRIBUTING.md`](../CONTRIBUTING.md) for the project's local checks.
