import 'package:flutter/foundation.dart';
import 'package:sint/core/src/domain/enums/smart_management.dart';
import 'package:sint/core/src/domain/models/rx_computed.dart';
import 'package:sint/core/src/domain/typedefs/core_typedefs.dart';
import 'package:sint/state_manager/src/engine/list_notifier.dart';
import 'package:sint/state_manager/src/engine/notifier.dart';

import '../../utils/log.dart';

/// SintInterface allows any auxiliary package to be merged into the "SINT"
/// class through extensions
abstract class SintInterface {
  SmartManagement smartManagement = SmartManagement.full;
  bool isLogEnable = kDebugMode;
  LogWriterCallback log = defaultLogWriterCallback;

  /// Runs [action] while coalescing synchronous reactive notifications so
  /// downstream listeners and [Computed] values fire at most once when the
  /// outermost batch completes.
  T batch<T>(T Function() action) => ListNotifier.batch(action);

  /// Creates a memoized derived reactive value ([Computed]) that automatically
  /// tracks upstream `Rx` reads and only notifies listeners when its computed
  /// result changes (`!=`).
  Computed<T> computed<T>(T Function() compute) => Computed<T>(compute);

  /// Executes [fn] without tracking any reactive `Rx` or [Computed] reads in
  /// the enclosing `Obx`, `ObxValue`, or [Computed] scope.
  T untrack<T>(T Function() fn) => Notifier.instance.untrack(fn);
}
