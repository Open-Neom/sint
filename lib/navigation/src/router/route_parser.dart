import 'package:flutter/foundation.dart';
import 'package:sint/core/sint_core.dart';
import 'package:sint/injection/src/bind.dart';
import 'package:sint/injection/src/domain/interfaces/bindings_interface.dart';
import 'package:sint/navigation/src/domain/extensions/first_where_extension.dart';
import 'package:sint/navigation/src/domain/interfaces/sint_middleware.dart';
import 'package:sint/navigation/src/domain/models/path_decoded.dart';
import 'package:sint/navigation/src/router/index.dart';
import 'package:sint/navigation/src/router/route_decoder.dart';

class RouteParser {
  RouteParser({
    required this.routes,
  });

  final List<SintPage> routes;

  // ── Segment route index (1.5.0) ─────────────────────────────────────
  // Routes are bucketed by the type of their FIRST segment:
  //   literal > param with pattern > simple param > wildcard.
  // Matching only evaluates the regex of the buckets that can match the
  // requested path (precedence order above), instead of scanning the whole
  // flat list for every cumulative path: O(k + candidates) vs O(k × routes).
  bool _indexDirty = true;
  int _indexedRouteCount = -1;
  final Map<String, List<SintPage>> _literalIndex = {};
  final List<SintPage> _patternParamRoutes = [];
  final List<SintPage> _simpleParamRoutes = [];
  final List<SintPage> _wildcardRoutes = [];

  static const String _rootKey = '';

  /// Rank of a route based on its first segment type.
  /// Lower rank = higher precedence.
  static int _routeRank(SintPage route) {
    final segments =
        route.name.split('/').where((element) => element.isNotEmpty);
    if (segments.isEmpty) return 0; // root '/' is literal
    final first = segments.first;
    // A param anywhere in the first segment (':id', 'file.:ext') makes
    // the route non-literal — the regex builder treats any ':' as a
    // param marker, so the bucket logic must agree.
    if (!first.contains(':')) return 0; // pure literal
    if (first.startsWith(':') && first.endsWith('*')) return 3; // wildcard
    if (first.startsWith(':') && first.contains('(')) {
      return 1; // param with pattern
    }
    return 2; // simple / optional / dotted param
  }

  void _rebuildIndex() {
    _literalIndex.clear();
    _patternParamRoutes.clear();
    _simpleParamRoutes.clear();
    _wildcardRoutes.clear();
    for (final route in routes) {
      switch (_routeRank(route)) {
        case 0:
          final segments =
              route.name.split('/').where((element) => element.isNotEmpty);
          final key = segments.isEmpty ? _rootKey : segments.first;
          _literalIndex.putIfAbsent(key, () => []).add(route);
          break;
        case 1:
          _patternParamRoutes.add(route);
          break;
        case 2:
          _simpleParamRoutes.add(route);
          break;
        default:
          _wildcardRoutes.add(route);
      }
    }
    _indexDirty = false;
    _indexedRouteCount = routes.length;
  }

  void _ensureIndex() {
    // The length guard also catches external mutations that bypass
    // addRoute/removeRoute (e.g. `routes.clear()` from the delegate).
    if (_indexDirty || _indexedRouteCount != routes.length) {
      _rebuildIndex();
    }
  }

  RouteDecoder matchRoute(String name, {PageSettings? arguments}) {
    final uri = Uri.parse(name);
    final split = uri.path.split('/').where((element) => element.isNotEmpty);
    var curPath = '/';
    final cumulativePaths = <String>[
      '/',
    ];
    for (var item in split) {
      if (curPath.endsWith('/')) {
        curPath += item;
      } else {
        curPath += '/$item';
      }
      cumulativePaths.add(curPath);
    }

    final treeBranch = cumulativePaths
        .map((e) => MapEntry(e, _findRoute(e)))
        .where((element) => element.value != null)

        ///Prevent page be disposed
        .map((e) => MapEntry(e.key, e.value!.copyWith(key: ValueKey(e.key))))
        .toList();

    // ── Slug / vanity-URL fix ──────────────────────────────────────────
    // When the URL has segments beyond "/" (e.g. "/serzenmontoya") but
    // only a parent segment like "/" matched, the full URL is NOT a
    // registered route.  Return an empty tree so unknownRoute triggers
    // (which resolves vanity slugs via SlugResolverPage).
    if (treeBranch.isNotEmpty && cumulativePaths.length > 1) {
      final lastMatchedPath = treeBranch.last.key;
      final lastCumulativePath = cumulativePaths.last;
      if (lastMatchedPath != lastCumulativePath) {
        // Only a parent matched — the full URL is unknown.
        final params = Map<String, String>.from(uri.queryParameters);
        arguments?.params.clear();
        arguments?.params.addAll(params);
        return RouteDecoder([], arguments);
      }
    }

    final params = Map<String, String>.from(uri.queryParameters);
    if (treeBranch.isNotEmpty) {
      //route is found, do further parsing to get nested query params
      final lastRoute = treeBranch.last;
      final parsedParams = _parseParams(name, lastRoute.value.path);
      if (parsedParams.isNotEmpty) {
        params.addAll(parsedParams);
      }
      // Path params are also exposed SEPARATELY from query params (1.5.0);
      // `params` keeps the legacy merged behavior (query + path).
      arguments?.pathParams.clear();
      arguments?.pathParams.addAll(parsedParams);
      //copy parameters to all pages.
      final mappedTreeBranch = treeBranch
          .map(
            (e) => e.value.copyWith(
              parameters: {
                if (e.value.parameters != null) ...e.value.parameters!,
                ...params,
              },
              name: e.key,
            ),
          )
          .toList();
      arguments?.params.clear();
      arguments?.params.addAll(params);
      return RouteDecoder(
        mappedTreeBranch,
        arguments,
      );
    }

    arguments?.params.clear();
    arguments?.params.addAll(params);

    //route not found
    return RouteDecoder(
      treeBranch.map((e) => e.value).toList(),
      arguments,
    );
  }

