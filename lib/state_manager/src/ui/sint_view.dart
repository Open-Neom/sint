import 'package:flutter/widgets.dart';
import 'package:sint/core/sint_core.dart';
import 'package:sint/injection/sint_injection.dart';

/// Convenience [StatelessWidget] that resolves a registered controller [T]
/// via `Sint.find<T>(tag: tag)`.
///
/// Serves as the idiomatic SINT counterpart to `GetView<T>`, eliminating
/// repeated `final controller = Sint.find<MyController>();` boilerplate
/// across modular pages.
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
}
