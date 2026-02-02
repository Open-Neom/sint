
import 'package:sint/navigation/src/router/route_matcher.dart';
import 'package:sint/navigation/src/router/route_tree_result.dart';

import 'sint_page.dart';

class RouteTree {
  static final instance = RouteTree();
  final Map<String, SintPage> tree = {};
  final RouteMatcher matcher = RouteMatcher();

  void addRoute(SintPage route) {
    matcher.addRoute(route.name);
    tree[route.name] = route;
    handleChild(route);
  }

  void addRoutes(List<SintPage> routes) {
    for (var route in routes) {
      addRoute(route);
    }
  }

  void handleChild(SintPage route) {
    final children = route.children;
    for (var child in children) {
      final middlewares = List.of(route.middlewares);
      final bindings = List.of(route.bindings);
      middlewares.addAll(child.middlewares);
      bindings.addAll(child.bindings);
      child = child.copyWith(middlewares: middlewares, bindings: bindings);
      if (child.inheritParentPath) {
        child = child.copyWith(
            name: ('${route.path}/${child.path}').replaceAll(r'//', '/'));
      }
      addRoute(child);
    }
  }

  void removeRoute(SintPage route) {
    matcher.removeRoute(route.name);
    tree.remove(route.name);
  }

  void removeRoutes(List<SintPage> routes) {
    for (var route in routes) {
      removeRoute(route);
    }
  }

  RouteTreeResult? matchRoute(String path) {
    final matchResult = matcher.matchRoute(path);
    if (matchResult != null) {
      final route = tree[matchResult.node.originalPath];
      return RouteTreeResult(
        route: route,
        matchResult: matchResult,
      );
    }
    return null;
  }
}
