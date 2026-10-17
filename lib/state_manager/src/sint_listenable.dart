import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sint/core/src/domain/models/rx_interface.dart';
import 'package:sint/state_manager/src/engine/list_notifier.dart';

class SintListenable<T> extends ListNotifier implements RxInterface<T> {
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
  T get rawValue => _value;

  @protected
  set rawValue(T newValue) {
    _value = newValue;
  }

  @override
  T get value {
    reportRead();
    return _value;
  }

  /// Reads the current value without registering a reactive dependency in an
  /// enclosing `Obx` or `Computed` scope.
  T get peek => _value;

  void _notify() {
    refresh();
  }

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
