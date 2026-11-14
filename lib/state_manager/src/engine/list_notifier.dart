import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:sint/state_manager/src/domain/typedefs/state_typedefs.dart';
import 'package:sint/state_manager/src/engine/notifier.dart';

/// The core notification engine for Pillar S (State).
/// Maintained with original names to ensure multirepo compatibility.
class ListNotifier extends Listenable {
  static int _batchDepth = 0;
  static int _propagationDepth = 0;
  static bool _isFlushingBatch = false;
  static final List<ListNotifier> _batchedNotifiers = <ListNotifier>[];
  static final List<VoidCallback> _batchedComputed = <VoidCallback>[];

  /// Whether execution is currently inside a [batch] block.
  static bool get isBatching => _batchDepth > 0;

  /// Whether a completed [batch] or synchronous signal wave is flushing listeners.
  static bool get isFlushingBatch => _isFlushingBatch;

  /// Whether an upstream [ListNotifier] is currently dispatching notifications.
  static bool get isPropagating => _propagationDepth > 0;

  /// Internal hook for `Computed<T>` to coalesce recomputations during a wave/batch flush.
  static void enqueueBatchedComputed(VoidCallback flushCallback) {
    _batchedComputed.add(flushCallback);
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

  @pragma('vm:prefer-inline')
  void _notifyUpdate() {
    final list = _updaters;
    if (list == null || list.length <= _removedListeners) return;
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
    _updatersGroupIds?[id]?.removeListener(listener);
  }

  Disposer addListenerId(Object? key, SintStateUpdate listener) {
    if (isDisposed) {
      throw StateError('Cannot add a listener to a disposed ListNotifier.');
    }
    final groups = _updatersGroupIds ??= HashMap<Object?, ListNotifier>();
    groups[key] ??= ListNotifier();
    return groups[key]!.addListener(listener);
  }
}

class _ListenerEntry {
  _ListenerEntry(this.callback, {this.onMarkCheck});

  final SintStateUpdate callback;
  final VoidCallback? onMarkCheck;
  bool active = true;
}
