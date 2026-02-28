import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../sint.dart';

class SintInformationParser extends RouteInformationParser<RouteDecoder> {
  factory SintInformationParser.createInformationParser(
      {String initialRoute = '/'}) {
    return SintInformationParser(initialRoute: initialRoute);
  }

  final String initialRoute;

  SintInformationParser({
    required this.initialRoute,
  }) {
    Sint.log('GetInformationParser is created !');
  }
  @override
  SynchronousFuture<RouteDecoder> parseRouteInformation(
    RouteInformation routeInformation,
  ) {
    final uri = routeInformation.uri;
    var location = uri.toString();
    if (location == '/') {
      //check if there is a corresponding page
      //if not, relocate to initialRoute
      if (!(Sint.rootController.rootDelegate)
          .registeredRoutes
          .any((element) => element.name == '/')) {
        location = initialRoute;
      }
    } else if (location.isEmpty) {
      location = initialRoute;
    }

    // URL Canonicalization: normalize localized segments to canonical English
    // e.g. '/libro/abc123' → '/book/abc123' before route matching
    if (Sint.pathTranslator != null) {
      location = Sint.pathTranslator!.canonicalizePath(location);
    }

    Sint.log('GetInformationParser: route location: $location');

    return SynchronousFuture(RouteDecoder.fromRoute(location));
  }

  @override
  RouteInformation restoreRouteInformation(RouteDecoder configuration) {
    var name = configuration.pageSettings?.name ?? '';

    // URL Localization: translate canonical segments to current locale
    // e.g. '/book/abc123' → '/libro/abc123' for the browser URL bar
    if (Sint.pathTranslator != null && Sint.locale != null) {
      name = Sint.pathTranslator!.localizePath(name, Sint.locale!.languageCode);
    }

    return RouteInformation(
      uri: Uri.tryParse(name),
      state: null,
    );
  }
}
