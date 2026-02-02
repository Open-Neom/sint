import 'package:flutter/widgets.dart';
import 'package:sint/navigation/src/router/sint_page_route.dart';
import 'package:sint/navigation/src/ui/bottomsheet/modal_bottomsheet_route.dart';
import 'package:sint/navigation/src/ui/dialog/dialog_route.dart';

/// Extracts the name of a route based on it's instance type
/// or null if not possible.
String? extractRouteName(Route? route) {
  if (route?.settings.name != null) {
    return route!.settings.name;
  }

  if (route is SintPageRoute) {
    return route.routeName;
  }

  if (route is SintDialogRoute) {
    return 'DIALOG ${route.hashCode}';
  }

  if (route is SintModalBottomSheetRoute) {
    return 'BOTTOMSHEET ${route.hashCode}';
  }

  return null;
}
