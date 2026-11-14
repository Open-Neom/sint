/// Translates URL path segments between canonical (English) and localized forms.
///
/// Built automatically by SINT when `translateEndpoints: true` is set on
/// [SintMaterialApp]. Uses the app's registered translations to derive
/// segment mappings — no external localization file needed.
///
/// Example:
/// - ES: `/book/abc123` ↔ `/libro/abc123`
/// - FR: `/book/abc123` ↔ `/livre/abc123`
class PathTranslator {
  /// Per-locale forward maps: canonical segment → localized segment.
  /// e.g. `{'es': {'book': 'libro', 'event': 'evento'}, 'fr': {'book': 'livre'}}`
  final Map<String, Map<String, String>> _forwardMaps;

  /// Reverse map: any localized segment → canonical segment (all locales).
  /// e.g. `{'libro': 'book', 'livre': 'book', 'buch': 'book'}`
  final Map<String, String> _reverseMap;

  PathTranslator._(this._forwardMaps, this._reverseMap);

  static const Set<String> _reservedProtoSegments = <String>{
    '__proto__',
    'constructor',
    'prototype',
  };

  static final RegExp _disallowedSegmentChars = RegExp(
    r'[\x00-\x20\x7F-\x9F\u0085\u061C\u200B-\u200F\u2028-\u202E\u2060\u2066-\u2069\uFEFF/\\?#:%]+',
  );

  /// Builds a [PathTranslator] from SINT's loaded translations and the
  /// static route segments extracted from registered [SintPage] names.
  ///
  /// [translations] — full translation map from `Sint.translations`
  ///   (`{locale: {key: value}}`).
  /// [routeSegments] — static segments extracted via [extractSegments].
  factory PathTranslator.build({
    required Map<String, Map<String, String>> translations,
    required Set<String> routeSegments,
  }) {
    final forwardMaps = <String, Map<String, String>>{};
    final reverseMap = <String, String>{};
    final canonicalNormalized = <String>{
      for (final seg in routeSegments) _removeDiacritics(seg.toLowerCase()).trim(),
    };

    for (final localeEntry in translations.entries) {
      // Handle both 'es' and 'es_MX' style keys.
      final locale = localeEntry.key.split('_').first;
      if (locale == 'en') continue; // English is canonical — no mapping.

      final localeMap = <String, String>{};
      for (final segment in routeSegments) {
        final value = localeEntry.value[segment];
        if (value == null) continue;

        final normalized = _removeDiacritics(value.toLowerCase()).trim();
        if (normalized.isEmpty ||
            normalized == '.' ||
            normalized == '..' ||
            _reservedProtoSegments.contains(normalized) ||
            _reservedProtoSegments.contains(segment) ||
            _disallowedSegmentChars.hasMatch(normalized)) {
          continue; // Multi-word, control/Bidi, reserved key, or separator: can't be URL segment.
        }
        if (normalized == segment) continue; // Same as canonical: no-op.

        localeMap[segment] = normalized;
        // Never overwrite a registered canonical route segment in reverseMap
        // (e.g. French 'cat' -> 'chat' must not hijack canonical '/chat').
        if (!canonicalNormalized.contains(normalized) &&
            !routeSegments.contains(normalized)) {
          reverseMap[normalized] = segment;
        }
      }

      if (localeMap.isNotEmpty) {
        // Merge into existing locale map (handles 'es' + 'es_MX' both present).
        forwardMaps.putIfAbsent(locale, () => {}).addAll(localeMap);
      }
    }

    return PathTranslator._(forwardMaps, reverseMap);
  }

  /// Extracts unique static segments from registered route names.
  ///
  /// `/book/:bookId` → `{'book'}`
  /// `/shop/product/:productId` → `{'shop', 'product'}`
  static Set<String> extractSegments(List<dynamic> routes) {
    final segments = <String>{};
    for (final route in routes) {
      final rawName = (route as dynamic)?.name;
      if (rawName is! String || rawName.isEmpty) continue;
      for (final seg in rawName.split('/')) {
        if (seg.isEmpty) continue;
        if (seg.startsWith(':')) continue; // Skip parameters.
        segments.add(seg);
      }
    }
    return segments;
  }

  // ─── Public API ───────────────────────────────────────────────

  static int _suffixSplitIndex(String path) {
    final qIndex = path.indexOf('?');
    final hIndex = path.indexOf('#');
    if (qIndex == -1) return hIndex;
    if (hIndex == -1) return qIndex;
    return qIndex < hIndex ? qIndex : hIndex;
  }

  /// Canonicalizes a localized URL path to canonical English.
  ///
  /// `/libro/abc123` → `/book/abc123`
  /// `/livre/abc123` → `/book/abc123`
  /// `/book/abc123`  → `/book/abc123` (already canonical)
  String canonicalizePath(String path) {
    if (path.isEmpty || path == '/') return path;

    final sIndex = _suffixSplitIndex(path);
    final purePath = sIndex > -1 ? path.substring(0, sIndex) : path;
    final suffix = sIndex > -1 ? path.substring(sIndex) : '';

    final segments = purePath.split('/');
    var changed = false;
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      if (seg.isEmpty || _reservedProtoSegments.contains(seg)) continue;
      final canonical = _reverseMap[seg];
      if (canonical != null) {
        segments[i] = canonical;
        changed = true;
      }
    }
    if (!changed) return path;
    return segments.join('/') + suffix;
  }

  /// Localizes a canonical English path to the given language code.
  ///
  /// `/book/abc123` → `/libro/abc123` (for `'es'`)
  /// `/book/abc123` → `/book/abc123`  (for `'en'`, no-op)
  String localizePath(String path, String languageCode) {
    if (path.isEmpty || path == '/') return path;
    if (languageCode == 'en' || _reservedProtoSegments.contains(languageCode)) {
      return path;
    }

    final localMap = _forwardMaps[languageCode];
    if (localMap == null) return path;

    final sIndex = _suffixSplitIndex(path);
    final purePath = sIndex > -1 ? path.substring(0, sIndex) : path;
    final suffix = sIndex > -1 ? path.substring(sIndex) : '';

    final segments = purePath.split('/');
    var changed = false;
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      if (seg.isEmpty || _reservedProtoSegments.contains(seg)) continue;
      final localized = localMap[seg];
      if (localized != null) {
        segments[i] = localized;
        changed = true;
      }
    }
    if (!changed) return path;
    return segments.join('/') + suffix;
  }

  // ─── Diacritics ───────────────────────────────────────────────

  static const _diacriticsFrom =
      'ÀÁÂÃÄÅàáâãäåÈÉÊËèéêëÌÍÎÏìíîïÒÓÔÕÖØòóôõöøÙÚÛÜùúûüÝýÿÑñÇç';
  static const _diacriticsTo =
      'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOOooooooUUUUuuuuYyyNnCc';

  static final Map<int, String> _charMap = () {
    final map = <int, String>{};
    for (var i = 0; i < _diacriticsFrom.length; i++) {
      map[_diacriticsFrom.codeUnitAt(i)] = _diacriticsTo[i];
    }
    return map;
  }();

  /// Replaces accented characters with their ASCII equivalents.
  /// `Publicación` → `Publicacion`
  static String _removeDiacritics(String input) {
    final buffer = StringBuffer();
    for (final unit in input.codeUnits) {
      buffer.write(_charMap[unit] ?? String.fromCharCode(unit));
    }
    return buffer.toString();
  }
}
