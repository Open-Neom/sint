import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

class _PureHeadlessController extends SintController {
  bool readyFired = false;

  @override
  void onReady() {
    super.onReady();
    readyFired = true;
  }
}

void main() {
  tearDown(Sint.reset);

  test(
    'SintController.onReady fires via microtask in headless test() without requiring WidgetTester',
    () async {
      final bindingBefore = BindingBase.debugBindingType();

      final ctrl = Sint.put(_PureHeadlessController());
      expect(ctrl.initialized, isTrue);
      expect(ctrl.readyFired, isFalse);
      // Never lazily initializes WidgetsFlutterBinding if none existed yet.
      expect(BindingBase.debugBindingType(), bindingBefore);

      await Future<void>.delayed(Duration.zero);
      expect(ctrl.readyFired, isTrue);
      expect(BindingBase.debugBindingType(), bindingBefore);
    },
  );
}
