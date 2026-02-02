import 'dart:ui';

import 'package:sint/core/src/domain/interfaces/sint_interface.dart';
import 'package:sint/translation/src/domain/models/intl_host.dart';

extension LocalesIntl on SintInterface {
  static final _intlHost = IntlHost();

  Locale? get locale => _intlHost.locale;

  Locale? get fallbackLocale => _intlHost.fallbackLocale;

  set locale(Locale? newLocale) => _intlHost.locale = newLocale;

  set fallbackLocale(Locale? newLocale) => _intlHost.fallbackLocale = newLocale;

  Map<String, Map<String, String>> get translations => _intlHost.translations;

  void addTranslations(Map<String, Map<String, String>> tr) {
    translations.addAll(tr);
  }

  void clearTranslations() {
    translations.clear();
  }

  void appendTranslations(Map<String, Map<String, String>> tr) {
    tr.forEach((key, map) {
      if (translations.containsKey(key)) {
        translations[key]!.addAll(map);
      } else {
        translations[key] = map;
      }
    });
  }
}

