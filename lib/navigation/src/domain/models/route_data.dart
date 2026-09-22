import 'package:flutter/material.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:sint/navigation/src/router/sint_page_route.dart';
import 'package:sint/navigation/src/ui/bottomsheet/modal_bottomsheet_route.dart';
import 'package:sint/navigation/src/ui/dialog/dialog_route.dart';
import 'package:sint/navigation/src/utils/navigation_utilities.dart';

/// This is basically a util for rules about 'what a route is'
class RouteData {
  final bool isSintPageRoute;
  final bool isBottomSheet;
  final bool isDialog;
  final String? name;

  @Deprecated(
    'Use isSintPageRoute instead. Part of the legacy GetX route inspection.',
  )
  bool get isGetPageRoute => isSintPageRoute;

  const RouteData({
    required this.name,
    required this.isSintPageRoute,
    required this.isBottomSheet,
    required this.isDialog,
  });

  factory RouteData.ofRoute(Route? route) {
    return RouteData(
      name: extractRouteName(route),
      isSintPageRoute: route is SintPageRoute,
      isDialog:
          route is SintDialogRoute ||
          route is RawDialogRoute ||
          route is DialogRoute,
      isBottomSheet:
          route is SintModalBottomSheetRoute ||
          route is ModalBottomSheetRoute ||
          route is material.ModalBottomSheetRoute,
    );
  }
}
