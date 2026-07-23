import 'package:flutter/widgets.dart';

class PageSettings extends RouteSettings {
  PageSettings(
    this.uri, [
    Object? arguments,
  ]) : super(arguments: arguments);

  @override
  String get name => '$uri';

  final Uri uri;

  final params = <String, String>{};

  /// Path (segment) parameters only, e.g. `:id` in `/user/:id`.
  /// Populated by RouteParser during matchRoute. Kept separate from
  /// query parameters since 1.5.0; [params] keeps the legacy merged view.
  final pathParams = <String, String>{};

  String get path => uri.path;

  List<String> get paths => uri.pathSegments;

  Map<String, String> get query => uri.queryParameters;

  /// Query parameters only (alias of [query], mirrors [pathParams]).
  Map<String, String> get queryParams => uri.queryParameters;

  Map<String, List<String>> get queries => uri.queryParametersAll;

  @override
  String toString() => name;

  PageSettings copy({
    Uri? uri,
    Object? arguments,
  }) {
    return PageSettings(
      uri ?? this.uri,
      arguments ?? this.arguments,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PageSettings &&
        other.uri == uri &&
        other.arguments == arguments;
  }

  @override
  int get hashCode => uri.hashCode ^ arguments.hashCode;
}

/// Builds a concrete URL from a route template (1.5.0).
///
/// - [pathParams] values replace `:param` segments. Pattern (`:id(\d+)`),
///   optional (`:id?`) and wildcard (`:path*`) markers are stripped from
///   the parameter name before lookup. Values are encoded per-segment
///   (a literal `/` inside a value becomes `%2F`).
/// - [queryParams] are merged into the query string, preserving any
///   query already present in [page].
///
/// Unresolved `:param` segments are left as-is (the route will simply
/// not match, preserving the classic unknownRoute flow).
String resolveRoutePath(
  String page, {
  Map<String, String>? pathParams,
  Map<String, String>? queryParams,
}) {
  var resolved = page;

  if (pathParams != null && pathParams.isNotEmpty) {
    // Textual path surgery: the query string (if any) is preserved
    // verbatim and values are encoded per-segment.
    final qIdx = resolved.indexOf('?');
    final query = qIdx >= 0 ? resolved.substring(qIdx) : '';
    final pathOnly = qIdx >= 0 ? resolved.substring(0, qIdx) : resolved;
    final segments = pathOnly.split('/');
    for (var i = 0; i < segments.length; i++) {
      if (segments[i].startsWith(':')) {
        segments[i] = _substituteSegment(segments[i], pathParams);
      }
    }
    resolved = segments.join('/') + query;
  }

  if (queryParams != null && queryParams.isNotEmpty) {
    final uri = Uri.parse(resolved);
    resolved = uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...queryParams,
    }).toString();
  }

  return resolved;
}

String _substituteSegment(String segment, Map<String, String> pathParams) {
  var name = segment.substring(1);
  // Strip a custom pattern (':id(\d+)') before marker checks.
  final parenIdx = name.indexOf('(');
  if (parenIdx >= 0) name = name.substring(0, parenIdx);
  // Strip wildcard ('*') / optional ('?') markers.
  if (name.endsWith('*') || name.endsWith('?')) {
    name = name.substring(0, name.length - 1);
  }
  final value = pathParams[name];
  return value == null ? segment : Uri.encodeComponent(value);
}
