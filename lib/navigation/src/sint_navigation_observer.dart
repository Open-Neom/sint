import 'package:flutter/widgets.dart';
import 'package:sint/sint.dart';


class SintNavigationObserver extends NavigatorObserver {
  final Function(Routing?)? routing;

  final Routing? _routeSend;

  SintNavigationObserver([this.routing, this._routeSend]);

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    final currentRoute = RouteData.ofRoute(route);
    final newRoute = RouteData.ofRoute(previousRoute);

    if (currentRoute.isBottomSheet || currentRoute.isDialog) {
      Sint.log("CLOSE ${currentRoute.name}");
    } else if (currentRoute.isGetPageRoute) {
      Sint.log("CLOSE TO ROUTE ${currentRoute.name}");
    }
    if (previousRoute != null) {
      RouterReportManager.instance.reportCurrentRoute(previousRoute);
    }

    // Here we use a 'inverse didPush set', meaning that we use
    // previous route instead of 'route' because this is
    // a 'inverse push'
    _routeSend?.update((value) {
      // Only PageRoute is allowed to change current value
      if (previousRoute is PageRoute) {
        value.current = extractRouteName(previousRoute) ?? '';
        value.previous = newRoute.name ?? '';
      } else if (value.previous.isNotEmpty) {
        value.current = value.previous;
      }

      value.args = previousRoute?.settings.arguments;
      value.route = previousRoute;
      value.isBack = true;
      value.removed = '';
      value.isBottomSheet = newRoute.isBottomSheet;
      value.isDialog = newRoute.isDialog;
    });

    routing?.call(_routeSend);
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    final newRoute = RouteData.ofRoute(route);

    if (newRoute.isBottomSheet || newRoute.isDialog) {
      Sint.log("OPEN ${newRoute.name}");
    } else if (newRoute.isGetPageRoute) {
      Sint.log("GOING TO ROUTE ${newRoute.name}");
    }

    RouterReportManager.instance.reportCurrentRoute(route);
    _routeSend?.update((value) {
      if (route is PageRoute) {
        value.current = newRoute.name ?? '';
      }
      final previousRouteName = extractRouteName(previousRoute);
      if (previousRouteName != null) {
        value.previous = previousRouteName;
      }

      value.args = route.settings.arguments;
      value.route = route;
      value.isBack = false;
      value.removed = '';
      value.isBottomSheet =
          newRoute.isBottomSheet ? true : value.isBottomSheet ?? false;
      value.isDialog = newRoute.isDialog ? true : value.isDialog ?? false;
    });

    if (routing != null) {
      routing!(_routeSend);
    }
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);
    final routeName = extractRouteName(route);
    final currentRoute = RouteData.ofRoute(route);
    final previousRouteName = extractRouteName(previousRoute);

    Sint.log("REMOVING ROUTE $routeName");
    Sint.log("PREVIOUS ROUTE $previousRouteName");

    _routeSend?.update((value) {
      value.route = previousRoute;
      value.isBack = false;
      value.removed = routeName ?? '';
      value.previous = previousRouteName ?? '';
      value.isBottomSheet =
          currentRoute.isBottomSheet ? false : value.isBottomSheet;
      value.isDialog = currentRoute.isDialog ? false : value.isDialog;
    });

    if (route is SintPageRoute) {
      RouterReportManager.instance.reportRouteWillDispose(route);
    }
    routing?.call(_routeSend);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    final newName = extractRouteName(newRoute);
    final oldName = extractRouteName(oldRoute);
    final currentRoute = RouteData.ofRoute(oldRoute);

    Sint.log("REPLACE ROUTE $oldName");
    Sint.log("NEW ROUTE $newName");

    if (newRoute != null) {
      RouterReportManager.instance.reportCurrentRoute(newRoute);
    }

    _routeSend?.update((value) {
      // Only PageRoute is allowed to change current value
      if (newRoute is PageRoute) {
        value.current = newName ?? '';
      }

      value.args = newRoute?.settings.arguments;
      value.route = newRoute;
      value.isBack = false;
      value.removed = '';
      value.previous = oldName ?? '';
      value.isBottomSheet =
          currentRoute.isBottomSheet ? false : value.isBottomSheet;
      value.isDialog = currentRoute.isDialog ? false : value.isDialog;
    });
    if (oldRoute is SintPageRoute) {
      RouterReportManager.instance.reportRouteWillDispose(oldRoute);
    }

    routing?.call(_routeSend);
  }
}
