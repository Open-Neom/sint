import 'package:flutter/material.dart';
import 'package:sint/sint.dart';

class Wrapper extends StatelessWidget {
  final Widget? child;
  final List<SintPage>? namedRoutes;
  final String? initialRoute;
  final Transition? defaultTransition;

  const Wrapper({
    super.key,
    this.child,
    this.namedRoutes,
    this.initialRoute,
    this.defaultTransition,
  });

  @override
  Widget build(BuildContext context) {
    return SintMaterialApp(
      defaultTransition: defaultTransition,
      initialRoute: initialRoute,
      translations: WrapperTranslations(),
      locale: WrapperTranslations.locale,
      sintPages: namedRoutes,
      home: namedRoutes == null
          ? Scaffold(
        body: child,
      )
          : null,
    );
  }
}

class WrapperNamed extends StatelessWidget {
  final Widget? child;
  final List<SintPage>? namedRoutes;
  final String? initialRoute;
  final Transition? defaultTransition;

  const WrapperNamed({
    super.key,
    this.child,
    this.namedRoutes,
    this.initialRoute,
    this.defaultTransition,
  });

  @override
  Widget build(BuildContext context) {
    return SintMaterialApp(
      defaultTransition: defaultTransition,
      initialRoute: initialRoute,
      sintPages: namedRoutes,
    );
  }
}

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
