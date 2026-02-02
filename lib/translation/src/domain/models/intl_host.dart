import 'dart:ui';

class IntlHost {
  Locale? locale;

  Locale? fallbackLocale;

  Map<String, Map<String, String>> translations = {};
}