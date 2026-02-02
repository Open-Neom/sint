import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:sint/state_manager/src/domain/typedefs/state_typedefs.dart';
import 'package:sint/state_manager/src/engine/notifier.dart';

/// The core notification engine for Pillar S (State).
/// Maintained with original names to ensure multirepo compatibility.
class ListNotifier extends Listenable {

  List<SintStateUpdate>? _updaters = <SintStateUpdate>[];

  @override
  Disposer addListener(SintStateUpdate listener) {
    _updaters!.add(listener);
    return () => _updaters!.remove(listener);
  }

  bool containsListener(SintStateUpdate listener) {
    return _updaters?.contains(listener) ?? false;
  }

  @override
  void removeListener(VoidCallback listener) {
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
    if (_updaters == null) return;
    // Create a fixed list to prevent "Concurrent modification" during iteration.
    final list = _updaters!.toList();
    for (var element in list) {
      element();
    }
  }

  bool get isDisposed => _updaters == null;

  int get listenersLength {
    return _updaters!.length;
  }

  @mustCallSuper
  void dispose() {
    _updaters = null;
  }

  final HashMap<Object?, ListNotifier> _updatersGroupIds = HashMap<Object?, ListNotifier>();

  void _notifyGroupUpdate(Object id) {
    if (_updatersGroupIds.containsKey(id)) {
      _updatersGroupIds[id]!._notifyUpdate();
    }
  }

  @protected
  void refreshGroup(Object id) {
    _notifyGroupUpdate(id);
  }

  void removeListenerId(Object id, VoidCallback listener) {
    if (_updatersGroupIds.containsKey(id)) {
      _updatersGroupIds[id]!.removeListener(listener);
    }
  }

  Disposer addListenerId(Object? key, SintStateUpdate listener) {
    _updatersGroupIds[key] ??= ListNotifier();
    return _updatersGroupIds[key]!.addListener(listener);
  }

}
