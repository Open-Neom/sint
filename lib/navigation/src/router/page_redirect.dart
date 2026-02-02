
import 'package:flutter/cupertino.dart';

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
      SintPage rou, SintPage? unk, BuildContext context) {
    while (needRecheck(context)) {}
    final r = (isUnknown ? unk : rou)!;

    return SintPageRoute<T>(
      page: r.page,
      parameter: r.parameters,
      alignment: r.alignment,
      title: r.title,
      maintainState: r.maintainState,
      routeName: r.name,
      settings: r,
      curve: r.curve,
      showCupertinoParallax: r.showCupertinoParallax,
      gestureWidth: r.gestureWidth,
      opaque: r.opaque,
      customTransition: r.customTransition,
      bindings: r.bindings,
      binding: r.binding,
      binds: r.binds,
      transitionDuration: r.transitionDuration ?? Sint.defaultTransitionDuration,
      reverseTransitionDuration:
          r.reverseTransitionDuration ?? Sint.defaultTransitionDuration,
      // performIncomeAnimation: _r.performIncomeAnimation,
      // performOutGoingAnimation: _r.performOutGoingAnimation,
      transition: r.transition,
      popGesture: r.popGesture,
      fullscreenDialog: r.fullscreenDialog,
      middlewares: r.middlewares,
    );
  }

  /// check if redirect is needed
  bool needRecheck(BuildContext context) {
    if (settings == null && route != null) {
      settings = route;
    }
    final match = context.delegate.matchRoute(settings!.name!);

    // No Match found
    if (match.route == null) {
      isUnknown = true;
      return false;
    }

    // No middlewares found return match.
    if (match.route!.middlewares.isEmpty) {
      return false;
    }

    final runner = MiddlewareRunner(match.route!.middlewares);
    route = runner.runOnPageCalled(match.route);
    addPageParameter(route!);

    final newSettings = runner.runRedirect(settings!.name);
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
