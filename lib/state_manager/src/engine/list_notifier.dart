import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:sint/state_manager/src/domain/typedefs/state_typedefs.dart';
import 'package:sint/state_manager/src/engine/notifier.dart';

/// The core notification engine for Pillar S (State).
/// Maintained with original names to ensure multirepo compatibility.
class ListNotifier extends Listenable {

  List<SintStateUpdate>? _updaters = <SintStateUpdate>[];

  /// Mutation counter used by [_notifyUpdate] to detect reentrant
  /// add/remove during iteration without paying a defensive copy
  /// on every notification.
  int _version = 0;

  @override
  Disposer addListener(SintStateUpdate listener) {
    _version++;
    _updaters!.add(listener);
    return () {
      _version++;
      _updaters!.remove(listener);
    };
  }

  bool containsListener(SintStateUpdate listener) {
    return _updaters?.contains(listener) ?? false;
  }

  @override
  void removeListener(VoidCallback listener) {
    _version++;
    _updaters!.remove(listener);
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
    // Fast path: iterate directly by index, no per-notification copy.
    // If a listener mutates the list reentrantly (version change),
    // fall back to a defensive copy for the remaining listeners.
    final version = _version;
    final length = list.length;
    for (var i = 0; i < length; i++) {
      if (_version != version) {
        final rest = list.sublist(i);
        for (final element in rest) {
          element();
        }
        return;
      }
      list[i]();
    }
  }

  bool get isDisposed => _updaters == null;

  int get listenersLength {
    return _updaters!.length;
  }

  @mustCallSuper
  void dispose() {
    _updaters = null;
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
    final groups = _updatersGroupIds ??= HashMap<Object?, ListNotifier>();
    groups[key] ??= ListNotifier();
    return groups[key]!.addListener(listener);
  }

}
