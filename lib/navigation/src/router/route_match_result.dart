
import 'package:sint/navigation/src/domain/models/route_node.dart';

/// A class representing the result of a route matching operation.
class RouteMatchResult {
  /// The route found that matches the result
  final RouteNode node;

  /// The current path of match, eg: adding 'user/:id' the match result for 'user/123' will be: 'user/123'
  final String currentPath;

  /// Route parameters eg: adding 'user/:id' the match result for 'user/123' will be: {id: 123}
  final Map<String, String> parameters;

  /// Route url parameters eg: adding 'user' the match result for 'user?foo=bar' will be: {foo: bar}
  final Map<String, String> urlParameters;

  RouteMatchResult(this.node, this.parameters, this.currentPath,
      {this.urlParameters = const {}});

  @override
  String toString() =>
      'MatchResult(node: $node, currentPath: $currentPath, parameters: $parameters, urlParameters: $urlParameters)';
}
