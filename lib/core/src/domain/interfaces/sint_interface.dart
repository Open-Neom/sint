import 'package:flutter/foundation.dart';
import 'package:sint/core/src/domain/enums/smart_management.dart';
import 'package:sint/core/src/domain/models/rx_computed.dart';
import 'package:sint/core/src/domain/models/rx_frame_throttled.dart';
import 'package:sint/core/src/domain/typedefs/core_typedefs.dart';
import 'package:sint/state_manager/src/engine/list_notifier.dart';
import 'package:sint/state_manager/src/engine/notifier.dart';
import 'package:sint/state_manager/src/sint_listenable.dart';

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

  /// Runs [action] while coalescing high-frequency mutations across multiple
  /// events into **at most one VSync frame flush** (ideal for DAW playheads,
  /// 256 Hz EEG telemetry, VR streams, and LLM token bursts).
  T frameBatch<T>(T Function() action) => ListNotifier.frameBatch(action);

  /// Immediately flushes any updates queued via [frameBatch].
  void flushFrameBatch() => ListNotifier.flushFrameBatch();

  /// Creates a VSync-throttled [FrameThrottledRx] view over [source] that
  /// emits at most one notification per display frame.
  FrameThrottledRx<T> frameThrottled<T>(SintListenable<T> source) =>
      FrameThrottledRx<T>(source);

  /// Creates a memoized, glitch-free derived reactive value ([Computed]) that
  /// automatically tracks upstream `Rx` reads and only notifies listeners when
  /// its computed result changes (`!=`).
  ///
  /// Set [lazy] to `true` to defer recomputation while no `Obx`, worker, or
  /// listener is attached until [Computed.value] or [Computed.peek] is read.
  Computed<T> computed<T>(T Function() compute, {bool lazy = false}) =>
      Computed<T>(compute, lazy: lazy);

  /// Executes [fn] without tracking any reactive `Rx` or [Computed] reads in
  /// the enclosing `Obx`, `ObxSelect`, or [Computed] scope.
  T untrack<T>(T Function() fn) => Notifier.instance.untrack(fn);
}
