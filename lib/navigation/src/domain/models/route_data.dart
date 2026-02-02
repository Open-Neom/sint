import 'package:flutter/material.dart';
import 'package:sint/navigation/src/router/sint_page_route.dart';
import 'package:sint/navigation/src/ui/bottomsheet/modal_bottomsheet_route.dart';
import 'package:sint/navigation/src/ui/dialog/dialog_route.dart';
import 'package:sint/navigation/src/utils/navigation_utilities.dart';

/// This is basically a util for rules about 'what a route is'
class RouteData {
  final bool isGetPageRoute;
  final bool isBottomSheet;
  final bool isDialog;
  final String? name;

  const RouteData({
    required this.name,
    required this.isGetPageRoute,
    required this.isBottomSheet,
    required this.isDialog,
  });

  factory RouteData.ofRoute(Route? route) {
    return RouteData(
      name: extractRouteName(route),
      isGetPageRoute: route is SintPageRoute,
      isDialog: route is SintDialogRoute,
      isBottomSheet: route is SintModalBottomSheetRoute,
    );
  }
}