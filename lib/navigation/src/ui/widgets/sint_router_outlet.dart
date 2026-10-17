import 'package:flutter/widgets.dart';
import 'package:sint/core/sint_core.dart';
import 'package:sint/navigation/src/domain/extensions/navigation_extensions.dart';
import 'package:sint/navigation/src/domain/extensions/page_arg_extension.dart';
import 'package:sint/navigation/src/router/route_decoder.dart';
import 'package:sint/navigation/src/router/sint_delegate.dart';
import 'package:sint/navigation/src/router/sint_navigator.dart';
import 'package:sint/navigation/src/router/sint_page.dart';

/// A widget that listens to a [RouterDelegate] and rebuilds its subtree
/// when the active route stack changes.
class RouterOutlet<TDelegate extends RouterDelegate<T>, T extends Object>
    extends StatefulWidget {
  final TDelegate routerDelegate;
  final Widget Function(BuildContext context) builder;

  RouterOutlet.builder({
    super.key,
    TDelegate? delegate,
    required this.builder,
  }) : routerDelegate = delegate ?? Sint.delegate<TDelegate, T>()!;

  RouterOutlet({
    Key? key,
    TDelegate? delegate,
    required Iterable<SintPage> Function(T currentNavStack) pickPages,
    required Widget Function(
      BuildContext context,
      TDelegate delegate,
      Iterable<SintPage>? page,
    ) pageBuilder,
  }) : this.builder(
          builder: (context) {
            final currentConfig = context.delegate.currentConfiguration as T?;
            final rDelegate = context.delegate as TDelegate;
            var picked =
                currentConfig == null ? null : pickPages(currentConfig);
            if (picked?.isEmpty ?? true) {
              picked = null;
            }
            return pageBuilder(context, rDelegate, picked);
          },
          delegate: delegate,
          key: key,
        );

  @override
  RouterOutletState<TDelegate, T> createState() =>
      RouterOutletState<TDelegate, T>();
}

class RouterOutletState<TDelegate extends RouterDelegate<T>, T extends Object>
    extends State<RouterOutlet<TDelegate, T>> {
  RouterDelegate? delegate;
  ChildBackButtonDispatcher? _backButtonDispatcher;

  void _listener() {
    if (mounted) {
      setState(() {});
    }
  }

  VoidCallback? disposer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    disposer?.call();
    final router = Router.of(context);
    delegate ??= router.routerDelegate;
    delegate?.addListener(_listener);
    disposer = () => delegate?.removeListener(_listener);

    _backButtonDispatcher =
        router.backButtonDispatcher?.createChildBackButtonDispatcher();
  }

  @override
  void dispose() {
    disposer?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _backButtonDispatcher?.takePriority();
    return widget.builder(context);
  }
}

/// Nested navigation outlet for declarative SINT route hierarchies
/// (`SintPage.children` and `participatesInRootNavigator`).
class SintRouterOutlet extends RouterOutlet<SintDelegate, RouteDecoder> {
  SintRouterOutlet({
    Key? key,
    String? anchorRoute,
    required String initialRoute,
    Iterable<SintPage> Function(Iterable<SintPage> afterAnchor)? filterPages,
    SintDelegate? delegate,
    String? restorationScopeId,
  }) : this.pickPages(
          restorationScopeId: restorationScopeId,
          pickPages: (config) {
            Iterable<SintPage<dynamic>> ret;
            if (anchorRoute == null) {
              final length = Uri.parse(initialRoute).pathSegments.length;
              return config.currentTreeBranch
                  .skip(length)
                  .take(length)
                  .toList();
            }
            ret = config.currentTreeBranch.pickAfterRoute(anchorRoute);
            if (filterPages != null) {
              ret = filterPages(ret);
            }
            return ret;
          },
          key: key,
          emptyPage: (delegate) =>
              delegate.matchRoute(initialRoute).route ?? delegate.notFoundRoute,
          navigatorKey: Sint.nestedKey(anchorRoute)?.navigatorKey,
          delegate: delegate,
        );

  SintRouterOutlet.pickPages({
    super.key,
    Widget Function(SintDelegate delegate)? emptyWidget,
    SintPage Function(SintDelegate delegate)? emptyPage,
    required super.pickPages,
    bool Function(Route<dynamic>, dynamic)? onPopPage,
    String? restorationScopeId,
    GlobalKey<NavigatorState>? navigatorKey,
    SintDelegate? delegate,
  }) : super(
          pageBuilder: (context, rDelegate, pages) {
            final pageRes = <SintPage?>[
              ...?pages,
              if (pages == null || pages.isEmpty) emptyPage?.call(rDelegate),
            ].whereType<SintPage>();

            if (pageRes.isNotEmpty) {
              return InheritedNavigator(
                navigatorKey: navigatorKey ??
                    Sint.rootController.rootDelegate.navigatorKey,
                child: SintNavigator(
                  restorationScopeId: restorationScopeId,
                  onPopPage: onPopPage ??
                      (route, result) {
                        final didPop = route.didPop(result);
                        if (!didPop) {
                          return false;
                        }
                        return true;
                      },
                  pages: pageRes.toList(),
                  key: navigatorKey,
                ),
              );
            }
            return (emptyWidget?.call(rDelegate) ?? const SizedBox.shrink());
          },
          delegate: delegate ?? Sint.rootController.rootDelegate,
        );

