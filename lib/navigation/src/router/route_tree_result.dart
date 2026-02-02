import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sint/navigation/src/router/route_match_result.dart';

import 'sint_page.dart';

class RouteTreeResult {
  final SintPage? route;
  final RouteMatchResult matchResult;

  RouteTreeResult({
    required this.route,
    required this.matchResult,
  });

  @override
  String toString() {
    return 'RouteTreeResult(route: $route, matchResult: $matchResult)';
  }

  RouteTreeResult configure(String page, Object? arguments) {
    return copyWith(
        route: route?.copyWith(
      key: ValueKey(page),
      settings: RouteSettings(name: page, arguments: arguments),
      completer: Completer(),
      arguments: arguments,
    ));
  }

  RouteTreeResult copyWith({
    SintPage? route,
    RouteMatchResult? matchResult,
  }) {
    return RouteTreeResult(
      route: route ?? this.route,
      matchResult: matchResult ?? this.matchResult,
    );
  }
}
