import 'dart:async';
import 'package:flutter/foundation.dart';

/// This class is the foundation for all reactive (Rx) classes that makes SINT
/// so powerful.
/// This interface is the contract that `_RxImpl<T>` uses in all it's
/// subclass.
abstract class RxInterface<T> implements ValueListenable<T> {
  /// Close the Rx Variable
  void close();

  /// Calls `callback` with current value, when the value changes.
  StreamSubscription<T> listen(void Function(T event) onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError});
}