  SintRouterOutlet.builder({
    super.key,
    required super.builder,
    String? route,
    SintDelegate? routerDelegate,
  }) : super.builder(
          delegate: routerDelegate ??
              (route != null
                  ? Sint.nestedKey(route)
                  : Sint.rootController.rootDelegate),
        );
}

class InheritedNavigator extends InheritedWidget {
  const InheritedNavigator({
    super.key,
    required super.child,
    required this.navigatorKey,
  });
  final GlobalKey<NavigatorState> navigatorKey;

  static InheritedNavigator? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<InheritedNavigator>();
  }

  @override
  bool updateShouldNotify(InheritedNavigator oldWidget) {
    return oldWidget.navigatorKey != navigatorKey;
  }
}

extension NavKeyExt on BuildContext {
  GlobalKey<NavigatorState>? get parentNavigatorKey {
    return InheritedNavigator.of(this)?.navigatorKey;
  }
}

extension PagesListExt on List<SintPage> {
  /// Returns the route and all following routes after the given route.
  Iterable<SintPage> pickFromRoute(String route) {
    return skipWhile((value) => value.name != route);
  }

  /// Returns the routes after the given route.
  Iterable<SintPage> pickAfterRoute(String route) {
    if (route == '/') {
      return pickFromRoute(route).skip(1).take(1);
    }
    return pickFromRoute(route).skip(1);
  }
}

typedef NavigatorItemBuilderBuilder = Widget Function(
  BuildContext context,
  List<String> routes,
  int index,
);

class IndexedRouteBuilder<T> extends StatelessWidget {
  const IndexedRouteBuilder({
    super.key,
    required this.builder,
    required this.routes,
  });
  final List<String> routes;
  final NavigatorItemBuilderBuilder builder;

  int _getCurrentIndex(String currentLocation) {
    for (int i = 0; i < routes.length; i++) {
      if (currentLocation.startsWith(routes[i])) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return RouterListener(
      builder: (context) {
        final location = context.location;
        final index = _getCurrentIndex(location);

        return builder(context, routes, index);
      },
    );
  }
}

mixin RouterListenerMixin<T extends StatefulWidget> on State<T> {
  RouterDelegate? delegate;

  void _listener() {
    if (mounted) {
      setState(() {});
    }
  }

  VoidCallback? disposer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    disposer?.call();
    final router = Router.of(context);
    delegate ??= router.routerDelegate as SintDelegate;

    delegate?.addListener(_listener);
    disposer = () => delegate?.removeListener(_listener);
  }

  @override
  void dispose() {
    disposer?.call();
    super.dispose();
  }
}

class RouterListenerInherited extends InheritedWidget {
  const RouterListenerInherited({
    super.key,
    required super.child,
  });

  static RouterListenerInherited? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<RouterListenerInherited>();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }
}

class RouterListener extends StatefulWidget {
  const RouterListener({
    super.key,
    required this.builder,
  });
  final WidgetBuilder builder;

  @override
  State<RouterListener> createState() => RouteListenerState();
}

class RouteListenerState extends State<RouterListener>
    with RouterListenerMixin {
  @override
  Widget build(BuildContext context) {
    return RouterListenerInherited(child: Builder(builder: widget.builder));
  }
}

class BackButtonCallback extends StatefulWidget {
  const BackButtonCallback({super.key, required this.builder});
  final WidgetBuilder builder;

  @override
  State<BackButtonCallback> createState() => RouterListenerState();
}

class RouterListenerState extends State<BackButtonCallback>
    with RouterListenerMixin {
  ChildBackButtonDispatcher? backButtonDispatcher;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = Router.of(context);
    backButtonDispatcher =
        router.backButtonDispatcher?.createChildBackButtonDispatcher();
  }

  @override
  Widget build(BuildContext context) {
    backButtonDispatcher?.takePriority();
    return widget.builder(context);
  }
}

/// Legacy GetX compatibility alias for [SintRouterOutlet].
@Deprecated('Use SintRouterOutlet instead. Will be removed in SINT 3.0.0.')
typedef GetRouterOutlet = SintRouterOutlet;
