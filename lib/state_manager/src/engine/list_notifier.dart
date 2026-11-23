import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:sint/state_manager/src/domain/typedefs/state_typedefs.dart';
import 'package:sint/state_manager/src/engine/notifier.dart';

/// The core notification engine for Pillar S (State).
/// Maintained with original names to ensure multirepo compatibility.
class ListNotifier extends Listenable {
  static int _batchDepth = 0;
  static int _frameBatchDepth = 0;
  static int _propagationDepth = 0;
  static bool _isFlushingBatch = false;
  static bool _isFlushingFrameBatch = false;
  static bool _frameFlushScheduled = false;
  static int _frameScheduleGeneration = 0;
  static final List<ListNotifier> _batchedNotifiers = <ListNotifier>[];
  static final List<VoidCallback> _batchedComputed = <VoidCallback>[];
  static final List<ListNotifier> _frameBatchedNotifiers = <ListNotifier>[];

  /// Optional custom frame scheduler hook used by [frameBatch] (e.g. for
  /// deterministic custom clocks or headless tests). When `null`, SINT
  /// schedules a VSync transient frame callback via [SchedulerBinding] when an
  /// active Flutter frame loop is running, or falls back to a microtask in
  /// headless `test()` zones.
  static void Function(VoidCallback flush)? frameScheduler;

  /// Whether execution is currently inside a synchronous [batch] block.
  static bool get isBatching => _batchDepth > 0;

  /// Whether execution is currently inside a VSync-aligned [frameBatch] block.
  static bool get isFrameBatching => _frameBatchDepth > 0;

  /// Whether one or more [ListNotifier] updates are queued for the next frame
  /// flush via [frameBatch].
  static bool get hasPendingFrameBatch => _frameBatchedNotifiers.isNotEmpty;

  /// Whether a completed [batch] or synchronous signal wave is flushing listeners.
  static bool get isFlushingBatch => _isFlushingBatch;

  /// Whether a scheduled VSync [frameBatch] flush is currently running.
  static bool get isFlushingFrameBatch => _isFlushingFrameBatch;

  /// Whether an upstream [ListNotifier] is currently dispatching notifications.
  static bool get isPropagating => _propagationDepth > 0;

  /// Internal hook for `Computed<T>` to coalesce recomputations during a wave/batch flush.
  static void enqueueBatchedComputed(VoidCallback flushCallback) {
    _batchedComputed.add(flushCallback);
  }

