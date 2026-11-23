import 'package:flutter/widgets.dart';
import 'package:sint/core/src/diagnostics/sint_diagnostics.dart';
import 'package:sint/injection/src/domain/extensions/injection_extension.dart';
import 'package:sint/injection/src/ui/sint_scope.dart';
import 'package:sint/state_manager/src/domain/notify_data.dart';
import 'package:sint/state_manager/src/engine/notifier.dart';

/// A fine-grained reactive selector widget that rebuilds **only** when the
/// value returned by [selector] changes (according to [equals], or `==` by
/// default).
///
/// Ideal for observing a single slice of a rich `Rx<Model>`, `RxMap`, or
/// high-frequency telemetry object without declaring boilerplate `Computed`
/// fields in a controller:
///
/// ```dart
/// ObxSelect<int>(
///   selector: () => controller.profile.value.unreadCount,
///   builder: (count) => Text('$count'),
/// )
/// ```
class ObxSelect<T> extends StatelessWidget {
  const ObxSelect({
    super.key,
    required this.selector,
    required this.builder,
    this.equals,
    this.debugLabel,
  });

  /// Pure projection reading one or more `Rx` / `Computed` / `.tr` sources.
  final T Function() selector;

  /// Builds the subtree using the current selected value.
  final Widget Function(T value) builder;

  /// Optional custom equality comparator (defaults to `a == b`).
  final bool Function(T previous, T next)? equals;

  /// Optional label used by `Sint.diagnostics` when live rebuild tracking is
  /// enabled in debug/profile mode.
  final String? debugLabel;

  @override
  Widget build(BuildContext context) {
    throw StateError('ObxSelect builds through _ObxSelectElement.');
  }

  @override
  StatelessElement createElement() => _ObxSelectElement<T>(this);
}

class _ObxSelectElement<T> extends StatelessElement {
  _ObxSelectElement(ObxSelect<T> super.widget);

  @override
  ObxSelect<T> get widget => super.widget as ObxSelect<T>;

  late final NotifyData _notifyData = NotifyData(
    updater: _onDependencyChanged,
    throwException: false,
  );
  bool _hasValue = false;
  late T _selectedValue;

  T _evaluateSelector() {
    if (!InjectionExtension.hasActiveScopes) {
      return Notifier.instance.append(_notifyData, widget.selector);
    }
    return InjectionExtension.runWithWidgetBuildScopes(
      SintScope.ancestorContainersOf(this),
      () => Notifier.instance.append(_notifyData, widget.selector),
    );
  }

  void _onDependencyChanged() {
    if (_notifyData.isDisposed || !mounted) return;
    final next = _evaluateSelector();
    if (_hasValue) {
      final isEqual = widget.equals != null
          ? widget.equals!(_selectedValue, next)
          : _selectedValue == next;
      if (isEqual) return;
    }
    _selectedValue = next;
    _hasValue = true;
    markNeedsBuild();
  }

  @override
  void update(StatelessWidget newWidget) {
    _hasValue = false;
    super.update(newWidget);
  }

  @override
  Widget build() {
    if (SintDiagnostics.isRebuildTrackingEnabled) {
      SintDiagnostics.instance.recordRebuild(
        widget.debugLabel ?? 'ObxSelect<$T>',
      );
    }
    if (!_hasValue) {
      _selectedValue = _evaluateSelector();
      _hasValue = true;
    }
    if (!InjectionExtension.hasActiveScopes) {
      return Notifier.instance.untrack(() => widget.builder(_selectedValue));
    }
    return InjectionExtension.runWithWidgetBuildScopes(
      SintScope.ancestorContainersOf(this),
      () => Notifier.instance.untrack(() => widget.builder(_selectedValue)),
    );
  }

  @override
  void unmount() {
    super.unmount();
    _notifyData.disposeAll();
  }
}
