import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class SintEngine {
  static WidgetsBinding get instance {
    return WidgetsFlutterBinding.ensureInitialized();
  }

  /// Schedules [callback] on the next frame when an active Flutter frame loop
  /// is running, while falling back to a microtask in headless `test()` zones
  /// (both when no binding exists and when a `TestWidgetsFlutterBinding` is
  /// idle outside `testWidgets`).
  static void schedulePostFrame(FrameCallback callback) {
    var useHeadlessMicrotask = false;
    assert(() {
      if (Zone.current[#test.declarer] != null) {
        final bindingType = BindingBase.debugBindingType();
        if (bindingType == null) {
          useHeadlessMicrotask = true;
        } else {
          final dynamic binding = WidgetsBinding.instance;
          try {
            if (binding.inTest == false) {
              useHeadlessMicrotask = true;
            }
          } on Object {
            // Custom non-test binding inside a test zone: use normal post-frame.
          }
        }
      }
      return true;
    }());
    if (useHeadlessMicrotask) {
      scheduleMicrotask(() => callback(Duration.zero));
      return;
    }
    final binding = instance;
    binding.addPostFrameCallback(callback);
    binding.ensureVisualUpdate();
  }
}
