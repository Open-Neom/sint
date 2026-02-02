import 'dart:async';

import 'package:sint/core/src/domain/interfaces/sint_interface.dart';

extension LoopEventsExtension on SintInterface {

  FutureOr<T> asap<T>(T Function() computation,
      {bool Function()? condition}) async {
    T val;
    if (condition == null || !condition()) {
      await Future.delayed(Duration.zero);
      val = computation();
    } else {
      val = computation();
    }
    return val;
  }
}
