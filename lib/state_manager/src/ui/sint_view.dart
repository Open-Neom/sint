import 'package:flutter/widgets.dart';
import 'package:sint/core/sint_core.dart';
import 'package:sint/injection/sint_injection.dart';

/// Convenience [StatelessWidget] that resolves a registered controller [T]
/// via `Sint.find<T>(tag: tag)`.
///
/// Serves as the idiomatic SINT counterpart to `GetView<T>`, eliminating
/// repeated `final controller = Sint.find<MyController>();` boilerplate
/// across modular pages. Automatically honors ancestor [SintScope] overrides
/// (including side-by-side sibling scopes) with zero cost when no scopes are
/// active.
///
/// ```dart
/// class CounterPage extends SintView<CounterController> {
///   const CounterPage({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return Obx(() => Text('${controller.count.value}'));
///   }
/// }
/// ```
abstract class SintView<T> extends StatelessWidget {
  const SintView({super.key});

  /// Optional registration tag used when looking up [controller].
  String? get tag => null;

  /// Resolves the active [T] instance from SINT's dependency container.
  T get controller => Sint.find<T>(tag: tag);

  @override
  StatelessElement createElement() => _SintViewElement<T>(this);
}

class _SintViewElement<T> extends StatelessElement {
  _SintViewElement(SintView<T> super.widget);

  @override
  Widget build() {
    if (!InjectionExtension.hasActiveScopes) {
      return super.build();
    }
    return InjectionExtension.runWithWidgetBuildScopes(
      SintScope.ancestorContainersOf(this),
      super.build,
    );
  }
}
