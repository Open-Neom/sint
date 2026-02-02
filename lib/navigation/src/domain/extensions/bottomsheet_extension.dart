
import 'package:flutter/material.dart';
import 'package:sint/core/src/domain/interfaces/sint_interface.dart';
import 'package:sint/navigation/src/domain/extensions/navigation_extensions.dart';
import 'package:sint/navigation/src/ui/bottomsheet/modal_bottomsheet_route.dart';

extension BottomSheetExtension on SintInterface {
  Future<T?> bottomSheet<T>(
      Widget bottomsheet, {
        Color? backgroundColor,
        double? elevation,
        bool persistent = true,
        ShapeBorder? shape,
        Clip? clipBehavior,
        Color? barrierColor,
        bool? ignoreSafeArea,
        bool isScrollControlled = false,
        bool useRootNavigator = false,
        bool isDismissible = true,
        bool enableDrag = true,
        RouteSettings? settings,
        Duration? enterBottomSheetDuration,
        Duration? exitBottomSheetDuration,
        Curve? curve,
      }) {
    return Navigator.of(overlayContext!, rootNavigator: useRootNavigator)
        .push(SintModalBottomSheetRoute<T>(
      builder: (_) => bottomsheet,
      isPersistent: persistent,
      // theme: Theme.of(key.currentContext, shadowThemeOnly: true),
      theme: Theme.of(key.currentContext!),
      isScrollControlled: isScrollControlled,

      barrierLabel: MaterialLocalizations.of(key.currentContext!)
          .modalBarrierDismissLabel,

      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: elevation,
      shape: shape,
      removeTop: ignoreSafeArea ?? true,
      clipBehavior: clipBehavior,
      isDismissible: isDismissible,
      modalBarrierColor: barrierColor,
      settings: settings,
      enableDrag: enableDrag,
      enterBottomSheetDuration:
      enterBottomSheetDuration ?? const Duration(milliseconds: 250),
      exitBottomSheetDuration:
      exitBottomSheetDuration ?? const Duration(milliseconds: 200),
      curve: curve,
    ));
  }
}
