
import 'package:flutter/cupertino.dart';
import 'package:sint/navigation/src/domain/interfaces/sint_middleware.dart';
import 'package:sint/navigation/src/domain/typedefs/navigation_typedefs.dart';
import 'package:sint/navigation/src/router/index.dart';

class MiddlewareRunner {
  MiddlewareRunner(List<SintMiddleware>? middlewares)
      : _middlewares = middlewares != null
            ? sortByPriority(middlewares)
            : const [];

  final List<SintMiddleware> _middlewares;

  /// Stable sort by [SintMiddleware.priority]: among equal priorities the
  /// original declaration order is preserved (Dart's List.sort is NOT
  /// stable). Shared by [MiddlewareRunner] and SintDelegate.runMiddleware
  /// so both middleware pipelines agree on ordering (1.5.0).
  static List<SintMiddleware> sortByPriority(
      List<SintMiddleware> middlewares) {
    final indexed = <MapEntry<int, SintMiddleware>>[
      for (var i = 0; i < middlewares.length; i++)
        MapEntry(i, middlewares[i]),
    ];
    indexed.sort((a, b) {
      final cmp = a.value.priority.compareTo(b.value.priority);
      return cmp != 0 ? cmp : a.key.compareTo(b.key);
    });
    return [for (final entry in indexed) entry.value];
  }

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
