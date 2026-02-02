import 'package:flutter/material.dart';
import 'package:sint/sint.dart';

class WrapperTranslations extends Translations {
  static const fallbackLocale = Locale('en', 'US');
  static Locale? get locale => const Locale('en', 'US');
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      'covid': 'Corona Virus',
      'total_confirmed': 'Total Confirmed',
      'total_deaths': 'Total Deaths',
    },
    'pt_BR': {
      'covid': 'Corona Vírus',
      'total_confirmed': 'Total confirmado',
      'total_deaths': 'Total de mortes',
    },
  };
}
