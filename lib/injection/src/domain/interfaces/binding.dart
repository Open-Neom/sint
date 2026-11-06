import 'package:sint/core/sint_core.dart';
import 'package:sint/injection/src/bind.dart';
import 'package:sint/injection/src/domain/extensions/injection_extension.dart';
import 'package:sint/injection/src/domain/interfaces/bindings_interface.dart';
import 'package:sint/injection/src/domain/typedefs/injection_typedefs.dart';

/// [Binding] should be extended when returning declarative [Bind] widgets.
///
/// When using `SintApp` or `SintMaterialApp`, all `SintPage`s and navigation
/// methods (like `Sint.to()`) have a `binding` property that takes an
/// instance of [BindingsInterface] to manage the `dependencies()` for the
/// Route you are opening.
abstract class Binding extends BindingsInterface<List<Bind>> {}

/// Imperative binding contract (`void dependencies()`), 100% drop-in
/// compatible with GetX 4 `Bindings` classes.
///
/// Works everywhere a [BindingsInterface] is accepted (`SintPage.binding`,
/// `SintPage.bindings`, `Sint.to(bindings: ...)`, and `SintApp.initialBinding`).
///
/// ```dart
/// class HomeBinding extends Bindings {
///   @override
///   void dependencies() {
///     Sint.lazyPut(() => HomeController());
///   }
/// }
/// ```
abstract class Bindings extends BindingsInterface<void> {
  @override
  void dependencies();
}

/// Inline [Bindings] adapter that avoids creating a dedicated subclass per page.
///
/// ```dart
/// SintPage(
///   name: '/counter',
///   page: () => const CounterPage(),
///   binding: BindingsBuilder(() {
///     Sint.lazyPut(() => CounterController());
///   }),
/// )
/// ```
class BindingsBuilder<T> extends Bindings {
  BindingsBuilder(this.builder);

  /// Convenience factory that registers a single eager dependency via `Sint.put`.
  factory BindingsBuilder.put(
    InstanceBuilderCallback<T> builder, {
    String? tag,
    bool permanent = false,
  }) =>
      BindingsBuilder<T>(
        () => Sint.put<T>(builder(), tag: tag, permanent: permanent),
      );

  final void Function() builder;

  @override
  void dependencies() => builder();
}
