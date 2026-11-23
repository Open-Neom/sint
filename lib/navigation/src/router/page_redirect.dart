import 'package:flutter/widgets.dart';

import '../../../sint.dart';

class PageRedirect {
  SintPage? route;
  SintPage? unknownRoute;
  RouteSettings? settings;
  bool isUnknown;

  PageRedirect({
    this.route,
    this.unknownRoute,
    this.isUnknown = false,
    this.settings,
  });

  // redirect all pages that needes redirecting
  SintPageRoute<T> getPageToRoute<T>(
    SintPage rou,
    SintPage? unk,
    BuildContext context,
  ) {
    var redirectDepth = 0;
    while (needRecheck(context)) {
      // Redirect-cycle guard (1.5.0): chained redirects beyond this
      // depth indicate a middleware loop — fail loudly instead of
      // looping forever.
      if (++redirectDepth > 5) {
        throw StateError(
          'Redirect loop detected: "${settings?.name}" exceeded the '
          'maximum redirect depth (5). Check your middlewares for '
          'cyclic redirects.',
        );
      }
    }
    final r = isUnknown ? (unk ?? rou) : (route ?? rou);
    final global = context.delegate.globalMiddlewares;

    return SintPageRoute<T>(
      page: r.page,
      parameter: r.parameters,
      alignment: r.alignment,
      title: r.title,
      maintainState: r.maintainState,
      routeName: r.name,
      settings: rou,
      curve: r.curve,
      showCupertinoParallax: r.showCupertinoParallax,
      gestureWidth: r.gestureWidth,
      opaque: r.opaque,
      customTransition: r.customTransition,
      bindings: r.bindings,
      binding: r.binding,
      binds: r.binds,
      transitionDuration:
          r.transitionDuration ?? Sint.defaultTransitionDuration,
      reverseTransitionDuration:
          r.reverseTransitionDuration ?? Sint.defaultTransitionDuration,
      // performIncomeAnimation: _r.performIncomeAnimation,
      // performOutGoingAnimation: _r.performOutGoingAnimation,
      transition: r.transition,
      popGesture: r.popGesture,
      fullscreenDialog: r.fullscreenDialog,
      middlewares: MiddlewareRunner.combine(global, r.middlewares),
    );
  }

  /// check if redirect is needed
  bool needRecheck(BuildContext context) {
    if (settings == null && route != null) {
      settings = route;
    }
    final targetName = settings?.name;
    if (targetName == null || targetName.isEmpty) {
      isUnknown = true;
      return false;
    }
    final delegate = context.delegate;
    final match = delegate.matchRoute(targetName);

    // No Match found
    if (match.route == null) {
      isUnknown = true;
      return false;
    }

    isUnknown = false;

    final combinedMiddlewares = MiddlewareRunner.combine(
      delegate.globalMiddlewares,
      match.route!.middlewares,
    );

    // No middlewares found: preserve initial page unless redirected.
    if (combinedMiddlewares.isEmpty) {
      if (!identical(settings, route)) {
        route = match.route;
      }
      return false;
    }

    final runner = MiddlewareRunner(combinedMiddlewares);
    final candidate = identical(settings, route)
        ? (route ?? match.route)
        : match.route;
    route = runner.runOnPageCalled(candidate) ?? candidate;
    addPageParameter(route!);

    final newSettings = runner.runRedirect(targetName);
    if (newSettings == null) {
      return false;
    }
    settings = newSettings;
    return true;
  }

  void addPageParameter(SintPage route) {
    if (route.parameters == null) return;

    final parameters = Map<String, String?>.from(Sint.parameters);
    parameters.addEntries(route.parameters!.entries);
    // Sint.parameters = parameters;
  }
}
