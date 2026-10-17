import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:sint/core/sint_core.dart';
import 'package:sint/navigation/src/domain/extensions/first_where_extension.dart';
import 'package:sint/navigation/src/domain/models/path_decoded.dart';
import 'package:sint/navigation/src/router/index.dart';
import 'package:sint/navigation/src/router/route_decoder.dart';

class RouteParser {
  /// Takes a snapshot of the supplied flat route table. Subsequent changes
  /// should use [routes], [addRoute], or [removeRoute]; changing the original
  /// list does not change this parser's table.
  RouteParser({
    required List<SintPage> routes,
  }) {
    this.routes = _RouteList(routes, () {
      _indexDirty = true;
      _patternsDirty = true;
    });
  }

  /// Mutable registered routes. Every mutation, including replacing or
  /// reordering entries without changing the length, invalidates the index.
  late final List<SintPage> routes;

  // ── Multi-level prefix route index (2.0.0) ──────────────────────────
  // Routes are bucketed by their FIRST segment rank:
  //   literal > param with pattern > simple param > wildcard.
  // Literal-first routes (rank 0) are further indexed into a multi-level
  // literal prefix trie (_LiteralTrieNode) keyed by all leading pure-literal
  // segments, while preserving exact registration order (first-wins).
  bool _indexDirty = true;
  bool _patternsDirty = true;
  final _LiteralTrieNode _literalTrie = _LiteralTrieNode();
  final List<SintPage> _patternParamRoutes = [];
  final List<SintPage> _simpleParamRoutes = [];
  final List<SintPage> _wildcardRoutes = [];
  final Map<String, String> _patternOwners = {};

  static Iterable<String> _pathSegments(String routeName) {
    final qIndex = routeName.indexOf('?');
    final hIndex = routeName.indexOf('#');
    var end = routeName.length;
    if (qIndex >= 0 && qIndex < end) end = qIndex;
    if (hIndex >= 0 && hIndex < end) end = hIndex;
    final cleanPath = end == routeName.length
        ? routeName
        : routeName.substring(0, end);
    return cleanPath.split('/').where((element) => element.isNotEmpty);
  }

