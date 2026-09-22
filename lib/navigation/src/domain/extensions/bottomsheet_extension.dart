import 'package:flutter/material.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:sint/navigation/src/router/sint_page_route.dart';
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
    if (rootController.config.useStandaloneDesign) {
      final source = overlayContext!;
      final navigator = Navigator.of(source, rootNavigator: useRootNavigator);
      return navigator.push<T>(
        _StandaloneBottomSheetRoute<T>(
          // Preserve the legacy route's content-sized layout. Its persistent
          // argument did not change the route's actual modal presentation.
          builder: (_) => bottomsheet,
          capturedThemes: InheritedTheme.capture(
            from: source,
            to: navigator.context,
          ),
          barrierLabel: material.MaterialLocalizations.of(
            source,
          ).modalBarrierDismissLabel,
          backgroundColor: backgroundColor ?? Colors.transparent,
          elevation: elevation,
          shape: shape,
          clipBehavior: clipBehavior,
          modalBarrierColor: barrierColor,
          isDismissible: isDismissible,
          enableDrag: enableDrag,
          isScrollControlled: isScrollControlled,
          useSafeArea: !(ignoreSafeArea ?? true),
          settings: settings,
          sheetAnimationStyle: AnimationStyle(
            duration:
                enterBottomSheetDuration ?? const Duration(milliseconds: 250),
            reverseDuration:
                exitBottomSheetDuration ?? const Duration(milliseconds: 200),
          ),
          curve: curve,
        ),
      );
    }
    return Navigator.of(overlayContext!, rootNavigator: useRootNavigator).push(
      SintModalBottomSheetRoute<T>(
        builder: (_) => bottomsheet,
        isPersistent: persistent,
        // theme: Theme.of(key.currentContext, shadowThemeOnly: true),
        theme: Theme.of(key.currentContext!),
        isScrollControlled: isScrollControlled,

        barrierLabel: MaterialLocalizations.of(
          key.currentContext!,
        ).modalBarrierDismissLabel,

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
      ),
    );
  }
}

class _StandaloneBottomSheetRoute<T> extends material.ModalBottomSheetRoute<T>
    with PageRouteReportMixin<T> {
  _StandaloneBottomSheetRoute({
    required super.builder,
    required super.isScrollControlled,
    super.capturedThemes,
    super.barrierLabel,
    super.backgroundColor,
    super.elevation,
    super.shape,
    super.clipBehavior,
    super.modalBarrierColor,
    super.isDismissible,
    super.enableDrag,
    super.useSafeArea,
    super.settings,
    super.sheetAnimationStyle,
    this.curve,
  });

  final Curve? curve;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    // Keep the keyboard avoidance provided by the legacy SINT route. Padding
    // outside the route content reduces the sheet's available layout height.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: super.buildPage(context, animation, secondaryAnimation),
    );
  }

  @override
  Animation<double> createAnimation() {
    final animation = super.createAnimation();
    return curve == null
        ? animation
        : CurveTween(curve: curve!).animate(animation);
  }
}
