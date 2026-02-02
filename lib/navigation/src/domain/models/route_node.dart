
import 'package:sint/navigation/src/domain/extensions/first_where_extension.dart';

// A class representing a node in a routing tree.
class RouteNode {
  String path;
  String originalPath;
  RouteNode? parent;
  List<RouteNode> nodeSegments = [];

  RouteNode(this.path, this.originalPath, {this.parent});

  bool get isRoot => parent == null;

  String get fullPath {
    if (isRoot) {
      return '/';
    } else {
      final parentPath = parent?.fullPath == '/' ? '' : parent?.fullPath;
      return '$parentPath/$path';
    }
  }

  bool get hasChildren => nodeSegments.isNotEmpty;

  void addChild(RouteNode child) {
    nodeSegments.add(child);
    child.parent = this;
  }

  RouteNode? findChild(String name) {
    return nodeSegments.firstWhereOrNull((node) => node.path == name);
  }

  bool matches(String name) {
    return name == path || path == '*' || path.startsWith(':');
  }

  @override
  String toString() =>
      'RouteNode(name: $path, nodeSegments: $nodeSegments, fullPath: $fullPath )';
}
