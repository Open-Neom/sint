import 'dart:ui';

import 'package:sint/core/src/domain/errors/obx_error.dart';
import 'package:sint/state_manager/src/domain/notify_data.dart';
import 'package:sint/state_manager/src/engine/list_notifier.dart';

/// The dependency tracking singleton (The "Synapse" of SINT).
class Notifier {
  Notifier._();

  static Notifier? _instance;
  static Notifier get instance => _instance ??= Notifier._();

  NotifyData? _notifyData;

  void add(VoidCallback listener) {
    _notifyData?.disposers.add(listener);
  }

  void read(ListNotifier updaters) {
    final listener = _notifyData?.updater;
    if (listener != null && !updaters.containsListener(listener)) {
      updaters.addListener(listener);
      add(() => updaters.removeListener(listener));
    }
  }

  T append<T>(NotifyData data, T Function() builder) {
    final oldData = _notifyData;
    _notifyData = data;
    try {
      final result = builder();
      if (data.disposers.isEmpty && data.throwException) {
        throw ObxError();
      }
      return result;
    } finally {
      _notifyData = oldData;
    }
  }

}