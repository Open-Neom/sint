import 'dart:ui';

import 'package:sint/core/src/domain/interfaces/sint_interface.dart';
import 'package:sint/translation/src/domain/models/intl_host.dart';
import 'package:sint/translation/src/domain/models/path_translator.dart';

extension LocalesIntl on SintInterface {
  static final _intlHost = IntlHost();

  /// Internal access to the active [IntlHost] for `O(1)` cached lookups.
  static IntlHost get host => _intlHost;

  Locale? get locale => _intlHost.locale;

  Locale? get fallbackLocale => _intlHost.fallbackLocale;

  set locale(Locale? newLocale) => _intlHost.locale = newLocale;

  set fallbackLocale(Locale? newLocale) => _intlHost.fallbackLocale = newLocale;

  Map<String, Map<String, String>> get translations => _intlHost.translations;

  /// Optional callback invoked when `.tr` cannot find a key in active or
  /// fallback locale maps.
  void Function(String key, Locale? locale)? get onMissingTranslationKey =>
      _intlHost.onMissingKey;

  set onMissingTranslationKey(
    void Function(String key, Locale? locale)? callback,
  ) =>
      _intlHost.onMissingKey = callback;

  /// URL path translator (built when `translateEndpoints: true`).
  PathTranslator? get pathTranslator => _intlHost.pathTranslator;

  set pathTranslator(PathTranslator? value) => _intlHost.pathTranslator = value;

  void addTranslations(Map<String, Map<String, String>> tr) {
    translations.addAll(tr);
    _intlHost.invalidateCache();
  }

  void clearTranslations() {
    translations.clear();
    _intlHost.lazyLoaders.clear();
    _intlHost.loadedLocales.clear();
    _intlHost.onMissingKey = null;
    _intlHost.invalidateCache();
  }

  void appendTranslations(Map<String, Map<String, String>> tr) {
    tr.forEach((key, map) {
      if (translations.containsKey(key)) {
        translations[key]!.addAll(map);
      } else {
        translations[key] = map;
      }
    });
    _intlHost.invalidateCache();
  }

  /// Registers a deferred loader for [localeTag] (e.g. `'es'` or `'es_MX'`).
  ///
  /// The [loader] runs on demand when [ensureLocaleLoaded] or `Sint.updateLocale`
  /// switches to a matching locale.
  void registerLazyTranslations(
    String localeTag,
    Future<Map<String, String>> Function() loader,
  ) {
    _intlHost.lazyLoaders[localeTag] = loader;
  }

  /// Ensures any deferred translations registered via [registerLazyTranslations]
  /// for [targetLocale] (`languageCode` and `languageCode_countryCode`) are loaded.
  ///
  /// Returns `true` if at least one lazy bundle was fetched and merged.
  Future<bool> ensureLocaleLoaded(Locale targetLocale) async {
    if (_intlHost.lazyLoaders.isEmpty) return false;
    var loadedAny = false;
    final candidates = <String>[
      targetLocale.languageCode,
      if (targetLocale.countryCode != null &&
          targetLocale.countryCode!.isNotEmpty)
        '${targetLocale.languageCode}_${targetLocale.countryCode}',
    ];
    for (final tag in candidates) {
      if (_intlHost.loadedLocales.contains(tag)) continue;
      final loader = _intlHost.lazyLoaders[tag];
      if (loader != null) {
        final map = await loader();
        _intlHost.loadedLocales.add(tag);
        appendTranslations({tag: map});
        loadedAny = true;
      }
    }
    return loadedAny;
  }

  /// Loads translations asynchronously from a [loader] callback and merges
  /// them with existing translations (does not replace).
  ///
  /// Useful for lazy-loading translations per module/feature, from assets,
  /// network, or any async source.
  ///
  /// ```dart
  /// await Sint.loadTranslations(() async {
  ///   final json = await rootBundle.loadString('assets/i18n/es.json');
  ///   return {'es': Map<String, String>.from(jsonDecode(json))};
  /// });
  /// ```
  Future<void> loadTranslations(
    Future<Map<String, Map<String, String>>> Function() loader,
  ) async {
    final newTranslations = await loader();
    appendTranslations(newTranslations);
  }
}
