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

    Sint.log('GetInformationParser: route location: $location');

    return SynchronousFuture(RouteDecoder.fromRoute(location));
  }

  @override
  RouteInformation restoreRouteInformation(RouteDecoder configuration) {
    return RouteInformation(
      uri: Uri.tryParse(configuration.pageSettings?.name ?? ''),
      state: null,
    );
  }
}