  void addRoutes<T>(List<SintPage<T>> sintPages) {
    for (final route in sintPages) {
      addRoute(route);
    }
  }

  void removeRoutes<T>(List<SintPage<T>> sintPages) {
    for (final route in sintPages) {
      removeRoute(route);
    }
  }

  void removeRoute<T>(SintPage<T> route) {
    routes.remove(route);
    _indexDirty = true;
    for (var page in _flattenPage(route)) {
      removeRoute(page);
    }
  }

  void addRoute<T>(SintPage<T> route) {
    _warnIfDuplicate(route);
    routes.add(route);
    _indexDirty = true;

    // Add Page children.
    for (var page in _flattenPage(route)) {
      addRoute(page);
    }
  }

  /// Warns (without throwing, for backwards compatibility) when two
  /// registered routes compile to the same pattern — historically a
  /// silent first-wins situation.
  void _warnIfDuplicate(SintPage route) {
    final pattern = route.path.regex.pattern;
    for (final existing in routes) {
      if (existing.path.regex.pattern == pattern) {
        Sint.log(
          // ignore: lines_longer_than_80_chars
          'Duplicate route "${route.name}" matches the same pattern as "${existing.name}" — the first registered route wins.',
          isError: true,
        );
        return;
      }
    }
  }

  List<SintPage> _flattenPage(SintPage route) {
    final result = <SintPage>[];
    if (route.children.isEmpty) {
      return result;
    }

    final parentPath = route.name;
    for (var page in route.children) {
      // Add Parent middlewares to children
      final parentMiddlewares = [
        if (page.middlewares.isNotEmpty) ...page.middlewares,
        if (route.middlewares.isNotEmpty) ...route.middlewares
      ];

      final parentBindings = [
        if (page.binding != null) page.binding!,
        if (page.bindings.isNotEmpty) ...page.bindings,
        if (route.bindings.isNotEmpty) ...route.bindings
      ];

      final parentBinds = [
        if (page.binds.isNotEmpty) ...page.binds,
        if (route.binds.isNotEmpty) ...route.binds
      ];

      result.add(
        _addChild(
          page,
          parentPath,
          parentMiddlewares,
          parentBindings,
          parentBinds,
        ),
      );

      final children = _flattenPage(page);
      for (var child in children) {
        result.add(_addChild(
          child,
          parentPath,
          [
            ...parentMiddlewares,
            if (child.middlewares.isNotEmpty) ...child.middlewares,
          ],
          [
            ...parentBindings,
            if (child.binding != null) child.binding!,
            if (child.bindings.isNotEmpty) ...child.bindings,
          ],
          [
            ...parentBinds,
            if (child.binds.isNotEmpty) ...child.binds,
          ],
        ));
      }
    }
    return result;
  }

  /// Change the Path for a [SintPage]
  SintPage _addChild(
    SintPage origin,
    String parentPath,
    List<SintMiddleware> middlewares,
    List<BindingsInterface> bindings,
    List<Bind> binds,
  ) {
    return origin.copyWith(
      middlewares: middlewares,
      name: origin.inheritParentPath
          ? (parentPath + origin.name).replaceAll(r'//', '/')
          : origin.name,
      bindings: bindings,
      binds: binds,
      // key:
    );
  }

  SintPage? _findRoute(String name) {
    _ensureIndex();

    // Candidate buckets in precedence order:
    // literal > param with pattern > simple param > wildcard.
    // Within a bucket, registration order is preserved (first wins).
    final segments = name.split('/').where((element) => element.isNotEmpty);
    final literalKey = segments.isEmpty ? _rootKey : segments.first;

    final literalCandidates = _literalIndex[literalKey];
    if (literalCandidates != null) {
      final value = literalCandidates.firstWhereOrNull(
        (route) => route.path.regex.hasMatch(name),
      );
      if (value != null) return value;
    }

    for (final candidates in [
      _patternParamRoutes,
      _simpleParamRoutes,
      _wildcardRoutes,
    ]) {
      final value = candidates.firstWhereOrNull(
        (route) => route.path.regex.hasMatch(name),
      );
      if (value != null) return value;
    }

    return null;
  }

  Map<String, String> _parseParams(String path, PathDecoded routePath) {
    final params = <String, String>{};
    var idx = path.indexOf('?');
    final uri = Uri.tryParse(path);
    if (uri == null) return params;
    if (idx > -1) {
      params.addAll(uri.queryParameters);
    }
    var paramsMatch = routePath.regex.firstMatch(uri.path);
    if (paramsMatch == null) {
      return params;
    }
    for (var i = 0; i < routePath.keys.length; i++) {
      final group = paramsMatch[i + 1];
      // Optional params (e.g. ':id?') may be absent from the URL — their
      // match group is null. Skip them instead of null-asserting.
      if (group == null) continue;
      // Path segments are decoded with decodeComponent (NOT
      // decodeQueryComponent): '+' is a literal plus in a path segment,
      // and '%2F' decodes to '/' after the segment split.
      var param = Uri.decodeComponent(group);
      params[routePath.keys[i]!] = param;
    }
    return params;
  }
}
