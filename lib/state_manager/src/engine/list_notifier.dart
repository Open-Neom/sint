import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:sint/state_manager/src/domain/typedefs/state_typedefs.dart';
import 'package:sint/state_manager/src/engine/notifier.dart';

/// The core notification engine for Pillar S (State).
/// Maintained with original names to ensure multirepo compatibility.
class ListNotifier extends Listenable {
  List<_ListenerEntry>? _updaters = <_ListenerEntry>[];
  int _notificationDepth = 0;
  int _removedListeners = 0;

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
