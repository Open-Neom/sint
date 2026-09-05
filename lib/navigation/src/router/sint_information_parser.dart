import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:sint/core/sint_core.dart';
import 'package:sint/navigation/src/domain/extensions/navigation_extensions.dart';
import 'package:sint/translation/sint_translation.dart';
import 'package:sint/navigation/src/router/route_decoder.dart';

class SintInformationParser extends RouteInformationParser<RouteDecoder> {
  factory SintInformationParser.createInformationParser(
      {String initialRoute = '/'}) {
    return SintInformationParser(initialRoute: initialRoute);
  }

  final String initialRoute;

  SintInformationParser({
    required this.initialRoute,
  }) {
    Sint.log('SintInformationParser is created !');
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

    Sint.log('SintInformationParser: route location: $location');

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
      // The browser serializes RouteInformation.state. Keep plain JSON state,
      // but never ask it to encode arbitrary navigation-domain objects.
      state: sanitizeRouteInformationState(
        configuration.pageSettings?.arguments,
      ),
    );
  }
}

/// Returns [state] unchanged when its complete object graph is JSON-safe.
///
/// Navigation arguments remain available through [PageSettings] in memory.
/// This only prevents opaque Dart objects (for example domain models), cyclic
/// containers, maps with non-string keys, and non-finite numbers from reaching
/// browser history serialization.
@visibleForTesting
Object? sanitizeRouteInformationState(Object? state) {
  return _isJsonSafeRouteInformationState(
    state,
    HashSet<Object>.identity(),
  )
      ? state
      : null;
}

bool _isJsonSafeRouteInformationState(
  Object? value,
  Set<Object> activeContainers,
) {
  if (value == null || value is String || value is bool || value is int) {
    return true;
  }

  if (value is double) {
    return value.isFinite;
  }

  if (value is List) {
    if (!activeContainers.add(value)) return false;
    final isSafe = value.every(
      (element) => _isJsonSafeRouteInformationState(element, activeContainers),
    );
    activeContainers.remove(value);
    return isSafe;
  }

  if (value is Map) {
    if (!activeContainers.add(value)) return false;
    final isSafe = value.entries.every(
      (entry) =>
          entry.key is String &&
          _isJsonSafeRouteInformationState(entry.value, activeContainers),
    );
    activeContainers.remove(value);
    return isSafe;
  }

  return false;
}
