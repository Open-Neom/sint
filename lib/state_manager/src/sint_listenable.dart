import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sint/core/src/domain/models/rx_interface.dart';
import 'package:sint/state_manager/src/engine/list_notifier.dart';

class SintListenable<T> extends ListNotifier implements RxInterface<T> {
  SintListenable(T val) : _value = val;

  StreamController<T>? _controller;

  StreamController<T> get subject {
    if (_controller == null) {
      _controller =
      StreamController<T>.broadcast(onCancel: addListener(_streamListener));
      _controller?.add(_value);

      ///TODO: report to controller dispose
    }
    return _controller!;
  }

  void _streamListener() {
    _controller?.add(_value);
  }

  @override
  @mustCallSuper
  void close() {
    removeListener(_streamListener);
    _controller?.close();
    dispose();
  }

  Stream<T> get stream {
    return subject.stream;
  }

  T _value;

  @override
  T get value {
    reportRead();
    return _value;
  }

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