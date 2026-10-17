import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:sint/state_manager/src/domain/notify_data.dart';
import 'package:sint/state_manager/src/domain/typedefs/state_typedefs.dart';
import 'package:sint/state_manager/src/engine/list_notifier.dart';
import 'package:sint/state_manager/src/engine/notifier.dart';

class ObxReactiveElement extends StatelessElement {
  ObxReactiveElement(super.widget);

  List<Disposer>? disposers = <Disposer>[];
  Map<ListNotifier, Disposer>? _subscriptions =
      HashMap<ListNotifier, Disposer>.identity();
  late final NotifyData _notifyData = NotifyData(
    disposers: disposers!,
    updater: getUpdate,
    trackedSubscriptions: _subscriptions,
    activeSources: HashSet<ListNotifier>.identity(),
  );

  void getUpdate() {
    // markNeedsBuild is idempotent and Flutter batches dirty elements
    // into the next frame naturally — no per-notification microtask needed.
    if (_subscriptions != null && mounted) {
      markNeedsBuild();
    }
  }

  @override
  Widget build() {
    if (disposers != null && disposers!.isNotEmpty) {
      for (final disposer in disposers!) {
        disposer();
      }
      disposers!.clear();
    }
    return Notifier.instance.append(_notifyData, super.build);
  }

  @override
  void unmount() {
    super.unmount();
    final subs = _subscriptions;
    _subscriptions = null;
    if (subs != null) {
      for (final disposer in subs.values) {
        disposer();
      }
      subs.clear();
    }
    final direct = disposers;
    disposers = null;
    if (direct != null) {
      for (final disposer in direct) {
        disposer();
      }
      direct.clear();
    }
  }
}
