import 'dart:async';

import 'package:sint/core/src/domain/models/rx_interface.dart';
import 'package:sint/injection/src/lifecycle.dart';

import 'list_notifier.dart';

/// A base controller class that provides state management functionality.
///
/// Extend this class to create a controller that can be used with SINT's
/// state management system. This class provides methods to update the UI
/// when the controller's state changes.
///
/// Includes reactive **workers** (`ever`, `once`, `debounce`, `interval`)
/// that auto-cancel when the controller is disposed.
///
/// Example:
/// ```dart
/// class CounterController extends SintController {
///   var count = 0.obs;
///
///   @override
///   void onInit() {
///     super.onInit();
///     ever(count, (val) => print('Count changed to $val'));
///     debounce(count, (val) => saveToDb(val));
///   }
///
///   void increment() => count.value++;
/// }
abstract class SintController extends ListNotifier with SintLifeCycleMixin {

  // ─── Workers ──────────────────────────────────────────────
  // Reactive listeners with automatic lifecycle management.
  // Built on top of Rx.listen() — the engine already supports it,
  // these are the ergonomic wrappers.

  final List<StreamSubscription> _workers = [];

  /// Calls [callback] every time [rx] changes.
  /// Auto-cancels on controller disposal.
  ///
  /// ```dart
  /// ever(name, (val) => print('Name changed: $val'));
  /// ```
  void ever<T>(RxInterface<T> rx, void Function(T) callback) {
    _workers.add(rx.listen(callback));
  }

  /// Calls [callback] only the **first** time [rx] changes, then cancels.
  ///
  /// ```dart
  /// once(isLoggedIn, (val) => analytics.trackFirstLogin());
  /// ```
  void once<T>(RxInterface<T> rx, void Function(T) callback) {
    late StreamSubscription<T> sub;
    sub = rx.listen((val) {
      callback(val);
      sub.cancel();
      _workers.remove(sub);
    });
    _workers.add(sub);
  }

  /// Calls [callback] after [rx] stops changing for [duration].
  /// Useful for search-as-you-type, form validation, etc.
  ///
  /// ```dart
  /// debounce(searchQuery, (q) => fetchResults(q),
  ///   duration: const Duration(milliseconds: 500));
  /// ```
  void debounce<T>(
    RxInterface<T> rx,
    void Function(T) callback, {
    Duration duration = const Duration(milliseconds: 400),
  }) {
    Timer? timer;
    _workers.add(rx.listen((val) {
      timer?.cancel();
      timer = Timer(duration, () => callback(val));
    }));
  }

  /// Calls [callback] at most once per [duration], ignoring
  /// intermediate changes. Useful for rate-limiting UI updates.
  ///
  /// ```dart
  /// interval(scrollPosition, (pos) => loadMore(pos),
  ///   duration: const Duration(seconds: 1));
  /// ```
  void interval<T>(
    RxInterface<T> rx,
    void Function(T) callback, {
    Duration duration = const Duration(seconds: 1),
  }) {
    bool canCall = true;
    _workers.add(rx.listen((val) {
      if (canCall) {
        canCall = false;
        callback(val);
        Timer(duration, () => canCall = true);
      }
    }));
  }

  // ─── End Workers ──────────────────────────────────────────

  /// Notifies listeners to update the UI.
  ///
  /// When called without parameters, it will update all ui that depend on
  /// this controller. You can also specify specific widget IDs to update only
  /// those ui.
  ///
  /// Parameters:
  /// - [ids]: Optional list of widget IDs to update. If null, updates all ui.
  /// - [condition]: If false, the update will be skipped.
  ///
  void update([List<Object>? ids, bool condition = true]) {
    if (!condition) {
      return;
    }
    if (ids == null) {
      refresh();
    } else {
      for (final id in ids) {
        refreshGroup(id);
      }
    }
  }

  @override
  void onClose() {
    for (final sub in _workers) {
      sub.cancel();
    }
    _workers.clear();
    super.onClose();
  }
}
