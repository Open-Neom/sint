import 'dart:ui';

import 'path_translator.dart';

class IntlHost {
  Locale? locale;

  Locale? fallbackLocale;

  Map<String, Map<String, String>> translations = {};

  /// URL path translator built from translations when `translateEndpoints` is enabled.
  PathTranslator? pathTranslator;
}