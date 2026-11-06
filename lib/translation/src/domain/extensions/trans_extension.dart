import 'package:sint/translation/src/domain/extensions/locale_extension.dart';

extension TransExtension on String {
  static bool _isIdentChar(int codeUnit) {
    return (codeUnit >= 0x61 && codeUnit <= 0x7A) || // a-z
        (codeUnit >= 0x41 && codeUnit <= 0x5A) || // A-Z
        (codeUnit >= 0x30 && codeUnit <= 0x39) || // 0-9
        codeUnit == 0x5F; // _
  }

  String get tr => LocalesIntl.host.lookup(this) ?? this;

  String trArgs([List<String> args = const []]) {
    var key = tr;
    if (args.isEmpty) return key;
    var searchFrom = 0;
    final firstIdx = key.indexOf('%s', searchFrom);
    if (firstIdx < 0) return key;

    final buffer = StringBuffer();
    var matchIdx = firstIdx;
    var argIndex = 0;
    while (matchIdx >= 0 && argIndex < args.length) {
      buffer
        ..write(key.substring(searchFrom, matchIdx))
        ..write(args[argIndex]);
      searchFrom = matchIdx + 2;
      argIndex++;
      if (argIndex < args.length) {
        matchIdx = key.indexOf('%s', searchFrom);
      } else {
        break;
      }
    }
    buffer.write(key.substring(searchFrom));
    return buffer.toString();
  }

  String trPlural([String? pluralKey, int? i, List<String> args = const []]) {
    if (i == 0 && pluralKey == null) {
      final zeroKey = '${this}_zero';
      if (LocalesIntl.host.hasKey(zeroKey)) {
        return zeroKey.trArgs(args);
      }
    }
    if (i == 1) return trArgs(args);
    if (pluralKey != null) return pluralKey.trArgs(args);
    final otherKey = '${this}_other';
    if (LocalesIntl.host.hasKey(otherKey)) {
      return otherKey.trArgs(args);
    }
    return trArgs(args);
  }

  String trParams([Map<String, String> params = const {}]) {
    final trans = tr;
    if (params.isEmpty) return trans;
    var atIndex = trans.indexOf('@');
    if (atIndex < 0) return trans;

    final length = trans.length;
    StringBuffer? buffer;
    var cursor = 0;

    while (atIndex >= 0 && atIndex < length) {
      final tokenStart = atIndex + 1;
      var identEnd = tokenStart;
      while (identEnd < length && _isIdentChar(trans.codeUnitAt(identEnd))) {
        identEnd++;
      }

      String? replacement;
      var matchEnd = identEnd;
      if (identEnd > tokenStart) {
        replacement = params[trans.substring(tokenStart, identEnd)];
      }

      // Fallback for non-identifier keys or prefix tokens (e.g. '@a' inside '@ab').
      if (replacement == null) {
        var bestLen = 0;
        params.forEach((key, value) {
          if (key.length > bestLen && trans.startsWith(key, tokenStart)) {
            bestLen = key.length;
            replacement = value;
          }
        });
        if (bestLen > 0) {
          matchEnd = tokenStart + bestLen;
        }
      }

      if (replacement != null) {
        buffer ??= StringBuffer();
        buffer
          ..write(trans.substring(cursor, atIndex))
          ..write(replacement);
        cursor = matchEnd;
        atIndex = trans.indexOf('@', cursor);
      } else {
        atIndex = trans.indexOf('@', tokenStart);
      }
    }

    if (buffer == null) return trans;
    buffer.write(trans.substring(cursor));
    return buffer.toString();
  }

  String trPluralParams([
    String? pluralKey,
    int? i,
    Map<String, String> params = const {},
  ]) {
    if (i == 0 && pluralKey == null) {
      final zeroKey = '${this}_zero';
      if (LocalesIntl.host.hasKey(zeroKey)) {
        return zeroKey.trParams(params);
      }
    }
    if (i == 1) return trParams(params);
    if (pluralKey != null) return pluralKey.trParams(params);
    final otherKey = '${this}_other';
    if (LocalesIntl.host.hasKey(otherKey)) {
      return otherKey.trParams(params);
    }
    return trParams(params);
  }

  /// Capitalize each word inside string
  /// Example: your name => Your Name, your name => Your name
  String get capitalize {
    if (trim().isEmpty) return this;
    return split(' ').map((str) => str.capitalizeFirst).join(' ');
  }

  /// Uppercase first letter inside string and let the others lowercase
  /// Example: your name => Your name
  String get capitalizeFirst {
    if (trim().isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}
