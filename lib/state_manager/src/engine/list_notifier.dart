import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:sint/state_manager/src/domain/typedefs/state_typedefs.dart';
import 'package:sint/state_manager/src/engine/notifier.dart';

/// The core notification engine for Pillar S (State).
/// Maintained with original names to ensure multirepo compatibility.
class ListNotifier extends Listenable {
  static int _batchDepth = 0;
  static bool _isFlushingBatch = false;
  static final List<ListNotifier> _batchedNotifiers = <ListNotifier>[];
  static final List<VoidCallback> _batchedComputed = <VoidCallback>[];

  /// Whether execution is currently inside a [batch] block.
  static bool get isBatching => _batchDepth > 0;

  /// Whether a completed [batch] block is currently flushing queued listeners.
  static bool get isFlushingBatch => _isFlushingBatch;

  /// Internal hook for `Computed<T>` to coalesce recomputations during a batch flush.
  @protected
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

  static void _flushBatch() {
    if (_isFlushingBatch) return;
    _isFlushingBatch = true;
    try {
      while (_batchedNotifiers.isNotEmpty || _batchedComputed.isNotEmpty) {
        var i = 0;
        while (i < _batchedNotifiers.length) {
          final notifier = _batchedNotifiers[i++];
          notifier._queuedInBatch = false;
          if (!notifier.isDisposed) {
            notifier._dispatchNotifications();
          }
        }
        _batchedNotifiers.clear();

        var c = 0;
        while (c < _batchedComputed.length && _batchedNotifiers.isEmpty) {
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
    } finally {
      _isFlushingBatch = false;
    }
  }

  List<_ListenerEntry>? _updaters = <_ListenerEntry>[];
  int _notificationDepth = 0;
  int _removedListeners = 0;
  bool _queuedInBatch = false;

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
    final updaters = _updaters;
    if (updaters == null) return;
    if (_notificationDepth == 0) {
      updaters.remove(entry);
    } else {
      // Keep indexes stable until every nested notification has finished.
      _removedListeners++;
    }
  }

  @protected
  void refresh() {
    _notifyUpdate();
  }

  @protected
  void reportRead() {
    Notifier.instance.read(this);
  }

  @protected
  void reportAdd(VoidCallback disposer) {
    Notifier.instance.add(disposer);
  }

  void _notifyUpdate() {
    final list = _updaters;
    if (list == null || list.isEmpty) return;
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
    if (list == null || list.isEmpty) return;
    // No allocation on the notification path. Additions are deferred to the
    // next notification; removals take effect immediately without shifting
    // the indexes of callbacks still waiting to run.
    final length = list.length;
    _notificationDepth++;
    try {
      for (var i = 0; i < length && !isDisposed; i++) {
        final entry = list[i];
        if (entry.active) {
          entry.callback();
        }
      }
    } finally {
      _notificationDepth--;
      if (_notificationDepth == 0 && _removedListeners > 0) {
        _updaters?.removeWhere((entry) => !entry.active);
        _removedListeners = 0;
      }
    }
  }

  bool get isDisposed => _updaters == null;

  int get listenersLength {
    return (_updaters?.length ?? 0) - _removedListeners;
  }

  @mustCallSuper
  void dispose() {
    _updaters = null;
    _removedListeners = 0;
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
  _ListenerEntry(this.callback);

  final SintStateUpdate callback;
  bool active = true;
}
