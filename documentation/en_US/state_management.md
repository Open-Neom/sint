# State Management

- [Reactive State Manager](#reactive-state-manager)
  - [Declaring a reactive variable](#declaring-a-reactive-variable)
  - [Using values in the view](#using-values-in-the-view)
  - [Conditions to rebuild](#conditions-to-rebuild)
  - [Workers](#workers)
- [Simple State Manager (SintBuilder)](#simple-state-manager-SintBuilder)
  - [Usage](#usage)
  - [Unique IDs](#unique-ids)
- [StateMixin](#statemixin)
- [Test Roadmap](#test-roadmap)

---

SINT's **State Management** pillar provides two complementary approaches: a **Reactive State Manager** (using `.obs` and `Obx`) and a **Simple State Manager** (`SintBuilder`). Both avoid `ChangeNotifier` and `Streams` boilerplate, delivering high performance with minimal RAM consumption.

---

## Reactive State Manager

Make any variable observable by appending `.obs`:

```dart
var name = 'SINT'.obs;
```

Display it in the UI with `Obx`:

```dart
Obx(() => Text(controller.name.value));
```

`Obx` only rebuilds when the observed value actually changes. If you set `name.value = 'SINT'` again, no rebuild occurs.

### Declaring a reactive variable

Three equivalent ways:

```dart
// 1. Typed Rx
final count = RxInt(0);

// 2. Generic Rx
final count = Rx<int>(0);

// 3. .obs (preferred)
final count = 0.obs;
```

Works with any type:

```dart
final items = <String>[].obs;
final user = User(name: 'Serzen', age: 30).obs;
```

### Using values in the view

```dart
// Controller
final count1 = 0.obs;
final count2 = 0.obs;
int get sum => count1.value + count2.value;
```

```dart
// View
Obx(() => Text('${controller.count1.value}')),
Obx(() => Text('${controller.sum}')),
```

Incrementing `count1` only rebuilds widgets that depend on `count1` or `sum`. Other widgets remain untouched.

### Conditions to rebuild

```dart
list.addIf(item < limit, item);
```

### Workers

Trigger callbacks when reactive variables change:

```dart
// Called every time count changes
ever(count, (_) => print('changed: $_'));

// Called only the first time
once(count, (_) => print('first change: $_'));

// Called after user stops changing for 1 second
debounce(count, (_) => print('debounced: $_'), time: Duration(seconds: 1));

// Called at most once per second
interval(count, (_) => print('interval: $_'), time: Duration(seconds: 1));
```

Workers should be initialized in `onInit()` of your controller.

---

## Simple State Manager (SintBuilder)

For cases where you need to update multiple widgets at once without reactive streams. More economical in RAM.

### Usage

```dart
class CountController extends SintController {
  int counter = 0;
  void increment() {
    counter++;
    update(); // notifies SintBuilder widgets
  }
}
```

```dart
SintBuilder<CountController>(
  init: CountController(),
  builder: (_) => Text('${_.counter}'),
)
```

### Unique IDs

Target specific widgets:

```dart
SintBuilder<Controller>(
  id: 'text',
  builder: (_) => Text('${_.counter}'),
)
```

```dart
update(['text']); // only rebuilds widgets with id 'text'
```

---

## StateMixin

For UI state management with loading, success, empty, and error states:

```dart
class Controller extends SintController with StateMixin<User> {}
```

```dart
change(data, status: RxStatus.success());
change(null, status: RxStatus.loading());
change(null, status: RxStatus.error('Something went wrong'));
```

```dart
controller.obx(
  (state) => Text(state.name),
  onLoading: CircularProgressIndicator(),
  onEmpty: Text('No data'),
  onError: (error) => Text(error!),
)
```

---

## Test Roadmap

Tests for State Management are retained from the original GetX test suite and will be expanded in future versions:

- **Reactive performance profiling** for `.obs` rebuild frequency
- **Scoped Rx containers** that auto-dispose with navigation scopes
- **Stream interop** with Dart `Stream`/`StreamController` and platform channels
- Unit tests for `Workers` (ever, once, debounce, interval)
- Integration tests for `SintBuilder` with unique IDs
- StateMixin lifecycle tests
