import 'package:flutter/widgets.dart';
import 'package:sint/state_manager/src/domain/notify_data.dart';
import 'package:sint/state_manager/src/domain/typedefs/state_typedefs.dart';
// import 'obx_widget.dart';
import 'package:sint/state_manager/src/engine/notifier.dart';

class ObxReactiveElement extends StatelessElement {

  ObxReactiveElement(super.widget);

  List<Disposer>? disposers = <Disposer>[];

  void getUpdate() {
    // markNeedsBuild is idempotent and Flutter batches dirty elements
    // into the next frame naturally — no per-notification microtask needed.
    if (disposers != null && mounted) {
      markNeedsBuild();
    }
  }

  @override
  Widget build() {
    return Notifier.instance.append(
        NotifyData(disposers: disposers!, updater: getUpdate), super.build);
  }

  @override
  void unmount() {
    super.unmount();
    for (final disposer in disposers!) {
      disposer();
    }
    disposers!.clear();
    disposers = null;
  }

}
