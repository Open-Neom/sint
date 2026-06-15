import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sint/state_manager/src/domain/notify_data.dart';
import 'package:sint/state_manager/src/domain/typedefs/state_typedefs.dart';
// import 'obx_widget.dart';
import 'package:sint/state_manager/src/engine/notifier.dart';

class ObxReactiveElement extends StatelessElement {

  ObxReactiveElement(StatelessWidget super.widget);

  List<Disposer>? disposers = <Disposer>[];

  void getUpdate() {
    if (disposers != null) {
      scheduleMicrotask(markNeedsBuild);
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