  /// Rank of a route based on its first segment type.
  /// Lower rank = higher precedence.
  static int _routeRank(Iterable<String> segments) {
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
    _literalTrie.clear();
    _patternParamRoutes.clear();
    _simpleParamRoutes.clear();
    _wildcardRoutes.clear();
    for (var i = 0; i < routes.length; i++) {
      final route = routes[i];
      final segments = _pathSegments(route.name);
      switch (_routeRank(segments)) {
        case 0:
          var node = _literalTrie;
          for (final seg in segments) {
            if (seg.contains(':')) break;
            node = node.children.putIfAbsent(seg, _LiteralTrieNode.new);
          }
          node.routes.add(_IndexedRoute(i, route));
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
  }

  void _ensureIndex() {
    if (_indexDirty) {
      _rebuildIndex();
    }
  }

  void _ensurePatterns() {
    if (!_patternsDirty) return;
    _patternOwners.clear();
    for (final existing in routes) {
      _patternOwners.putIfAbsent(existing.path.regex.pattern, () => existing.name);
    }
    _patternsDirty = false;
  }

  RouteDecoder matchRoute(String name, {PageSettings? arguments}) {
    final uri = Uri.parse(name);
    arguments?.pathParams.clear();
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

    final treeBranch = <MapEntry<String, SintPage>>[];
    for (final path in cumulativePaths) {
      final matched = _findRoute(path);
      if (matched != null) {
        treeBranch.add(MapEntry(path, matched));
      }
    }

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
      final parsedParams = _parseParams(uri, lastRoute.value.path);
      if (parsedParams.isNotEmpty) {
        params.addAll(parsedParams);
      }
      // Path params are also exposed SEPARATELY from query params (1.5.0);
      // `params` keeps the legacy merged behavior (query + path).
      arguments?.pathParams.addAll(parsedParams);
      // Copy parameters, unique ValueKey, and matched name to all pages in
      // a single allocation while reusing the pre-compiled PathDecoded.
      final mappedTreeBranch = treeBranch
          .map(
            (e) => e.value.copyWith(
              key: ValueKey(e.key),
              name: e.key,
              path: e.value.path,
              parameters: {
                if (e.value.parameters != null) ...e.value.parameters!,
                ...params,
              },
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
      const <SintPage>[],
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
    for (final page in [route, ..._flattenPage(route)]) {
      // Children may share the same relative Page key under different
      // parents. Their fully qualified name identifies the right branch.
      final index = routes.indexWhere(
        (candidate) => candidate.name == page.name && candidate.key == page.key,
      );
      if (index >= 0) routes.removeAt(index);
    }
  }

  void addRoute<T>(SintPage<T> route) {
    // Flatten already visits every descendant; recursively registering its
    // output again would grow a depth-n branch to 2^(n-1) entries.
    _ensurePatterns();
    final routeList = routes as _RouteList;
    for (final page in [route, ..._flattenPage(route)]) {
      _warnIfDuplicate(page);
      routeList.addSilently(page);
      _indexDirty = true;
    }
  }

  /// Warns (without throwing, for backwards compatibility) when two
  /// registered routes compile to the same pattern — historically a
  /// silent first-wins situation.
  void _warnIfDuplicate(SintPage route) {
    _ensurePatterns();
    final pattern = route.path.regex.pattern;
    final existingName = _patternOwners[pattern];
    if (existingName != null) {
      Sint.log(
        // ignore: lines_longer_than_80_chars
        'Duplicate route "${route.name}" matches the same pattern as "$existingName" — the first registered route wins.',
        isError: true,
      );
      return;
    }
    _patternOwners[pattern] = route.name;
  }

  List<SintPage> _flattenPage(SintPage route) {
    final result = <SintPage>[];
    if (route.children.isEmpty) {
      return result;
    }

    for (final page in route.children) {
      final child = page.copyWith(
        name: page.inheritParentPath
            ? (route.name + page.name).replaceAll('//', '/')
            : page.name,
        middlewares: [...page.middlewares, ...route.middlewares],
        bindings: [
          ...page.bindings,
          ...route.bindings,
          if (route.binding != null) route.binding!,
        ],
        binds: [...page.binds, ...route.binds],
      );
      result.add(child);
      result.addAll(_flattenPage(child));
    }
    return result;
  }

  SintPage? _findRoute(String name) {
    _ensureIndex();

    // Candidate buckets in precedence order:
    // literal > param with pattern > simple param > wildcard.
    // Within a bucket, registration order is preserved (first wins).
    final segments = _pathSegments(name);

    SintPage? bestLiteralMatch;
    var bestLiteralOrder = 0x7fffffff;

    void checkNode(_LiteralTrieNode node) {
      for (final entry in node.routes) {
        if (entry.order >= bestLiteralOrder) break;
        if (entry.route.path.regex.hasMatch(name)) {
          bestLiteralOrder = entry.order;
          bestLiteralMatch = entry.route;
          break;
        }
      }
    }

    var currentNode = _literalTrie;
    checkNode(currentNode);
    for (final seg in segments) {
      final nextNode = currentNode.children[seg];
      if (nextNode == null) break;
      currentNode = nextNode;
      checkNode(currentNode);
    }

    if (bestLiteralMatch != null) {
      return bestLiteralMatch;
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

  Map<String, String> _parseParams(Uri uri, PathDecoded routePath) {
    final params = <String, String>{};
    var paramsMatch = routePath.regex.firstMatch(uri.path);
    if (paramsMatch == null) {
      return params;
    }
    for (var i = 0; i < routePath.keys.length; i++) {
      final key = routePath.keys[i];
      if (key == null) continue; // A capture inside a custom parameter pattern.
      final group = paramsMatch[i + 1];
      // Optional params (e.g. ':id?') may be absent from the URL — their
      // match group is null. Skip them instead of null-asserting.
      if (group == null) continue;
      // Path segments are decoded with decodeComponent (NOT
      // decodeQueryComponent): '+' is a literal plus in a path segment,
      // and '%2F' decodes to '/' after the segment split.
      var param = Uri.decodeComponent(group);
      params[key] = param;
    }
    return params;
  }
}

/// Owns the table so invalidation never needs an O(routes) identity scan on
/// the matching hot path. ListBase's replacement/reordering operations go
/// through []=; growing operations are overridden for non-nullable entries.
class _RouteList extends ListBase<SintPage> {
  _RouteList(List<SintPage> routes, this._onChanged)
      : _values = List<SintPage>.of(routes);

  final List<SintPage> _values;
  final void Function() _onChanged;

  @override
  int get length => _values.length;

  @override
  set length(int value) {
    if (value == _values.length) return;
    _values.length = value;
    _onChanged();
  }

  @override
  SintPage operator [](int index) => _values[index];

  @override
  void operator []=(int index, SintPage value) {
    _values[index] = value;
    _onChanged();
  }

  @override
  void add(SintPage value) {
    _values.add(value);
    _onChanged();
  }

  void addSilently(SintPage value) {
    _values.add(value);
  }

  @override
  void addAll(Iterable<SintPage> iterable) {
    // Snapshot self-iterables and complete fallible iteration before mutating.
    final values = iterable.toList();
    if (values.isEmpty) return;
    _values.addAll(values);
    _onChanged();
  }

  @override
  void insert(int index, SintPage element) {
    _values.insert(index, element);
    _onChanged();
  }

  @override
  void insertAll(int index, Iterable<SintPage> iterable) {
    final values = iterable.toList();
    _values.insertAll(index, values);
    if (values.isNotEmpty) _onChanged();
  }

  @override
  void replaceRange(int start, int end, Iterable<SintPage> replacements) {
    final values = replacements.toList();
    _values.replaceRange(start, end, values);
    _onChanged();
  }
}

class _LiteralTrieNode {
  final Map<String, _LiteralTrieNode> children = {};
  final List<_IndexedRoute> routes = [];

  void clear() {
    children.clear();
    routes.clear();
  }
}

class _IndexedRoute {
  const _IndexedRoute(this.order, this.route);

  final int order;
  final SintPage route;
}
