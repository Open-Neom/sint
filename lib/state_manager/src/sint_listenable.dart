import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sint/core/src/domain/models/rx_custom.dart';
import 'package:sint/core/src/domain/models/rx_interface.dart';
import 'package:sint/state_manager/src/engine/list_notifier.dart';
import 'package:sint/state_manager/src/engine/notifier.dart';

class SintListenable<T> extends ListNotifier
    implements RxInterface<T>, ValueListenable<T> {
  SintListenable(T val) : _value = val;

  StreamController<T>? _controller;
  VoidCallback? _removeStreamListener;

  StreamController<T> get subject {
    if (_controller == null) {
      _controller = StreamController<T>.broadcast(
        onListen: () {
          if (!isDisposed) {
            _removeStreamListener ??= addListener(_streamListener);
          }
        },
        onCancel: _detachStreamListener,
      );
      if (isDisposed) _controller!.close();
    }
    return _controller!;
  }

  void _streamListener() {
    final controller = _controller;
    if (controller != null && !controller.isClosed) {
      controller.add(_value);
    }
  }

  void _detachStreamListener() {
    _removeStreamListener?.call();
    _removeStreamListener = null;
  }

  @override
  @mustCallSuper
  void close() {
    dispose();
  }

  @override
  void dispose() {
    if (isDisposed) return;
    _detachStreamListener();
    _controller?.close();
    super.dispose();
  }

  Stream<T> get stream {
    return subject.stream;
  }

  T _value;

  @protected
  @pragma('vm:prefer-inline')
  T get rawValue => _value;

  @protected
  @pragma('vm:prefer-inline')
  set rawValue(T newValue) {
    _value = newValue;
  }

  @override
  @pragma('vm:prefer-inline')
  T get value {
    reportRead();
    return _value;
  }

  /// Reads the current value without registering a reactive dependency in an
  /// enclosing `Obx` or `Computed` scope.
  @pragma('vm:prefer-inline')
  T get peek => _value;

  @pragma('vm:prefer-inline')
  void _notify() {
    refresh();
  }

  @pragma('vm:prefer-inline')
  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    _notify();
  }

  T? call([T? v]) {
    if (v != null) {
      value = v;
    }
    return value;
  }

  @override
  StreamSubscription<T> listen(
    void Function(T)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      stream.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError ?? false,
      );

  @override
  String toString() => value.toString();
}

/// Bridges any Flutter [ValueListenable] (e.g. [ValueNotifier],
/// `TextEditingController`, `Animation<double>`) directly into `Obx` and
/// `Computed` scopes, or converts it into a synchronized [Rx].
extension SintValueListenableExtension<T> on ValueListenable<T> {
  /// Reads [value] and registers this [ValueListenable] as a reactive
  /// dependency in the enclosing `Obx` or `Computed` scope.
  ///
  /// ```dart
  /// final notifier = ValueNotifier<int>(0);
  /// Obx(() => Text('${notifier.rxValue}'));
  /// ```
  T get rxValue {
    if (this is SintListenable<T>) {
      return value;
    }
    Notifier.instance.readExternal(this);
    return value;
  }

  /// Creates a synchronized [Rx] mirroring this [ValueListenable].
  /// Calling `close()` on the returned [Rx] detaches the upstream listener.
  Rx<T> toRx() {
    if (this is Rx<T>) {
      return this as Rx<T>;
    }
    return _MirroredValueListenableRx<T>(this);
  }
}

/// Bridges any Flutter [Listenable] (e.g. `ChangeNotifier`, `ScrollController`,
/// `TabController`) into an `Obx` or `Computed` scope.
extension SintListenableBridgeExtension on Listenable {
  /// Registers this [Listenable] in the enclosing `Obx` or `Computed` scope.
  void watchInObx() {
    Notifier.instance.readExternal(this);
  }
}

class _MirroredValueListenableRx<T> extends Rx<T> {
  _MirroredValueListenableRx(this._source) : super(_source.value) {
    _source.addListener(_onSourceChanged);
  }

  final ValueListenable<T> _source;

  void _onSourceChanged() {
    if (!isDisposed) {
      value = _source.value;
    }
  }

  @override
  void dispose() {
    if (!isDisposed) {
      _source.removeListener(_onSourceChanged);
    }
    super.dispose();
  }
}
