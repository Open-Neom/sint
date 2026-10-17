import 'package:flutter/material.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:sint/core/sint_core.dart';
import 'package:sint/navigation/src/ui/dialog/dialog_route.dart';
import 'package:sint/navigation/src/domain/extensions/navigation_extensions.dart';

extension DialogExtension on SintInterface {
  /// Show a dialog.
  /// You can pass a [transitionDuration] and/or [transitionCurve],
  /// overriding the defaults when the dialog shows up and closes.
  /// When the dialog closes, uses those animations in reverse.
  Future<T?> dialog<T>(
    Widget widget, {
    bool barrierDismissible = true,
    Color? barrierColor,
    bool useSafeArea = true,
    GlobalKey<NavigatorState>? navigatorKey,
    Object? arguments,
    Duration? transitionDuration,
    Curve? transitionCurve,
    String? name,
    RouteSettings? routeSettings,
    String? id,
  }) {
    final standalone = rootController.config.useStandaloneDesign;
    final themes = InheritedTheme.capture(from: context!, to: null);
    final barrierLabel = standalone
        ? material.MaterialLocalizations.of(context!).modalBarrierDismissLabel
        : MaterialLocalizations.of(context!).modalBarrierDismissLabel;
    return generalDialog<T>(
      pageBuilder: (buildContext, animation, secondaryAnimation) {
        Widget dialog = themes.wrap(widget);
        if (useSafeArea) {
          dialog = SafeArea(child: dialog);
        }
        return dialog;
      },
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      barrierColor: barrierColor ?? Colors.black54,
      transitionDuration: transitionDuration ?? defaultDialogTransitionDuration,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: transitionCurve ?? defaultDialogTransitionCurve,
          ),
          child: child,
        );
      },
      navigatorKey: navigatorKey,
      routeSettings:
          routeSettings ?? RouteSettings(arguments: arguments, name: name),
      id: id,
    );
  }

  /// Api from showGeneralDialog with no context
  Future<T?> generalDialog<T>({
    required RoutePageBuilder pageBuilder,
    bool barrierDismissible = false,
    String? barrierLabel,
    Color barrierColor = const Color(0x80000000),
    Duration transitionDuration = const Duration(milliseconds: 200),
    RouteTransitionsBuilder? transitionBuilder,
    GlobalKey<NavigatorState>? navigatorKey,
    RouteSettings? routeSettings,
    String? id,
  }) {
    assert(!barrierDismissible || barrierLabel != null);
    final key = navigatorKey ?? Sint.nestedKey(id)?.navigatorKey;
    final nav =
        key?.currentState ??
        Navigator.of(
          overlayContext!,
          rootNavigator: true,
        ); //overlay context will always return the root navigator
    return nav.push<T>(
      SintDialogRoute<T>(
        pageBuilder: pageBuilder,
        barrierDismissible: barrierDismissible,
        barrierLabel: barrierLabel,
        barrierColor: barrierColor,
        transitionDuration: transitionDuration,
        transitionBuilder: transitionBuilder,
        settings: routeSettings,
      ),
    );
  }

  /// Custom UI Dialog.
  Future<T?> defaultDialog<T>({
    String title = "Alert",
    EdgeInsetsGeometry? titlePadding,
    TextStyle? titleStyle,
    Widget? content,
    String? id,
    EdgeInsetsGeometry? contentPadding,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    VoidCallback? onCustom,
    Color? cancelTextColor,
    Color? confirmTextColor,
    String? textConfirm,
    String? textCancel,
    String? textCustom,
    Widget? confirm,
    Widget? cancel,
    Widget? custom,
    Color? backgroundColor,
    bool barrierDismissible = true,
    Color? buttonColor,
    String middleText = "\n",
    TextStyle? middleTextStyle,
    double radius = 20.0,
    //   ThemeData themeData,
    List<Widget>? actions,

    // onWillPop Scope
    PopInvokedWithResultCallback<T>? onWillPop,

    // the navigator used to push the dialog
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    final standalone = rootController.config.useStandaloneDesign;
    final secondaryColor = standalone
        ? materialTheme.colorScheme.secondary
        : theme.colorScheme.secondary;
    final surfaceColor = standalone
        ? materialTheme.colorScheme.surface
        : theme.colorScheme.surface;
    var leanCancel = onCancel != null || textCancel != null;
    var leanConfirm = onConfirm != null || textConfirm != null;
    actions ??= [];

    if (cancel != null) {
      actions.add(cancel);
    } else {
      if (leanCancel) {
        void handleCancel() {
          if (onCancel == null) {
            closeAllDialogs();
          } else {
            onCancel.call();
          }
        }

        final cancelChild = Text(
          textCancel ?? "Cancel",
          style: TextStyle(color: cancelTextColor ?? secondaryColor),
        );
        final cancelShape = RoundedRectangleBorder(
          side: BorderSide(
            color: buttonColor ?? secondaryColor,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(radius),
        );

        actions.add(
          standalone
              ? material.TextButton(
                  style: material.TextButton.styleFrom(
                    tapTargetSize: material.MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    shape: cancelShape,
                  ),
                  onPressed: handleCancel,
                  child: cancelChild,
                )
              : TextButton(
                  style: TextButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    shape: cancelShape,
                  ),
                  onPressed: handleCancel,
                  child: cancelChild,
                ),
        );
      }
    }
    if (confirm != null) {
      actions.add(confirm);
    } else {
      if (leanConfirm) {
        final confirmChild = Text(
          textConfirm ?? "Ok",
          style: TextStyle(color: confirmTextColor ?? surfaceColor),
        );
        final confirmShape = RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        );

        actions.add(
          standalone
              ? material.TextButton(
                  style: material.TextButton.styleFrom(
                    tapTargetSize: material.MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: buttonColor ?? secondaryColor,
                    shape: confirmShape,
                  ),
                  onPressed: () {
                    onConfirm?.call();
                  },
                  child: confirmChild,
                )
              : TextButton(
                  style: TextButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: buttonColor ?? secondaryColor,
                    shape: confirmShape,
                  ),
                  onPressed: () {
                    onConfirm?.call();
                  },
                  child: confirmChild,
                ),
        );
      }
    }

    Widget baseAlertDialog = Builder(
      builder: (context) {
        final dialogShape = RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radius)),
        );
        final dialogTitle = Text(
          title,
          textAlign: TextAlign.center,
          style: titleStyle,
        );
        final actionsWrap = Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: actions!,
        );
        final dialogContent = Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            content ??
                Text(
                  middleText,
                  textAlign: TextAlign.center,
                  style: middleTextStyle,
                ),
            const SizedBox(height: 16),
            standalone
                ? material.ButtonTheme(
                    minWidth: 78.0,
                    height: 34.0,
                    child: actionsWrap,
                  )
                : ButtonTheme(
                    minWidth: 78.0,
                    height: 34.0,
                    child: actionsWrap,
                  ),
          ],
        );

        if (standalone) {
          return material.AlertDialog(
            titlePadding: titlePadding ?? const EdgeInsets.all(8),
            contentPadding: contentPadding ?? const EdgeInsets.all(8),
            backgroundColor:
                backgroundColor ??
                material.DialogTheme.of(context).backgroundColor,
            shape: dialogShape,
            title: dialogTitle,
            content: dialogContent,
            buttonPadding: EdgeInsets.zero,
          );
        }
        return AlertDialog(
          titlePadding: titlePadding ?? const EdgeInsets.all(8),
          contentPadding: contentPadding ?? const EdgeInsets.all(8),
          backgroundColor:
              backgroundColor ?? DialogTheme.of(context).backgroundColor,
          shape: dialogShape,
          title: dialogTitle,
          content: dialogContent,
          buttonPadding: EdgeInsets.zero,
        );
      },
    );

    return dialog<T>(
      onWillPop != null
          ? PopScope<T>(
              onPopInvokedWithResult: (didPop, result) =>
                  onWillPop(didPop, result),
              // onPopInvoked: onWillPop,
              child: baseAlertDialog,
            )
          : baseAlertDialog,
      barrierDismissible: barrierDismissible,
      navigatorKey: navigatorKey,
      id: id,
    );
  }
}
