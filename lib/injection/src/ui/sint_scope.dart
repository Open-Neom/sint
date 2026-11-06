import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sint/core/sint_core.dart';
import 'package:sint/injection/src/domain/extensions/injection_extension.dart';

/// Scopes dependency [overrides] to a widget subtree or test block without
/// mutating SINT's global singleton registry.
///
/// Inspired by Riverpod's `ProviderScope(overrides: ...)` while preserving
/// SINT's context-free `Sint.find<T>()` ergonomics:
/// - Inside a mounted [SintScope] (including nested scopes), `Sint.find<T>()`
///   and `SintView<T>` automatically resolve the innermost override.
/// - When [SintScope] unmounts, any `SintController` / `SintService` instances
///   created within its overrides automatically receive `onClose()`.
/// - For side-by-side sibling scopes in the same frame, use
///   `SintScope.find<T>(context)`.
/// - For headless unit tests without widgets, use [SintScope.run].
///
/// ```dart
/// await tester.pumpWidget(
///   SintScope(
///     overrides: [
///       SintOverride.value<AuthService>(FakeAuthService()),
///     ],
///     child: const MyApp(),
///   ),
/// );
/// ```
class SintScope extends StatefulWidget {
  const SintScope({
    super.key,
    required this.overrides,
    required this.child,
  });

  final List<SintOverride<dynamic>> overrides;
  final Widget child;

  /// Runs [body] with temporary scoped [overrides] and disposes any scoped
  /// lifecycle instances upon completion.
  static FutureOr<R> run<R>({
    required List<SintOverride<dynamic>> overrides,
    required FutureOr<R> Function() body,
  }) =>
      InjectionExtension.runScoped<R>(overrides: overrides, body: body);

  /// Resolves [T] from the nearest ancestor [SintScope] in [context], falling
  /// back to the global container when not overridden in an ancestor scope.
  static T find<T>(BuildContext context, {String? tag}) {
    if (context is Element) {
      _InheritedSintScope? inherited = context
          .getElementForInheritedWidgetOfExactType<_InheritedSintScope>()
          ?.widget as _InheritedSintScope?;
      while (inherited != null) {
        final match = InjectionExtension.findInScope<T>(
          inherited.container,
          tag: tag,
        );
        if (match != null) return match;
        final parentElement = inherited.parentContext;
        inherited = parentElement
            ?.getElementForInheritedWidgetOfExactType<_InheritedSintScope>()
            ?.widget as _InheritedSintScope?;
      }
      return InjectionExtension.findGlobal<T>(tag: tag);
    }
    return Sint.find<T>(tag: tag);
  }

  @override
  State<SintScope> createState() => _SintScopeState();
}

class _SintScopeState extends State<SintScope> {
  late SintScopeContainer _container;

  @override
  void initState() {
    super.initState();
    _container = SintScopeContainer(widget.overrides);
    InjectionExtension.pushMountedScope(_container);
  }

  @override
  void dispose() {
    InjectionExtension.popMountedScope(_container);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedSintScope(
      container: _container,
      parentContext: context,
      child: widget.child,
    );
  }
}

class _InheritedSintScope extends InheritedWidget {
  const _InheritedSintScope({
    required this.container,
    required this.parentContext,
    required super.child,
  });

  final SintScopeContainer container;
  final BuildContext? parentContext;

  @override
  bool updateShouldNotify(covariant _InheritedSintScope oldWidget) =>
      !identical(oldWidget.container, container);
}
