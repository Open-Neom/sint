import 'dart:collection';
import 'dart:ui';

import 'path_translator.dart';

class IntlHost {
  Locale? _locale;
  Locale? _fallbackLocale;

  late final Map<String, Map<String, String>> translations =
      _InvalidatingTranslationsMap(_markDirty);

  /// Optional lazy translation loaders keyed by locale tag (e.g. `'es'`, `'es_MX'`).
  final Map<String, Future<Map<String, String>> Function()> lazyLoaders = {};

  /// Tracks locale tags already loaded via [lazyLoaders].
  final Set<String> loadedLocales = {};

  /// Optional hook invoked when a key is missing in both active and fallback locales.
  void Function(String key, Locale? locale)? onMissingKey;

  /// URL path translator built from translations when `translateEndpoints` is enabled.
  PathTranslator? pathTranslator;

  bool _cacheDirty = true;
  Map<String, String>? _primaryMap;
  Map<String, String>? _languageMap;
  Map<String, String>? _fallbackPrimaryMap;
  Map<String, String>? _fallbackLanguageMap;

  Locale? get locale => _locale;

  set locale(Locale? value) {
    if (_locale == value) return;
    _locale = value;
    _cacheDirty = true;
  }

  Locale? get fallbackLocale => _fallbackLocale;

  set fallbackLocale(Locale? value) {
    if (_fallbackLocale == value) return;
    _fallbackLocale = value;
    _cacheDirty = true;
  }

  void invalidateCache() {
    _cacheDirty = true;
  }

  void _markDirty() {
    _cacheDirty = true;
  }

  Map<String, String>? _resolveLanguageMap(String languageCode) {
    final langPrefix = languageCode.contains('_')
        ? languageCode.split('_').first
        : languageCode;
    final exact = translations[langPrefix];
    if (exact != null) return exact;

    // Fallback to regional entries sharing the same base language (e.g. 'es_MX' for 'es'),
    // matching historical last-entry behavior without per-lookup Map allocations.
    Map<String, String>? matched;
    final prefixWithSep = '${langPrefix}_';
    for (final entry in translations.entries) {
      final key = entry.key;
      if (key == langPrefix || key.startsWith(prefixWithSep)) {
        matched = entry.value;
      }
    }
    return matched;
  }

  void _rebuildCache() {
    _primaryMap = null;
    _languageMap = null;
    _fallbackPrimaryMap = null;
    _fallbackLanguageMap = null;

    final loc = _locale;
    if (loc != null) {
      final country = loc.countryCode;
      if (country != null && country.isNotEmpty) {
        _primaryMap = translations['${loc.languageCode}_$country'];
      }
      _languageMap = _resolveLanguageMap(loc.languageCode);
    }

    final fb = _fallbackLocale;
    if (fb != null) {
      final fbCountry = fb.countryCode;
      if (fbCountry != null && fbCountry.isNotEmpty) {
        _fallbackPrimaryMap = translations['${fb.languageCode}_$fbCountry'];
      }
      _fallbackLanguageMap = _resolveLanguageMap(fb.languageCode);
    }

    _cacheDirty = false;
  }

  /// Resolves [key] in `O(1)` against cached active/fallback locale maps.
  /// Returns `null` when no translation exists (or when [locale] is `null`).
  String? lookup(String key, {bool reportMissing = true}) {
    final loc = _locale;
    if (loc == null) return null;
    if (_cacheDirty) _rebuildCache();

    final v1 = _primaryMap?[key];
    if (v1 != null) return v1;

    final v2 = _languageMap?[key];
    if (v2 != null) return v2;

    final v3 = _fallbackPrimaryMap?[key];
    if (v3 != null) return v3;

    final v4 = _fallbackLanguageMap?[key];
    if (v4 != null) return v4;

    if (reportMissing) {
      onMissingKey?.call(key, loc);
    }
    return null;
  }

  /// Checks whether [key] exists in active/fallback locale maps without
  /// triggering [onMissingKey].
  bool hasKey(String key) => lookup(key, reportMissing: false) != null;
}

class _InvalidatingTranslationsMap
    extends MapBase<String, Map<String, String>> {
  _InvalidatingTranslationsMap(this._onMutated);

  final Map<String, Map<String, String>> _inner = {};
  final void Function() _onMutated;

  @override
  Map<String, String>? operator [](Object? key) => _inner[key];

  @override
  void operator []=(String key, Map<String, String> value) {
    _inner[key] = value;
    _onMutated();
  }

  @override
  void clear() {
    if (_inner.isEmpty) return;
    _inner.clear();
    _onMutated();
  }

  @override
  Iterable<String> get keys => _inner.keys;

  @override
  Map<String, String>? remove(Object? key) {
    if (!_inner.containsKey(key)) return null;
    final removed = _inner.remove(key);
    _onMutated();
    return removed;
  }

  @override
  int get length => _inner.length;

  @override
  bool get isEmpty => _inner.isEmpty;

  @override
  bool get isNotEmpty => _inner.isNotEmpty;

  @override
  bool containsKey(Object? key) => _inner.containsKey(key);

  @override
  Iterable<MapEntry<String, Map<String, String>>> get entries => _inner.entries;

  @override
  void addAll(Map<String, Map<String, String>> other) {
    if (other.isEmpty) return;
    _inner.addAll(other);
    _onMutated();
  }
}
