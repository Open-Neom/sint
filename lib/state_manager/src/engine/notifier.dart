import 'dart:collection';
import 'package:flutter/foundation.dart';

import 'package:sint/core/src/domain/errors/obx_error.dart';
import 'package:sint/state_manager/src/domain/notify_data.dart';
import 'package:sint/state_manager/src/engine/list_notifier.dart';

/// The dependency tracking singleton (The "Synapse" of SINT).
class Notifier {
  Notifier._();

  static Notifier? _instance;
  static Notifier get instance => _instance ??= Notifier._();

  NotifyData? _notifyData;
  Set<Listenable>? _activeExternals;

  void add(VoidCallback listener) {
    _notifyData?.disposers.add(listener);
  }

  void read(ListNotifier updaters) {
    final data = _notifyData;
    final listener = data?.updater;
    if (data == null || listener == null) return;

    final tracked = data.trackedSubscriptions;
    final active = data.activeSources;
    if (tracked != null && active != null) {
      active.add(updaters);
      if (!tracked.containsKey(updaters)) {
        tracked[updaters] = updaters.addListener(listener);
      }
      return;
    }

    if (!updaters.containsListener(listener)) {
      add(updaters.addListener(listener));
    }
  }

  /// Tracks an external Flutter [Listenable] (e.g. [ValueNotifier],
  /// `TextEditingController`, `Animation`) inside the active `Obx` or
  /// `Computed` scope, deduplicating multiple reads within the same pass and
  /// detaching automatically when the branch becomes inactive or unmounts.
  void readExternal(Listenable listenable) {
    if (listenable is ListNotifier) {
      read(listenable);
      return;
    }
    final data = _notifyData;
    final listener = data?.updater;
    if (data == null || listener == null) return;

    final externals = _activeExternals ??= HashSet<Listenable>.identity();
    if (externals.add(listenable)) {
      listenable.addListener(listener);
      data.disposers.add(() => listenable.removeListener(listener));
    }
  }

  T append<T>(NotifyData data, T Function() builder) {
    final oldData = _notifyData;
    final oldExternals = _activeExternals;
    final active = data.activeSources;
    active?.clear();
    _notifyData = data;
    _activeExternals = null;
    try {
      final result = builder();
      final hasSubscriptions = data.disposers.isNotEmpty ||
          (active != null && active.isNotEmpty);
      if (!hasSubscriptions && data.throwException) {
        throw ObxError();
      }
      return result;
    } finally {
      final tracked = data.trackedSubscriptions;
      if (tracked != null &&
          active != null &&
          tracked.length > active.length) {
        List<ListNotifier>? stale;
        for (final source in tracked.keys) {
          if (!active.contains(source)) {
            (stale ??= <ListNotifier>[]).add(source);
          }
        }
        if (stale != null) {
          for (final source in stale) {
            tracked.remove(source)?.call();
          }
        }
      }
      active?.clear();
      _activeExternals = oldExternals;
      _notifyData = oldData;
    }
  }

  /// Executes [fn] without tracking any reactive `Rx` or [ListNotifier] reads
  /// in the enclosing `Obx`, `ObxValue`, or `Computed` scope.
  T untrack<T>(T Function() fn) {
    final oldData = _notifyData;
    final oldExternals = _activeExternals;
    _notifyData = null;
    _activeExternals = null;
    try {
      return fn();
    } finally {
      _activeExternals = oldExternals;
      _notifyData = oldData;
    }
  }
}
