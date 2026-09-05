import '../domain/models/path_decoded.dart';

/// Shared syntax for matching routes and resolving navigation templates.
/// This is internal to the router; parameter values are encoded only when a
/// template is resolved, never while its matching expression is compiled.
class RouteTemplate {
  RouteTemplate._(this.tokens, this.suffix);

  final List<RouteTemplateToken> tokens;
  final String suffix;

  factory RouteTemplate.parse(String source, {bool allowQuery = true}) {
    final tokens = <RouteTemplateToken>[];
    var literalStart = 0;
    var cursor = 0;

    void addLiteral(int end) {
      if (end > literalStart) {
        tokens.add(RouteTemplateToken.literal(
          source.substring(literalStart, end),
        ));
      }
    }

    while (cursor < source.length) {
      final character = source[cursor];
      if (allowQuery && (character == '?' || character == '#')) {
        addLiteral(cursor);
        return RouteTemplate._(tokens, source.substring(cursor));
      }
      if (character != ':' ||
          cursor + 1 == source.length ||
          !_isNameCharacter(source.codeUnitAt(cursor + 1))) {
        cursor++;
        continue;
      }

      final start = cursor > literalStart &&
              (source[cursor - 1] == '/' || source[cursor - 1] == '.')
          ? cursor - 1
          : cursor;
      addLiteral(start);
      final prefix = source.substring(start, cursor);
      final nameStart = ++cursor;
      while (cursor < source.length &&
          _isNameCharacter(source.codeUnitAt(cursor))) {
        cursor++;
      }
      final name = source.substring(nameStart, cursor);
      String? pattern;
      if (cursor < source.length && source[cursor] == '(') {
        final patternStart = ++cursor;
        var depth = 1;
        var inCharacterClass = false;
        while (cursor < source.length && depth > 0) {
          final character = source[cursor];
          if (character == r'\') {
            cursor += 2;
            continue;
          }
          if (character == '[') inCharacterClass = true;
          if (character == ']') inCharacterClass = false;
          if (!inCharacterClass) {
            if (character == '(') depth++;
            if (character == ')') depth--;
          }
          cursor++;
        }
        if (depth != 0) {
          throw FormatException('Unclosed route parameter pattern', source);
        }
        pattern = source.substring(patternStart, cursor - 1);
      }

      // A terminal '?' or one before another path separator modifies the
      // parameter. '?tab=posts' is an existing query string instead.
      var optional = false;
      if (cursor < source.length && source[cursor] == '?') {
        final next = cursor + 1 == source.length ? '' : source[cursor + 1];
        if (!allowQuery || ['', '/', '.', '?', '#', '*'].contains(next)) {
          optional = true;
          cursor++;
        }
      }
      final wildcard = cursor < source.length && source[cursor] == '*';
      if (wildcard) cursor++;
      tokens.add(RouteTemplateToken.parameter(
        source: source.substring(start, cursor),
        name: name,
        prefix: prefix,
        pattern: pattern,
        optional: optional,
        wildcard: wildcard,
      ));
      literalStart = cursor;
    }
    addLiteral(source.length);
    return RouteTemplate._(tokens, '');
  }

  String resolve(Map<String, String> parameters) {
    final buffer = StringBuffer();
    for (final token in tokens) {
      final name = token.name;
      if (name == null) {
        buffer.write(token.source);
      } else if (parameters.containsKey(name)) {
        buffer
          ..write(token.prefix)
          ..write(Uri.encodeComponent(parameters[name]!));
      } else if (!token.optional) {
        buffer.write(token.source);
      }
    }
    if (buffer.isEmpty &&
        tokens.isNotEmpty &&
        tokens.first.source.startsWith('/')) {
      buffer.write('/');
    }
    buffer.write(suffix);
    return buffer.toString();
  }

  static PathDecoded compile(String source) {
    var normalized = source.replaceAll('//', '/');
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    final template = RouteTemplate.parse(normalized, allowQuery: false);
    final keys = <String?>[];
    final expression = StringBuffer('^');
    for (final token in template.tokens) {
      if (token.name == null) {
        expression.write(RegExp.escape(token.source));
        continue;
      }
      final pattern =
          token.wildcard ? '.+' : token.pattern ?? r"[\w%+._~!$&'()*,;=:@-]+";
      expression.write('(?:${RegExp.escape(token.prefix)}($pattern))');
      if (token.optional) expression.write('?');
      keys.add(token.name);
      // Custom patterns may contain their own captures. Reserve their group
      // positions so subsequent route parameters still read the right group.
      if (!token.wildcard && token.pattern != null) {
        final groupCount = RegExp('(?:$pattern)|').firstMatch('')!.groupCount;
        keys.addAll(List<String?>.filled(groupCount, null));
      }
    }
    expression.write(r'/?$');
    return PathDecoded(RegExp(expression.toString()), keys);
  }

  static bool _isNameCharacter(int code) =>
      (code >= 65 && code <= 90) ||
      (code >= 97 && code <= 122) ||
      (code >= 48 && code <= 57) ||
      code == 95;
}

class RouteTemplateToken {
  const RouteTemplateToken.literal(this.source)
      : name = null,
        prefix = '',
        pattern = null,
        optional = false,
        wildcard = false;

  const RouteTemplateToken.parameter({
    required this.source,
    required this.name,
    required this.prefix,
    required this.pattern,
    required this.optional,
    required this.wildcard,
  });

  final String source;
  final String? name;
  final String prefix;
  final String? pattern;
  final bool optional;
  final bool wildcard;
}
