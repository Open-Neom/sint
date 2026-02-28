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

    for (final localeEntry in translations.entries) {
      // Handle both 'es' and 'es_MX' style keys.
      final locale = localeEntry.key.split('_').first;
      if (locale == 'en') continue; // English is canonical — no mapping.

      final localeMap = <String, String>{};
      for (final segment in routeSegments) {
        final value = localeEntry.value[segment];
        if (value == null) continue;

        final normalized = _removeDiacritics(value.toLowerCase());
        if (normalized.contains(' ')) continue; // Multi-word: can't be URL segment.
        if (normalized == segment) continue; // Same as canonical: no-op.

        localeMap[segment] = normalized;
        reverseMap[normalized] = segment;
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
      final name = (route as dynamic).name as String;
      for (final seg in name.split('/')) {
        if (seg.isEmpty) continue;
        if (seg.startsWith(':')) continue; // Skip parameters.
        segments.add(seg);
      }
    }
    return segments;
  }

  // ─── Public API ───────────────────────────────────────────────

  /// Canonicalizes a localized URL path to canonical English.
  ///
  /// `/libro/abc123` → `/book/abc123`
  /// `/livre/abc123` → `/book/abc123`
  /// `/book/abc123`  → `/book/abc123` (already canonical)
  String canonicalizePath(String path) {
    if (path.isEmpty || path == '/') return path;

    final qIndex = path.indexOf('?');
    final purePath = qIndex > -1 ? path.substring(0, qIndex) : path;
    final query = qIndex > -1 ? path.substring(qIndex) : '';

    final segments = purePath.split('/');
    var changed = false;
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      if (seg.isEmpty) continue;
      final canonical = _reverseMap[seg];
      if (canonical != null) {
        segments[i] = canonical;
        changed = true;
      }
    }
    if (!changed) return path;
    return segments.join('/') + query;
  }

  /// Localizes a canonical English path to the given language code.
  ///
  /// `/book/abc123` → `/libro/abc123` (for `'es'`)
  /// `/book/abc123` → `/book/abc123`  (for `'en'`, no-op)
  String localizePath(String path, String languageCode) {
    if (path.isEmpty || path == '/') return path;
    if (languageCode == 'en') return path;

    final localMap = _forwardMaps[languageCode];
    if (localMap == null) return path;

    final qIndex = path.indexOf('?');
    final purePath = qIndex > -1 ? path.substring(0, qIndex) : path;
    final query = qIndex > -1 ? path.substring(qIndex) : '';

    final segments = purePath.split('/');
    var changed = false;
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      if (seg.isEmpty) continue;
      final localized = localMap[seg];
      if (localized != null) {
        segments[i] = localized;
        changed = true;
      }
    }
    if (!changed) return path;
    return segments.join('/') + query;
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
