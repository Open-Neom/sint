import 'dart:async';

import 'package:sint/core/src/domain/models/rx_computed.dart';
import 'package:sint/core/src/domain/models/rx_interface.dart';
import 'package:sint/injection/src/lifecycle.dart';
import 'package:sint/state_manager/src/domain/typedefs/state_typedefs.dart';
import 'package:sint/state_manager/src/sint_listenable.dart';

import 'list_notifier.dart';

/// A base controller class that provides state management functionality.
///
/// Extend this class to create a controller that can be used with SINT's
/// state management system. This class provides methods to update the UI
/// when the controller's state changes.
///
/// Includes reactive **workers** (`ever`, `everSync`, `once`, `debounce`,
/// `interval`), scoped **`computed`**, and **`autoDispose`** helpers that
/// automatically clean up when the controller is disposed.
///
/// Example:
/// ```dart
/// class CounterController extends SintController {
///   final count = 0.obs;
///   late final doubled = computed(() => count.value * 2);
///
///   @override
///   void onInit() {
///     super.onInit();
///     everSync(count, (val) => print('Count changed synchronously to $val'));
///     debounce(count, (val) => saveToDb(val));
///   }
///
///   void increment() => count.value++;
/// }
/// ```
abstract class SintController extends ListNotifier with SintLifeCycleMixin {

  // ─── Workers & Scoped Reactive Resources ──────────────────
  // Reactive listeners and resources with automatic lifecycle management.

  final List<StreamSubscription> _workers = [];
  final List<Disposer> _syncDisposers = [];

  /// Active timers created by [debounce] and [interval] workers.
  /// Tracked so they can be cancelled in [onClose] — otherwise a pending
  /// timer would fire its callback on an already-disposed controller.
  final List<Timer> _timers = [];

  /// Creates a memoized [Computed] signal scoped to this controller and
  /// automatically disposes its upstream subscriptions in [onClose].
  Computed<T> computed<T>(T Function() compute) {
    final signal = Computed<T>(compute);
    _syncDisposers.add(signal.dispose);
    return signal;
  }

  /// Registers [resource] (`RxInterface`, [ListNotifier], [Computed],
  /// [StreamSubscription], [Timer], or [Disposer] callback) to be
  /// automatically closed/disposed when [onClose] runs.
  D autoDispose<D>(D resource) {
    if (resource is RxInterface) {
      _syncDisposers.add(resource.close);
    } else if (resource is ListNotifier) {
      _syncDisposers.add(resource.dispose);
    } else if (resource is StreamSubscription) {
      _workers.add(resource);
    } else if (resource is Timer) {
      _timers.add(resource);
    } else if (resource is Disposer) {
      _syncDisposers.add(resource);
    } else {
      throw ArgumentError.value(
        resource,
        'resource',
        'Expected RxInterface, ListNotifier, StreamSubscription, Timer, or Disposer.',
      );
    }
    return resource;
  }

  /// Synchronous, zero-Stream worker that invokes [callback] immediately
  /// whenever [listenable] notifies (including coalesced `Sint.batch` flushes).
  /// Automatically disposes when this controller closes.
  Disposer everSync<T>(
    SintListenable<T> listenable,
    void Function(T) callback,
  ) {
    final disposer = listenable.addListener(() {
      if (!isDisposed && !listenable.isDisposed) {
        callback(listenable.peek);
      }
    });
    _syncDisposers.add(disposer);
    return () {
      disposer();
      _syncDisposers.remove(disposer);
    };
  }

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
      if (timer != null) {
        _timers.remove(timer);
        timer!.cancel();
      }
      timer = Timer(duration, () {
        _timers.remove(timer);
        callback(val);
      });
      _timers.add(timer!);
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
        late Timer timer;
        timer = Timer(duration, () {
          _timers.remove(timer);
          canCall = true;
        });
        _timers.add(timer);
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
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    for (final sub in _workers) {
      sub.cancel();
    }
    _workers.clear();
    final disposers = List<Disposer>.of(_syncDisposers);
    _syncDisposers.clear();
    for (final disposer in disposers) {
      disposer();
    }
    super.onClose();
  }
}
