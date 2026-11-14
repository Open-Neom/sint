import 'package:flutter/widgets.dart';
import 'package:sint/injection/src/domain/extensions/injection_extension.dart';
import 'package:sint/injection/src/ui/sint_scope.dart';
import 'package:sint/state_manager/src/domain/notify_data.dart';
import 'package:sint/state_manager/src/engine/notifier.dart';

class ObxReactiveElement extends StatelessElement {
  ObxReactiveElement(super.widget);

  late final NotifyData _notifyData = NotifyData(updater: getUpdate);

  void getUpdate() {
    // markNeedsBuild is idempotent and Flutter batches dirty elements
    // into the next frame naturally — no per-notification microtask needed.
    if (!_notifyData.isDisposed && mounted) {
      markNeedsBuild();
    }
  }

  @override
  Widget build() {
    if (!InjectionExtension.hasActiveScopes) {
      return Notifier.instance.append(_notifyData, super.build);
    }
    return InjectionExtension.runWithWidgetBuildScopes(
      SintScope.ancestorContainersOf(this),
      () => Notifier.instance.append(_notifyData, super.build),
    );
  }

  @override
  void unmount() {
    super.unmount();
    _notifyData.disposeAll();
  }
}
