import 'dart:collection';
import 'package:sint/injection/src/domain/models/route_dependency.dart';

import '../../../sint.dart';

class RouterReportManager<T> {
  /// Holds a reference to `Sint.reference` when the Instance was
  /// created to manage the memory.
  final Map<T?, Set<RouteDependency>> _routesKey = {};

  /// Stores the onClose() references of instances created with `Sint.create()`
  /// using the `Sint.reference`.
  /// Experimental feature to keep the lifecycle and memory management with
  /// non-singleton instances.
  final Map<T?, HashSet<Function>> _routesByCreate = {};

  static RouterReportManager? _instance;

  RouterReportManager._();

  static RouterReportManager get instance =>
      _instance ??= RouterReportManager._();

  static void dispose() {
    _instance = null;
  }

  T? _current;

  // ignore: use_setters_to_change_properties
  void reportCurrentRoute(T newRoute) {
    _current = newRoute;
  }

  /// Links a Class instance [S] (or [tag]) to the current route.
  /// Requires usage of `SintMaterialApp`.
  /// Accepts generation-scoped references or unambiguous legacy string keys.
  void reportDependencyLinkedToRoute(Object dependencyKey) {
    if (dependencyKey is! String && dependencyKey is! RouteDependency) {
      throw ArgumentError.value(dependencyKey, 'dependencyKey');
    }
    if (_current == null) return;
    final dependency = dependencyKey is String
        ? InjectionExtension.routeDependencyForKey(dependencyKey)
        : dependencyKey as RouteDependency;
    if (dependency != null) (_routesKey[_current] ??= {}).add(dependency);
  }

  void clearRouteKeys() {
    _routesKey.clear();
    _routesByCreate.clear();
    _current = null;
  }

  void appendRouteByCreate(SintLifeCycleMixin i) {
    _routesByCreate[_current] ??= HashSet<Function>();
    // _routesByCreate[Sint.reference]!.add(i.onDelete as Function);
    _routesByCreate[_current]!.add(i.onDelete);
  }

  void reportRouteDispose(T disposed) {
    if (identical(_current, disposed)) _current = null;
    if (Sint.smartManagement != SmartManagement.onlyBuilder) {
      // Engine.instance.addPostFrameCallback((_) {
      // Future.microtask(() {
      _removeDependencyByRoute(disposed);
      // });
    }
  }

  void reportRouteWillDispose(T disposed) {
    final keysToRemove =
        _routesKey[disposed]?.toList() ?? const <RouteDependency>[];
    final created = _routesByCreate.remove(disposed);
    _releaseDependencies(keysToRemove, created, markOnly: true);
  }

  /// Clears from memory registered Instances associated with [routeName] when
  /// using `Sint.smartManagement` as [SmartManagement.full] or
  /// [SmartManagement.keepFactory]
  /// Meant for internal usage of `SintPageRoute` and `SintDialogRoute`
  void _removeDependencyByRoute(T routeName) {
    // Detach ownership before callbacks: reentrant registration belongs to a
    // new bucket and must not be removed with the route being disposed.
    final keysToRemove = _routesKey.remove(routeName);

    final created = _routesByCreate.remove(routeName);
    _releaseDependencies(keysToRemove, created);
  }

  void _releaseDependencies(
      Iterable<RouteDependency>? dependencies, Iterable<Function>? created,
      {bool markOnly = false}) {
    Object? firstError;
    StackTrace? firstStack;
    if (created != null) {
      for (final onClose in created) {
        try {
          onClose();
        } catch (error, stack) {
          firstError ??= error;
          firstStack ??= stack;
        }
      }
    }
    if (dependencies != null) {
      for (final dependency in dependencies) {
        try {
          if (markOnly) {
            dependency.markAsDirty();
          } else {
            dependency.delete();
          }
        } catch (error, stack) {
          firstError ??= error;
          firstStack ??= stack;
        }
      }
    }
    // Finish releasing unrelated resources, then preserve the original error.
    if (firstError != null) Error.throwWithStackTrace(firstError, firstStack!);
  }
}
