import 'package:sint/sint.dart';

extension TransExtension on String {
  // Checks whether the language code and country code are present, and
  // whether the key is also present.
  bool get _fullLocaleAndKey {
    return Sint.translations.containsKey(
        "${Sint.locale!.languageCode}_${Sint.locale!.countryCode}") &&
        Sint.translations[
        "${Sint.locale!.languageCode}_${Sint.locale!.countryCode}"]!
            .containsKey(this);
  }

  // Checks if there is a callback language in the absence of the specific
  // country, and if it contains that key.
  Map<String, String>? get _similarLanguageTranslation {
    final translationsWithNoCountry = Sint.translations
        .map((key, value) => MapEntry(key.split("_").first, value));
    final containsKey = translationsWithNoCountry
        .containsKey(Sint.locale!.languageCode.split("_").first);

    if (!containsKey) {
      return null;
    }

    return translationsWithNoCountry[Sint.locale!.languageCode.split("_").first];
  }

  String get tr {
    // Returns the key if locale is null.
    if (Sint.locale?.languageCode == null) return this;

    if (_fullLocaleAndKey) {
      return Sint.translations[
      "${Sint.locale!.languageCode}_${Sint.locale!.countryCode}"]![this]!;
    }
    final similarTranslation = _similarLanguageTranslation;
    if (similarTranslation != null && similarTranslation.containsKey(this)) {
      return similarTranslation[this]!;
      // If there is no corresponding language or corresponding key, return
      // the key.
    } else if (Sint.fallbackLocale != null) {
      final fallback = Sint.fallbackLocale!;
      final key = "${fallback.languageCode}_${fallback.countryCode}";

      if (Sint.translations.containsKey(key) &&
          Sint.translations[key]!.containsKey(this)) {
        return Sint.translations[key]![this]!;
      }
      if (Sint.translations.containsKey(fallback.languageCode) &&
          Sint.translations[fallback.languageCode]!.containsKey(this)) {
        return Sint.translations[fallback.languageCode]![this]!;
      }
      return this;
    } else {
      return this;
    }
  }

  String trArgs([List<String> args = const []]) {
    var key = tr;
    if (args.isNotEmpty) {
      for (final arg in args) {
        key = key.replaceFirst(RegExp(r'%s'), arg.toString());
      }
    }
    return key;
  }

  String trPlural([String? pluralKey, int? i, List<String> args = const []]) {
    return i == 1 ? trArgs(args) : pluralKey!.trArgs(args);
  }

  String trParams([Map<String, String> params = const {}]) {
    var trans = tr;
    if (params.isNotEmpty) {
      params.forEach((key, value) {
        trans = trans.replaceAll('@$key', value);
      });
    }
    return trans;
  }

  String trPluralParams(
      [String? pluralKey, int? i, Map<String, String> params = const {}]) {
    return i == 1 ? trParams(params) : pluralKey!.trParams(params);
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
