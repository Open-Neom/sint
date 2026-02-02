import 'package:flutter/widgets.dart';
import 'package:sint/navigation/src/router/index.dart';

extension PageArgExtension on BuildContext {
  RouteSettings? get settings {
    return ModalRoute.of(this)!.settings;
  }

  PageSettings? get pageSettings {
    final args = ModalRoute.of(this)?.settings.arguments;
    if (args is PageSettings) {
      return args;
    }
    return null;
  }

  dynamic get arguments {
    final args = settings?.arguments;
    if (args is PageSettings) {
      return args.arguments;
    } else {
      return args;
    }
  }

  Map<String, String> get params {
    final args = settings?.arguments;
    if (args is PageSettings) {
      return args.params;
    } else {
      return {};
    }
  }

  Router get router {
    return Router.of(this);
  }

  String get location {
    final parser = router.routeInformationParser;
    final config = delegate.currentConfiguration;
    return parser?.restoreRouteInformation(config)?.uri.toString() ?? '/';
  }

  SintDelegate get delegate {
    return router.routerDelegate as SintDelegate;
  }
}