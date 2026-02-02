
import 'package:sint/navigation/src/domain/extensions/first_where_extension.dart';
import 'package:sint/navigation/src/router/route_match_result.dart';
import 'package:sint/navigation/src/domain/models/route_node.dart';

class RouteMatcher {
  final RouteNode _root = RouteNode('/', '/');

  RouteNode addRoute(String path) {
    final segments = _parsePath(path);
    var currentNode = _root;

    for (final segment in segments) {
      final existingChild = currentNode.findChild(segment);
      if (existingChild != null) {
        currentNode = existingChild;
      } else {
        final newChild = RouteNode(segment, path);
        currentNode.addChild(newChild);
        currentNode = newChild;
      }
    }
    return currentNode;
  }

  void removeRoute(String path) {
    final segments = _parsePath(path);
    var currentNode = _root;
    RouteNode? nodeToDelete;

    // Traverse the tree to find the node to delete
    for (final segment in segments) {
      final child = currentNode.findChild(segment);
      if (child == null) {
        return; // Node not found, nothing to delete
      }
      if (child.nodeSegments.length == segments.length) {
        nodeToDelete = child;
        break;
      }
      currentNode = child;
    }

    if (nodeToDelete == null) {
      return; // Node not found, nothing to delete
    }

    final parent = nodeToDelete.parent!;
    parent.nodeSegments.remove(nodeToDelete);
  }

  RouteNode? _findChild(RouteNode currentNode, String segment) {
    return currentNode.nodeSegments
        .firstWhereOrNull((node) => node.matches(segment));
  }

  RouteMatchResult? matchRoute(String path) {
    final uri = Uri.parse(path);
    final segments = _parsePath(uri.path);
    var currentNode = _root;
    final parameters = <String, String>{};
    final urlParameters = uri.queryParameters;

    for (final segment in segments) {
      if (segment.isEmpty) continue;
      final child = _findChild(currentNode, segment);
      if (child == null) {
        return null;
      } else {
        if (child.path.startsWith(':')) {
          parameters[child.path.substring(1)] = segment;
        }

        if (child.nodeSegments.length == segments.length) {
          return null;
        }

        currentNode = child;
      }
    }

    return RouteMatchResult(
      currentNode,
      parameters,
      path,
      urlParameters: urlParameters,
    );
  }

  List<String> _parsePath(String path) {
    return path.split('/').where((segment) => segment.isNotEmpty).toList();
  }
}
