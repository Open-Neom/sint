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

  /// Fast `O(1)` pointer check indicating whether an `Obx`, `ObxValue`, or
  /// `Computed` scope is actively tracking reactive reads.
  @pragma('vm:prefer-inline')
  bool get isTracking => _notifyData != null;

  void add(VoidCallback listener) {
    _notifyData?.disposers.add(listener);
  }

  @pragma('vm:prefer-inline')
  void read(ListNotifier updaters) {
    _notifyData?.trackListNotifier(updaters);
  }

  /// Tracks an external Flutter [Listenable] (e.g. [ValueNotifier],
  /// `TextEditingController`, `Animation`) inside the active `Obx` or
  /// `Computed` scope, reusing active listeners across rebuilds and detaching
  /// automatically when the branch becomes inactive or unmounts.
  void readExternal(Listenable listenable) {
    if (listenable is ListNotifier) {
      _notifyData?.trackListNotifier(listenable);
      return;
    }
    _notifyData?.trackExternal(listenable);
  }

  T append<T>(NotifyData data, T Function() builder) {
    final oldData = _notifyData;
    data.beginPass();
    _notifyData = data;
    try {
      final result = builder();
      if (!data.hasActiveSubscriptions && data.throwException) {
        throw ObxError();
      }
      return result;
    } finally {
      data.endPass();
      _notifyData = oldData;
    }
  }

  /// Executes [fn] without tracking any reactive `Rx` or [ListNotifier] reads
  /// in the enclosing `Obx`, `ObxValue`, or `Computed` scope.
  T untrack<T>(T Function() fn) {
    final oldData = _notifyData;
    _notifyData = null;
    try {
      return fn();
    } finally {
      _notifyData = oldData;
    }
  }
}
