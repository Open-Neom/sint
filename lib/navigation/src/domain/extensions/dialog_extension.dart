
import 'package:flutter/material.dart';
import 'package:sint/sint.dart';

extension DialogExtension on SintInterface {
  /// Show a dialog.
  /// You can pass a [transitionDuration] and/or [transitionCurve],
  /// overriding the defaults when the dialog shows up and closes.
  /// When the dialog closes, uses those animations in reverse.
  Future<T?> dialog<T>(Widget widget, {
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
    assert(debugCheckHasMaterialLocalizations(context!));

    //  final theme = Theme.of(context, shadowThemeOnly: true);
    final theme = Theme.of(context!);
    return generalDialog<T>(
      pageBuilder: (buildContext, animation, secondaryAnimation) {
        final pageChild = widget;
        Widget dialog = Builder(builder: (context) {
          return Theme(data: theme, child: pageChild);
        });
        if (useSafeArea) {
          dialog = SafeArea(child: dialog);
        }
        return dialog;
      },
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations
          .of(context!)
          .modalBarrierDismissLabel,
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
  Future<T?> generalDialog<T>({required RoutePageBuilder pageBuilder,
    bool barrierDismissible = false,
    String? barrierLabel,
    Color barrierColor = const Color(0x80000000),
    Duration transitionDuration = const Duration(milliseconds: 200),
    RouteTransitionsBuilder? transitionBuilder,
    GlobalKey<NavigatorState>? navigatorKey,
    RouteSettings? routeSettings,
    String? id}) {
    assert(!barrierDismissible || barrierLabel != null);
    final key = navigatorKey ?? Sint
        .nestedKey(id)
        ?.navigatorKey;
    final nav = key?.currentState ??
        Navigator.of(overlayContext!,
            rootNavigator:
            true); //overlay context will always return the root navigator
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
    var leanCancel = onCancel != null || textCancel != null;
    var leanConfirm = onConfirm != null || textConfirm != null;
    actions ??= [];

    if (cancel != null) {
      actions.add(cancel);
    } else {
      if (leanCancel) {
        actions.add(TextButton(
          style: TextButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(
                side: BorderSide(
                    color: buttonColor ?? theme.colorScheme.secondary,
                    width: 2,
                    style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(radius)),
          ),
          onPressed: () {
            if (onCancel == null) {
              //TODO: Close current dialog after api change
              closeAllDialogs();
            } else {
              onCancel.call();
            }
          },
          child: Text(
            textCancel ?? "Cancel",
            style: TextStyle(
                color: cancelTextColor ?? theme.colorScheme.secondary),
          ),
        ));
      }
    }
    if (confirm != null) {
      actions.add(confirm);
    } else {
      if (leanConfirm) {
        actions.add(TextButton(
            style: TextButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: buttonColor ?? theme.colorScheme.secondary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius)),
            ),
            child: Text(
              textConfirm ?? "Ok",
              style: TextStyle(
                  color: confirmTextColor ?? theme.colorScheme.surface),
            ),
            onPressed: () {
              onConfirm?.call();
            }));
      }
    }

    Widget baseAlertDialog = Builder(builder: (context) {
      return AlertDialog(
        titlePadding: titlePadding ?? const EdgeInsets.all(8),
        contentPadding: contentPadding ?? const EdgeInsets.all(8),

        backgroundColor:
        backgroundColor ?? DialogTheme
            .of(context)
            .backgroundColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radius))),
        title: Text(title, textAlign: TextAlign.center, style: titleStyle),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            content ??
                Text(middleText,
                    textAlign: TextAlign.center, style: middleTextStyle),
            const SizedBox(height: 16),
            ButtonTheme(
              minWidth: 78.0,
              height: 34.0,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: actions!,
              ),
            )
          ],
        ),
        // actions: actions, // ?? <Widget>[cancelButton, confirmButton],
        buttonPadding: EdgeInsets.zero,
      );
    });

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
