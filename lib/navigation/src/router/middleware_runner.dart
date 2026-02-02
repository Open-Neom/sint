
import 'package:flutter/cupertino.dart';
import 'package:sint/navigation/src/domain/interfaces/sint_middleware.dart';
import 'package:sint/navigation/src/domain/typedefs/navigation_typedefs.dart';
import 'package:sint/navigation/src/router/index.dart';

class MiddlewareRunner {
  MiddlewareRunner(List<SintMiddleware>? middlewares)
      : _middlewares = middlewares != null
            ? (List.of(middlewares)..sort(_compareMiddleware))
            : const [];

  final List<SintMiddleware> _middlewares;

  static int _compareMiddleware(SintMiddleware a, SintMiddleware b) =>
      a.priority.compareTo(b.priority);

  SintPage? runOnPageCalled(SintPage? page) {
    for (final middleware in _middlewares) {
      page = middleware.onPageCalled(page);
    }
    return page;
  }

  RouteSettings? runRedirect(String? route) {
    for (final middleware in _middlewares) {
      final redirectTo = middleware.redirect(route);
      if (redirectTo != null) {
        return redirectTo;
      }
    }
    return null;
  }

  List<R>? runOnBindingsStart<R>(List<R>? bindings) {
    for (final middleware in _middlewares) {
      bindings = middleware.onBindingsStart(bindings);
    }
    return bindings;
  }

  GetPageBuilder? runOnPageBuildStart(GetPageBuilder? page) {
    for (final middleware in _middlewares) {
      page = middleware.onPageBuildStart(page);
    }
    return page;
  }

  Widget runOnPageBuilt(Widget page) {
    for (final middleware in _middlewares) {
      page = middleware.onPageBuilt(page);
    }
    return page;
  }

  void runOnPageDispose() {
    for (final middleware in _middlewares) {
      middleware.onPageDispose();
    }
  }
}