  static void _scheduleFrameFlush() {
    if (_frameFlushScheduled) return;
    _frameFlushScheduled = true;
    final generation = _frameScheduleGeneration;
    void runFlush() {
      if (generation != _frameScheduleGeneration) return;
      flushFrameBatch();
    }

    final custom = frameScheduler;
    if (custom != null) {
      custom(runFlush);
      return;
    }

    var useHeadlessMicrotask = false;
    assert(() {
      final bindingType = BindingBase.debugBindingType();
      if (bindingType == null) {
        useHeadlessMicrotask = true;
      } else if (Zone.current[#test.declarer] != null) {
        try {
          final dynamic binding = SchedulerBinding.instance;
          if (binding.inTest == false) {
            useHeadlessMicrotask = true;
          }
        } on Object {
          // Custom non-test binding inside a test zone: use normal frame callback.
        }
      }
      return true;
    }());

    if (useHeadlessMicrotask) {
      scheduleMicrotask(runFlush);
      return;
    }

    try {
      final binding = SchedulerBinding.instance;
      binding.scheduleFrameCallback((_) => runFlush());
      binding.scheduleFrame();
    } on Object {
      scheduleMicrotask(runFlush);
    }
  }

  /// Runs [action] while coalescing high-frequency reactive mutations across
  /// multiple async events (e.g. 256 Hz EEG streams, DAW playheads, VR
  /// controllers, or LLM token bursts) into **at most one VSync frame flush**.
  ///
  /// All mutated notifiers are deduplicated in `O(1)` with zero heap
  /// allocations per tick and flushed inside a single glitch-free [batch] right
  /// before the next frame's build/layout/paint pass.
  static T frameBatch<T>(T Function() action) {
    _frameBatchDepth++;
    try {
      return action();
    } finally {
      _frameBatchDepth--;
      if (_frameBatchDepth == 0 && _frameBatchedNotifiers.isNotEmpty) {
        _scheduleFrameFlush();
      }
    }
  }

  /// Immediately flushes any pending [frameBatch] updates inside a single
  /// coalesced [batch] wave. Safe to call when nothing is pending.
  static void flushFrameBatch() {
    _frameFlushScheduled = false;
    if (_frameBatchedNotifiers.isEmpty) return;

    _isFlushingFrameBatch = true;
    try {
      batch(() {
        while (_frameBatchedNotifiers.isNotEmpty) {
          final count = _frameBatchedNotifiers.length;
          for (var i = 0; i < count; i++) {
            final notifier = _frameBatchedNotifiers[i];
            notifier._queuedInFrameBatch = false;
            if (!notifier.isDisposed) {
              notifier.onFrameBatchFlush();
            }
          }
          if (count == _frameBatchedNotifiers.length) {
            _frameBatchedNotifiers.clear();
          } else {
            _frameBatchedNotifiers.removeRange(0, count);
          }
        }
      });
    } finally {
      _isFlushingFrameBatch = false;
    }
  }

  /// Clears any pending [frameBatch] queue and resets [frameScheduler] (used by
  /// `Sint.reset()` between tests).
  static void resetFrameBatch() {
    _frameScheduleGeneration++;
    _frameFlushScheduled = false;
    for (final notifier in _frameBatchedNotifiers) {
      notifier._queuedInFrameBatch = false;
    }
    _frameBatchedNotifiers.clear();
    frameScheduler = null;
  }

  /// Runs [action] while coalescing synchronous [ListNotifier] notifications.
  ///
  /// Each mutated notifier inside [action] is queued at most once and its
  /// listeners are notified when the outermost [batch] completes.
  static T batch<T>(T Function() action) {
    _batchDepth++;
    try {
      return action();
    } finally {
      _batchDepth--;
      if (_batchDepth == 0 &&
          (_batchedNotifiers.isNotEmpty || _batchedComputed.isNotEmpty)) {
        _flushBatch();
      }
    }
  }

  static const int _maxBatchFlushPasses = 1024;

  static void _flushBatch() {
    if (_isFlushingBatch) return;
    _isFlushingBatch = true;
    try {
      var passes = 0;
      while (_batchedNotifiers.isNotEmpty || _batchedComputed.isNotEmpty) {
        if (++passes > _maxBatchFlushPasses) {
          throw StateError(
            'Cyclic ListNotifier.batch() flush exceeded $_maxBatchFlushPasses passes.',
          );
        }
        final notifierPassCount = _batchedNotifiers.length;
        for (var i = 0; i < notifierPassCount; i++) {
          final notifier = _batchedNotifiers[i];
          notifier._queuedInBatch = false;
          if (!notifier.isDisposed) {
            notifier._dispatchNotifications();
          }
        }
        if (notifierPassCount > 0) {
          if (notifierPassCount == _batchedNotifiers.length) {
            _batchedNotifiers.clear();
          } else {
            _batchedNotifiers.removeRange(0, notifierPassCount);
          }
        }

        if (_batchedNotifiers.isEmpty && _batchedComputed.isNotEmpty) {
          final computedPassCount = _batchedComputed.length;
          var c = 0;
          while (c < computedPassCount && _batchedNotifiers.isEmpty) {
            final nextComputed = _batchedComputed[c++];
            nextComputed();
          }
          if (c > 0) {
            if (c == _batchedComputed.length) {
              _batchedComputed.clear();
            } else {
              _batchedComputed.removeRange(0, c);
            }
          }
        }
      }
    } catch (_) {
      for (final remaining in _batchedNotifiers) {
        remaining._queuedInBatch = false;
      }
      _batchedNotifiers.clear();
      _batchedComputed.clear();
      rethrow;
    } finally {
      _isFlushingBatch = false;
    }
  }

  List<_ListenerEntry>? _updaters = <_ListenerEntry>[];
  int _notificationDepth = 0;
  int _removedListeners = 0;
  int _computedListeners = 0;
  bool _queuedInBatch = false;
  bool _queuedInFrameBatch = false;

  /// Whether this notifier has at least one non-`Computed` listener (`Obx`,
  /// `ever`, `everSync`, `SintBuilder`, or active `stream` subscriber).
  bool get hasEagerListeners => listenersLength > _computedListeners;

  @override
  Disposer addListener(SintStateUpdate listener) {
    final updaters = _updaters;
    if (updaters == null) {
      throw StateError('Cannot add a listener to a disposed ListNotifier.');
    }
    final entry = _ListenerEntry(listener);
    updaters.add(entry);
    return () => _removeEntry(entry);
  }

  /// Internal subscription entry point for `Computed<T>` via `NotifyData`.
  Disposer addComputedListener(
    SintStateUpdate listener,
    VoidCallback onMarkCheck,
  ) {
    final updaters = _updaters;
    if (updaters == null) {
      throw StateError('Cannot add a listener to a disposed ListNotifier.');
    }
    final entry = _ListenerEntry(listener, onMarkCheck: onMarkCheck);
    updaters.add(entry);
    _computedListeners++;
    return () => _removeEntry(entry);
  }

  /// Propagates a lightweight dirty-check mark to downstream `Computed<T>`
  /// dependents without invoking eager UI/worker listeners.
  @protected
  void propagateComputedCheck() {
    if (_computedListeners == 0) return;
    final list = _updaters;
    if (list == null || list.length <= _removedListeners) return;
    final length = list.length;
    for (var i = 0; i < length; i++) {
      final entry = list[i];
      if (entry.active) {
        entry.onMarkCheck?.call();
      }
    }
  }

  bool containsListener(SintStateUpdate listener) {
    final updaters = _updaters;
    if (updaters == null) return false;
    for (final entry in updaters) {
      if (entry.active && entry.callback == listener) return true;
    }
    return false;
  }

  @override
  void removeListener(VoidCallback listener) {
    final updaters = _updaters;
    if (updaters == null) return;
    for (final entry in updaters) {
      if (entry.active && entry.callback == listener) {
        _removeEntry(entry);
        return;
      }
    }
  }

  void _removeEntry(_ListenerEntry entry) {
    if (!entry.active) return;
    entry.active = false;
    if (entry.onMarkCheck != null) {
      _computedListeners--;
    }
    final updaters = _updaters;
    if (updaters == null) return;
    if (_notificationDepth == 0) {
      if (updaters.isNotEmpty && identical(updaters.last, entry)) {
        updaters.removeLast();
        if (updaters.length == _removedListeners && _removedListeners > 0) {
          updaters.clear();
          _removedListeners = 0;
        }
        return;
      }
      _removedListeners++;
      if (_removedListeners == updaters.length) {
        updaters.clear();
        _removedListeners = 0;
      } else if (_removedListeners * 2 >= updaters.length &&
          _removedListeners >= 4) {
        updaters.removeWhere((item) => !item.active);
        _removedListeners = 0;
      }
    } else {
      // Keep indexes stable until every nested notification has finished.
      _removedListeners++;
    }
  }

  @protected
  @pragma('vm:prefer-inline')
  void refresh() {
    _notifyUpdate();
  }

  @protected
  @pragma('vm:prefer-inline')
  void reportRead() {
    Notifier.instance.read(this);
  }

  @protected
  void reportAdd(VoidCallback disposer) {
    Notifier.instance.add(disposer);
  }

  /// Invoked when a VSync [frameBatch] flushes this notifier. Subclasses such
  /// as `FrameThrottledRx` may override to skip redundant dispatch when the
  /// net sub-frame delta returned to the last emitted value.
  @protected
  void onFrameBatchFlush() {
    _notifyUpdate();
  }

  @pragma('vm:prefer-inline')
  void _notifyUpdate() {
    final list = _updaters;
    if (list == null || list.length <= _removedListeners) return;
    if (_frameBatchDepth > 0) {
      if (!_queuedInFrameBatch) {
        _queuedInFrameBatch = true;
        _frameBatchedNotifiers.add(this);
      }
      return;
    }
    if (_batchDepth > 0) {
      if (!_queuedInBatch) {
        _queuedInBatch = true;
        _batchedNotifiers.add(this);
      }
      return;
    }
    _dispatchNotifications();
  }

  void _dispatchNotifications() {
    final list = _updaters;
    if (list == null || list.length <= _removedListeners) return;
    // No allocation on the notification path. Additions are deferred to the
    // next notification; removals take effect immediately without shifting
    // the indexes of callbacks still waiting to run.
    final length = list.length;
    _notificationDepth++;
    _propagationDepth++;
    try {
      for (var i = 0; i < length; i++) {
        if (_updaters == null) break;
        final entry = list[i];
        if (entry.active) {
          entry.callback();
        }
      }
    } finally {
      _propagationDepth--;
      _notificationDepth--;
      if (_notificationDepth == 0 && _removedListeners > 0) {
        final current = _updaters;
        if (current != null) {
          if (_removedListeners == current.length) {
            current.clear();
          } else {
            current.removeWhere((entry) => !entry.active);
          }
        }
        _removedListeners = 0;
      }
      if (_propagationDepth == 0 &&
          _batchDepth == 0 &&
          !_isFlushingBatch &&
          (_batchedNotifiers.isNotEmpty || _batchedComputed.isNotEmpty)) {
        _flushBatch();
      }
    }
  }

  @pragma('vm:prefer-inline')
  bool get isDisposed => _updaters == null;

  int get listenersLength {
    return (_updaters?.length ?? 0) - _removedListeners;
  }

  @mustCallSuper
  void dispose() {
    _updaters = null;
    _removedListeners = 0;
    _computedListeners = 0;
    final groups = _updatersGroupIds;
    if (groups != null) {
      for (final group in groups.values) {
        group.dispose();
      }
      groups.clear();
      _updatersGroupIds = null;
    }
  }

  /// Lazily allocated on first [addListenerId] usage; most Rx/controllers
  /// never use id-groups, so the HashMap is no longer created eagerly.
  HashMap<Object?, ListNotifier>? _updatersGroupIds;

  void _notifyGroupUpdate(Object id) {
    final group = _updatersGroupIds?[id];
    if (group != null) {
      group._notifyUpdate();
    }
  }

  @protected
  void refreshGroup(Object id) {
    _notifyGroupUpdate(id);
  }

  void removeListenerId(Object id, VoidCallback listener) {
    final groups = _updatersGroupIds;
    final group = groups?[id];
    if (group == null) return;
    group.removeListener(listener);
    if (!group.isDisposed &&
        group.listenersLength == 0 &&
        group._notificationDepth == 0) {
      groups!.remove(id);
    }
  }

  Disposer addListenerId(Object? key, SintStateUpdate listener) {
    if (isDisposed) {
      throw StateError('Cannot add a listener to a disposed ListNotifier.');
    }
    final groups = _updatersGroupIds ??= HashMap<Object?, ListNotifier>();
    final group = groups[key] ??= ListNotifier();
    final remove = group.addListener(listener);
    return () {
      remove();
      final currentGroups = _updatersGroupIds;
      if (currentGroups != null &&
          identical(currentGroups[key], group) &&
          !group.isDisposed &&
          group.listenersLength == 0 &&
          group._notificationDepth == 0) {
        currentGroups.remove(key);
      }
    };
  }
}

class _ListenerEntry {
  _ListenerEntry(this.callback, {this.onMarkCheck});

  final SintStateUpdate callback;
  final VoidCallback? onMarkCheck;
  bool active = true;
}
