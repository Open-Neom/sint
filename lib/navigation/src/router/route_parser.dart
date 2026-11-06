import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:sint/core/sint_core.dart';
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

  // ── Multi-level prefix route index (2.0.0+) ─────────────────────────
  // Routes are bucketed by their FIRST segment rank:
  //   literal > param with pattern > simple param > wildcard.
  // Literal-first routes (rank 0) are further indexed into a multi-level
  // literal prefix trie (_LiteralTrieNode) keyed by all leading pure-literal
  // segments, while preserving exact registration order (first-wins).
  bool _indexDirty = true;
  bool _patternsDirty = true;
  final _LiteralTrieNode _literalTrie = _LiteralTrieNode();
  final List<_IndexedRoute> _patternParamRoutes = [];
  final List<_IndexedRoute> _simpleParamRoutes = [];
  final List<_IndexedRoute> _wildcardRoutes = [];
  final Map<String, String> _patternOwners = {};

  static List<String> _extractSegments(String routeOrPath, {bool stripQuery = false}) {
    var end = routeOrPath.length;
    if (stripQuery) {
      final qIndex = routeOrPath.indexOf('?');
      final hIndex = routeOrPath.indexOf('#');
      if (qIndex >= 0 && qIndex < end) end = qIndex;
      if (hIndex >= 0 && hIndex < end) end = hIndex;
    }
    if (end == 0 || (end == 1 && routeOrPath.codeUnitAt(0) == 0x2F)) {
      return const <String>[];
    }
    final result = <String>[];
    var start = 0;
    while (start < end) {
      while (start < end && routeOrPath.codeUnitAt(start) == 0x2F) {
        start++;
      }
      if (start >= end) break;
      var slash = routeOrPath.indexOf('/', start);
      if (slash < 0 || slash > end) slash = end;
      result.add(routeOrPath.substring(start, slash));
      start = slash + 1;
    }
    return result;
  }

  /// Rank of a single path segment.
  /// Lower rank = higher precedence:
  /// 0 = pure literal, 1 = param with pattern, 2 = simple param, 3 = wildcard.
  static int _segmentRank(String segment) {
    // A param anywhere in the segment (':id', 'file.:ext') makes it
    // non-literal — the regex builder treats any ':' as a param marker,
    // so the bucket logic must agree.
    if (!segment.contains(':')) return 0;
    if (segment.startsWith(':') && segment.endsWith('*')) return 3;
    if (segment.startsWith(':') && segment.contains('(')) return 1;
    return 2;
  }

  /// Rank of a route based on its first segment type.
  /// Lower rank = higher precedence.
  static int _routeRank(List<String> segments) {
    if (segments.isEmpty) return 0; // root '/' is literal
    return _segmentRank(segments.first);
  }

  static _IndexedRoute _buildIndexedRoute(
    int order,
    SintPage route,
    List<String> segments, {
    required int tailRank,
    required int literalCount,
  }) {
    final isPureLiteral = route.path.keys.isEmpty;
    final String? exactPath = isPureLiteral
        ? (segments.isEmpty ? '/' : '/${segments.join('/')}')
        : null;
    final name = route.name;
    final bool hasFixedSegmentCount = isPureLiteral ||
        (!name.contains('?') && !name.contains('*') && !name.contains('('));
    return _IndexedRoute(
      order,
      route,
      tailRank: tailRank,
      literalCount: literalCount,
      exactPath: exactPath,
      exactSegmentCount: hasFixedSegmentCount ? segments.length : null,
    );
  }

  void _rebuildIndex() {
    _literalTrie.clear();
    _patternParamRoutes.clear();
    _simpleParamRoutes.clear();
    _wildcardRoutes.clear();
    for (var i = 0; i < routes.length; i++) {
      final route = routes[i];
      final segments = _extractSegments(route.name, stripQuery: true);
      switch (_routeRank(segments)) {
        case 0:
          var node = _literalTrie;
          var reachedParam = false;
          var tailRank = 0;
          var literalCount = 0;
          for (final seg in segments) {
            if (!reachedParam && seg.contains(':')) {
              reachedParam = true;
              tailRank = _segmentRank(seg);
            }
            if (!seg.contains(':')) {
              literalCount++;
              if (!reachedParam) {
                node = node.children.putIfAbsent(seg, _LiteralTrieNode.new);
              }
            }
          }
          node.routes.add(
            _buildIndexedRoute(
              i,
              route,
              segments,
              tailRank: tailRank,
              literalCount: literalCount,
            ),
          );
          break;
        case 1:
          _patternParamRoutes.add(
            _buildIndexedRoute(
              i,
              route,
              segments,
              tailRank: 1,
              literalCount: 0,
            ),
          );
          break;
        case 2:
          _simpleParamRoutes.add(
            _buildIndexedRoute(
              i,
              route,
              segments,
              tailRank: 2,
              literalCount: 0,
            ),
          );
          break;
        default:
          _wildcardRoutes.add(
            _buildIndexedRoute(
              i,
              route,
              segments,
              tailRank: 3,
              literalCount: 0,
            ),
          );
      }
    }
    _literalTrie.sortRoutesRecursively();
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
    _ensureIndex();
    arguments?.pathParams.clear();

    final String cleanPath;
    final Map<String, String> rawQueryParams;
    if (!name.contains('?') && !name.contains('#') && !name.contains('://')) {
      cleanPath = name;
      rawQueryParams = const <String, String>{};
    } else {
      final uri = Uri.parse(name);
      cleanPath = uri.path;
      rawQueryParams = uri.queryParameters;
    }

    final segments = _extractSegments(cleanPath);
    final totalSegments = segments.length;

    // Walk the literal trie once along the input segments (`O(D)` total).
    final nodeStack = List<_LiteralTrieNode?>.filled(totalSegments + 1, null);
    nodeStack[0] = _literalTrie;
    for (var i = 0; i < totalSegments; i++) {
      final prev = nodeStack[i];
      if (prev == null) break;
      nodeStack[i + 1] = prev.children[segments[i]];
    }

    List<String?>? cachedPrefixPaths;
    String pathAtDepth(int depth) {
      if (depth == 0) return '/';
      if (depth == totalSegments &&
          cleanPath.startsWith('/') &&
          !cleanPath.endsWith('/') &&
          !cleanPath.contains('//')) {
        return cleanPath;
      }
      final cache =
          cachedPrefixPaths ??= List<String?>.filled(totalSegments + 1, null);
      final existing = cache[depth];
      if (existing != null) return existing;
      final built = depth == 1
          ? '/${segments[0]}'
          : '${pathAtDepth(depth - 1)}/${segments[depth - 1]}';
      cache[depth] = built;
      return built;
    }

    List<String>? matchedPaths;
    List<SintPage>? matchedPages;
    var lastMatchedDepth = -1;
    RegExpMatch? finalDepthMatch;

    for (var d = 0; d <= totalSegments; d++) {
      SintPage? matched;
      RegExpMatch? capturedMatch;

      for (var k = d; k >= 0; k--) {
        final node = nodeStack[k];
        if (node == null) continue;
        final nodeRoutes = node.routes;
        for (var r = 0; r < nodeRoutes.length; r++) {
          final entry = nodeRoutes[r];
          final expectedSegs = entry.exactSegmentCount;
          if (expectedSegs != null && expectedSegs != d) continue;

          final exact = entry.exactPath;
          if (exact != null) {
            if (pathAtDepth(d) == exact) {
              matched = entry.route;
              break;
            }
          } else if (d == totalSegments &&
              expectedSegs != null &&
              !cleanPath.endsWith('/')) {
            final m = entry.route.path.regex.firstMatch(pathAtDepth(d));
            if (m != null) {
              matched = entry.route;
              capturedMatch = m;
              break;
            }
          } else if (entry.route.path.regex.hasMatch(pathAtDepth(d))) {
            matched = entry.route;
            break;
          }
        }
        if (matched != null) break;
      }

      if (matched == null) {
        for (final bucket in [
          _patternParamRoutes,
          _simpleParamRoutes,
          _wildcardRoutes,
        ]) {
          if (bucket.isEmpty) continue;
          for (var r = 0; r < bucket.length; r++) {
            final entry = bucket[r];
            final expectedSegs = entry.exactSegmentCount;
            if (expectedSegs != null && expectedSegs != d) continue;
            final p = pathAtDepth(d);
            if (d == totalSegments &&
                expectedSegs != null &&
                !cleanPath.endsWith('/')) {
              final m = entry.route.path.regex.firstMatch(p);
              if (m != null) {
                matched = entry.route;
                capturedMatch = m;
                break;
              }
            } else if (entry.route.path.regex.hasMatch(p)) {
              matched = entry.route;
              break;
            }
          }
          if (matched != null) break;
        }
      }

      if (matched != null) {
        (matchedPaths ??= <String>[]).add(pathAtDepth(d));
        (matchedPages ??= <SintPage>[]).add(matched);
        lastMatchedDepth = d;
        if (d == totalSegments) {
          finalDepthMatch = capturedMatch;
        }
      }
    }

    // ── Slug / vanity-URL fix ──────────────────────────────────────────
    // When the URL has segments beyond "/" (e.g. "/serzenmontoya") but
    // only a parent segment like "/" matched, the full URL is NOT a
    // registered route.  Return an empty tree so unknownRoute triggers
    // (which resolves vanity slugs via SlugResolverPage).
    if (matchedPages != null &&
        totalSegments > 0 &&
        lastMatchedDepth != totalSegments) {
      if (arguments != null) {
        arguments.params.clear();
        if (rawQueryParams.isNotEmpty) {
          arguments.params.addAll(rawQueryParams);
        }
      }
      return RouteDecoder(const <SintPage>[], arguments);
    }

    if (matchedPages != null) {
      final lastPage = matchedPages.last;
      final parsedParams = _parseParams(
        cleanPath,
        lastPage.path,
        cachedMatch: finalDepthMatch,
      );

      final Map<String, String> mergedParams;
      if (rawQueryParams.isEmpty && parsedParams.isEmpty) {
        mergedParams = const <String, String>{};
      } else if (rawQueryParams.isEmpty) {
        mergedParams = parsedParams;
      } else if (parsedParams.isEmpty) {
        mergedParams = Map<String, String>.of(rawQueryParams);
      } else {
        mergedParams = <String, String>{
          ...rawQueryParams,
          ...parsedParams,
        };
      }

      if (arguments != null) {
        if (parsedParams.isNotEmpty) {
          arguments.pathParams.addAll(parsedParams);
        }
        arguments.params.clear();
        if (mergedParams.isNotEmpty) {
          arguments.params.addAll(mergedParams);
        }
      }

      final paths = matchedPaths!;
      final branchLength = matchedPages.length;
      final mappedTreeBranch = List<SintPage>.generate(branchLength, (idx) {
        final page = matchedPages![idx];
        final matchedPath = paths[idx];
        final existingParams = page.parameters;
        final Map<String, String> pageParams;
        if (existingParams == null || existingParams.isEmpty) {
          pageParams = mergedParams.isEmpty
              ? <String, String>{}
              : Map<String, String>.of(mergedParams);
        } else if (mergedParams.isEmpty) {
          pageParams = Map<String, String>.of(existingParams);
        } else {
          pageParams = <String, String>{
            ...existingParams,
            ...mergedParams,
          };
        }
        return page.copyWith(
          key: ValueKey(matchedPath),
          name: matchedPath,
          path: page.path,
          parameters: pageParams,
        );
      });

      return RouteDecoder(
        mappedTreeBranch,
        arguments,
      );
    }

    if (arguments != null) {
      arguments.params.clear();
      if (rawQueryParams.isNotEmpty) {
        arguments.params.addAll(rawQueryParams);
      }
    }

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

  Map<String, String> _parseParams(
    String cleanPath,
    PathDecoded routePath, {
    RegExpMatch? cachedMatch,
  }) {
    final keys = routePath.keys;
    if (keys.isEmpty) return const <String, String>{};
    final paramsMatch = cachedMatch ?? routePath.regex.firstMatch(cleanPath);
    if (paramsMatch == null) {
      return const <String, String>{};
    }
    final params = <String, String>{};
    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      if (key == null) continue; // A capture inside a custom parameter pattern.
      final group = paramsMatch[i + 1];
      // Optional params (e.g. ':id?') may be absent from the URL — their
      // match group is null. Skip them instead of null-asserting.
      if (group == null) continue;
      // Path segments are decoded with decodeComponent (NOT
      // decodeQueryComponent): '+' is a literal plus in a path segment,
      // and '%2F' decodes to '/' after the segment split.
      params[key] =
          group.contains('%') ? Uri.decodeComponent(group) : group;
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

  void sortRoutesRecursively() {
    if (routes.length > 1) {
      routes.sort((a, b) {
        final tailCmp = a.tailRank.compareTo(b.tailRank);
        if (tailCmp != 0) return tailCmp;
        final litCmp = b.literalCount.compareTo(a.literalCount);
        if (litCmp != 0) return litCmp;
        return a.order.compareTo(b.order);
      });
    }
    for (final child in children.values) {
      child.sortRoutesRecursively();
    }
  }

  void clear() {
    children.clear();
    routes.clear();
  }
}

class _IndexedRoute {
  const _IndexedRoute(
    this.order,
    this.route, {
    required this.tailRank,
    required this.literalCount,
    this.exactPath,
    this.exactSegmentCount,
  });

  final int order;
  final SintPage route;
  final int tailRank;
  final int literalCount;
  final String? exactPath;
  final int? exactSegmentCount;
}
