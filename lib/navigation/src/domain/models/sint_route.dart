import 'package:sint/core/sint_core.dart';
import 'package:sint/injection/sint_injection.dart';
import 'package:sint/navigation/src/domain/enums/transition.dart';
import 'package:sint/navigation/src/domain/extensions/navigation_extensions.dart';
import 'package:sint/navigation/src/domain/interfaces/sint_middleware.dart';
import 'package:sint/navigation/src/domain/typedefs/navigation_typedefs.dart';
import 'package:sint/navigation/src/router/page_settings.dart';
import 'package:sint/navigation/src/router/sint_page.dart';

/// Zero-codegen, compile-time typed route descriptor for Pillar N (Navigation).
///
/// Associates a route template [path] (e.g. `'/orders/:orderId'`) with strongly
/// typed navigation arguments [TArgs] and pop result [TResult] — eliminating
/// `as` casts and `build_runner` code generation.
///
/// ```dart
/// const orderRoute = SintRoute<OrderArgs, bool>('/orders/:orderId');
///
/// // Register in SintApp / SintMaterialApp:
/// orderRoute.page(page: () => const OrderPage())
///
/// // Navigate with compile-time type checking:
/// final confirmed = await orderRoute.to(
///   pathParams: {'orderId': '42'},
///   arguments: const OrderArgs(express: true),
/// );
///
/// // Read typed arguments in controller or page:
/// final args = orderRoute.args; // OrderArgs
/// ```
class SintRoute<TArgs, TResult> {
  const SintRoute(this.path);

  /// Route path template (must start with `'/'`, may contain `:param` tokens).
  final String path;

  /// Resolves [path] by substituting [pathParams] and appending [queryParams].
  String location({
    Map<String, String>? pathParams,
    Map<String, String>? queryParams,
  }) {
    if (pathParams == null && queryParams == null) return path;
    return resolveRoutePath(
      path,
      pathParams: pathParams,
      queryParams: queryParams,
    );
  }

  /// Creates a [SintPage] configured for this typed route.
  SintPage<TResult> page({
    required SintPageBuilder page,
    String? title,
    BindingsInterface? binding,
    List<BindingsInterface> bindings = const [],
    List<Bind> binds = const [],
    List<SintMiddleware> middlewares = const [],
    List<SintPage> children = const [],
    Transition? transition,
    Duration? transitionDuration,
    bool fullscreenDialog = false,
    bool preventDuplicates = true,
  }) =>
      SintPage<TResult>(
        name: path,
        page: page,
        title: title,
        binding: binding,
        bindings: bindings,
        binds: binds,
        middlewares: middlewares,
        children: children,
        transition: transition,
        transitionDuration: transitionDuration,
        fullscreenDialog: fullscreenDialog,
        preventDuplicates: preventDuplicates,
      );

  /// Pushes this route onto the navigation stack with typed [arguments].
  Future<TResult?>? to({
    TArgs? arguments,
    String? id,
    bool preventDuplicates = true,
    Map<String, String>? pathParams,
    Map<String, String>? queryParams,
  }) =>
      Sint.toNamed<TResult>(
        path,
        arguments: arguments,
        id: id,
        preventDuplicates: preventDuplicates,
        pathParams: pathParams,
        queryParams: queryParams,
      );

  /// Replaces the active route with this typed route.
  Future<TResult?>? off({
    TArgs? arguments,
    String? id,
    Map<String, String>? pathParams,
    Map<String, String>? queryParams,
  }) =>
      Sint.offNamed<TResult>(
        path,
        arguments: arguments,
        id: id,
        pathParams: pathParams,
        queryParams: queryParams,
      );

  /// Clears previous routes (optionally until [predicate]) and pushes this typed route.
  Future<TResult?>? offAll({
    TArgs? arguments,
    String? id,
    bool Function(SintPage<dynamic>)? predicate,
    Map<String, String>? pathParams,
    Map<String, String>? queryParams,
  }) {
    if (predicate != null) {
      return Sint.offNamedUntil<TResult>(
        location(pathParams: pathParams, queryParams: queryParams),
        predicate,
        id: id,
        arguments: arguments,
      );
    }
    return Sint.offAllNamed<TResult>(
      path,
      arguments: arguments,
      id: id,
      pathParams: pathParams,
      queryParams: queryParams,
    );
  }

  /// Reads the current route's arguments cast to [TArgs].
  TArgs get args => Sint.args<TArgs>();

  /// Reads the current route's arguments if they match [TArgs], or `null`.
  TArgs? get argsOrNull {
    final current = Sint.arguments;
    return current is TArgs ? current : null;
  }
}
