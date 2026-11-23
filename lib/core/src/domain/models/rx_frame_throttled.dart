import 'package:sint/state_manager/src/domain/typedefs/state_typedefs.dart';
import 'package:sint/state_manager/src/engine/list_notifier.dart';
import 'package:sint/state_manager/src/sint_listenable.dart';

/// A VSync-throttled derived reactive signal that coalesces high-frequency
/// upstream mutations (e.g. 256 Hz EEG streams, DAW playheads, VR controller
/// packets, or 100 tok/s LLM streaming buffers) into **at most one UI
/// notification per display frame**.
///
/// - Zero `StreamController` and zero `Timer` allocations.
/// - Sub-frame oscillations that return to the last emitted value before VSync
///   emit **0** notifications.
/// - Works seamlessly inside `Obx`, `ObxSelect`, `Computed`, `ever`, and
///   Flutter's `ValueListenableBuilder`.
class FrameThrottledRx<T> extends SintListenable<T> {
  FrameThrottledRx(this._source)
    : _lastEmittedValue = _source.peek,
      super(_source.peek) {
    _sourceDisposer = _source.addListener(_onSourceChanged);
  }

  final SintListenable<T> _source;
  Disposer? _sourceDisposer;
  T _lastEmittedValue;

  void _onSourceChanged() {
    if (isDisposed || _source.isDisposed) return;
    final next = _source.peek;
    if (next == rawValue) return;
    rawValue = next;
    if (listenersLength == 0) {
      _lastEmittedValue = next;
      return;
    }
    if (ListNotifier.isFlushingFrameBatch) {
      onFrameBatchFlush();
      return;
    }
    ListNotifier.frameBatch(refresh);
  }

  @override
  void onFrameBatchFlush() {
    if (isDisposed) return;
    if (rawValue == _lastEmittedValue) return;
    _lastEmittedValue = rawValue;
    super.onFrameBatchFlush();
  }

  @override
  set value(T newValue) {
    throw UnsupportedError(
      'Cannot assign to a FrameThrottledRx directly. Update the upstream Rx instead.',
    );
  }

  @override
  T? call([T? v]) {
    if (v != null) {
      throw UnsupportedError(
        'Cannot assign to a FrameThrottledRx directly. Update the upstream Rx instead.',
      );
    }
    return value;
  }

  @override
  void dispose() {
    if (isDisposed) return;
    final disposer = _sourceDisposer;
    _sourceDisposer = null;
    disposer?.call();
    super.dispose();
  }
}

/// Convenience extension to derive a VSync-throttled view from any
/// [SintListenable] (`Rx`, `Computed`, etc.).
extension FrameThrottleExtension<T> on SintListenable<T> {
  /// Returns a [FrameThrottledRx] that coalesces rapid mutations on this signal
  /// to at most one notification per VSync frame.
  ///
  /// Remember to call `dispose()` (or use `SintController.frameThrottled(rx)`
  /// for automatic `onClose()` disposal).
  FrameThrottledRx<T> throttledToFrame() => FrameThrottledRx<T>(this);
}
