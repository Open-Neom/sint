
import 'package:flutter/material.dart';
import 'package:sint/core/src/domain/interfaces/sint_interface.dart';
import 'package:sint/core/src/sint_engine.dart';
import 'package:sint/navigation/src/domain/enums/snackbar_position.dart';
import 'package:sint/navigation/src/domain/enums/snackbar_style.dart';
import 'package:sint/navigation/src/domain/extensions/navigation_extensions.dart';
import 'package:sint/navigation/src/domain/models/sint_snackbar_style.dart';
import 'package:sint/navigation/src/domain/navigation_typedef.dart';
import 'package:sint/navigation/src/ui/snackbar/snackbar.dart';
import 'package:sint/navigation/src/ui/snackbar/snackbar_controller.dart';

extension SnackbarExtension on SintInterface {

  /// Resolves the global [SintSnackBarStyle] from [ConfigData], or null.
  SintSnackBarStyle? get _globalStyle => rootController.config.snackBarStyle;

  SnackbarController rawSnackbar({
    String? title,
    String? message,
    Widget? titleText,
    Widget? messageText,
    Widget? icon,
    bool instantInit = true,
    bool? shouldIconPulse,
    double? maxWidth,
    EdgeInsets? margin,
    EdgeInsets? padding,
    double? borderRadius,
    Color? borderColor,
    double? borderWidth,
    Color? backgroundColor,
    Color? leftBarIndicatorColor,
    List<BoxShadow>? boxShadows,
    Gradient? backgroundGradient,
    Widget? mainButton,
    OnTap? onTap,
    Duration? duration,
    bool? isDismissible,
    DismissDirection? dismissDirection,
    bool? showProgressIndicator,
    AnimationController? progressIndicatorController,
    Color? progressIndicatorBackgroundColor,
    Animation<Color>? progressIndicatorValueColor,
    SnackPosition? snackPosition,
    SnackStyle? snackStyle,
    Curve? forwardAnimationCurve,
    Curve? reverseAnimationCurve,
    Duration? animationDuration,
    SnackbarStatusCallback? snackbarStatus,
    double? barBlur,
    double? overlayBlur,
    Color? overlayColor,
    Form? userInputForm,
  }) {
    final s = _globalStyle;

    final getSnackBar = SintSnackBar(
      snackbarStatus: snackbarStatus,
      title: title,
      message: message,
      titleText: titleText,
      messageText: messageText,
      snackPosition: snackPosition ?? s?.snackPosition ?? SnackPosition.bottom,
      borderRadius: borderRadius ?? s?.borderRadius ?? 0.0,
      margin: margin ?? s?.margin ?? const EdgeInsets.all(0.0),
      duration: duration ?? s?.duration ?? const Duration(seconds: 3),
      barBlur: barBlur ?? s?.barBlur ?? 0.0,
      backgroundColor: backgroundColor ?? s?.backgroundColor ?? const Color(0xFF303030),
      icon: icon ?? s?.icon,
      shouldIconPulse: shouldIconPulse ?? s?.shouldIconPulse ?? true,
      maxWidth: maxWidth ?? s?.maxWidth,
      padding: padding ?? s?.padding ?? const EdgeInsets.all(16),
      borderColor: borderColor ?? s?.borderColor,
      borderWidth: borderWidth ?? s?.borderWidth ?? 1.0,
      leftBarIndicatorColor: leftBarIndicatorColor ?? s?.leftBarIndicatorColor,
      boxShadows: boxShadows ?? s?.boxShadows,
      backgroundGradient: backgroundGradient ?? s?.backgroundGradient,
      mainButton: mainButton ?? s?.mainButton,
      onTap: onTap,
      isDismissible: isDismissible ?? s?.isDismissible ?? true,
      dismissDirection: dismissDirection,
      showProgressIndicator: showProgressIndicator ?? s?.showProgressIndicator ?? false,
      progressIndicatorController: progressIndicatorController,
      progressIndicatorBackgroundColor: progressIndicatorBackgroundColor,
      progressIndicatorValueColor: progressIndicatorValueColor,
      snackStyle: snackStyle ?? s?.snackStyle ?? SnackStyle.floating,
      forwardAnimationCurve: forwardAnimationCurve ?? s?.forwardAnimationCurve ?? Curves.easeOutCirc,
      reverseAnimationCurve: reverseAnimationCurve ?? s?.reverseAnimationCurve ?? Curves.easeOutCirc,
      animationDuration: animationDuration ?? s?.animationDuration ?? const Duration(seconds: 1),
      overlayBlur: overlayBlur ?? s?.overlayBlur ?? 0.0,
      overlayColor: overlayColor ?? s?.overlayColor,
      userInputForm: userInputForm,
    );

    final controller = SnackbarController(getSnackBar);

    if (instantInit) {
      controller.show();
    } else {
      SintEngine.instance.addPostFrameCallback((_) {
        controller.show();
      });
    }
    return controller;
  }

  SnackbarController showSnackbar(SintSnackBar snackbar) {
    final controller = SnackbarController(snackbar);
    controller.show();
    return controller;
  }

  SnackbarController snackbar(
      String title,
      String message, {
        Color? colorText,
        Duration? duration,

        /// with instantInit = false you can put snackbar on initState
        bool instantInit = true,
        SnackPosition? snackPosition,
        Widget? titleText,
        Widget? messageText,
        Widget? icon,
        bool? shouldIconPulse,
        double? maxWidth,
        EdgeInsets? margin,
        EdgeInsets? padding,
        double? borderRadius,
        Color? borderColor,
        double? borderWidth,
        Color? backgroundColor,
        Color? leftBarIndicatorColor,
        List<BoxShadow>? boxShadows,
        Gradient? backgroundGradient,
        TextButton? mainButton,
        OnTap? onTap,
        OnHover? onHover,
        bool? isDismissible,
        bool? showProgressIndicator,
        DismissDirection? dismissDirection,
        AnimationController? progressIndicatorController,
        Color? progressIndicatorBackgroundColor,
        Animation<Color>? progressIndicatorValueColor,
        SnackStyle? snackStyle,
        Curve? forwardAnimationCurve,
        Curve? reverseAnimationCurve,
        Duration? animationDuration,
        double? barBlur,
        double? overlayBlur,
        SnackbarStatusCallback? snackbarStatus,
        Color? overlayColor,
        Form? userInputForm,
      }) {
    // Cascade: call-site param > global SintSnackBarStyle > hardcoded default
    final s = _globalStyle;
    final resolvedColorText = colorText ?? s?.colorText ?? iconColor ?? Colors.black;

    final getSnackBar = SintSnackBar(
        snackbarStatus: snackbarStatus,
        titleText: titleText ??
            Text(
              title,
              style: TextStyle(
                color: resolvedColorText,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
        messageText: messageText ??
            Text(
              message,
              style: TextStyle(
                color: resolvedColorText,
                fontWeight: FontWeight.w300,
                fontSize: 14,
              ),
            ),
        snackPosition: snackPosition ?? s?.snackPosition ?? SnackPosition.top,
        borderRadius: borderRadius ?? s?.borderRadius ?? 15,
        margin: margin ?? s?.margin ?? const EdgeInsets.symmetric(horizontal: 10),
        duration: duration ?? s?.duration ?? const Duration(seconds: 3),
        barBlur: barBlur ?? s?.barBlur ?? 7.0,
        backgroundColor: backgroundColor ?? s?.backgroundColor ?? Colors.grey.withValues(alpha: 0.2),
        icon: icon ?? s?.icon,
        shouldIconPulse: shouldIconPulse ?? s?.shouldIconPulse ?? true,
        maxWidth: maxWidth ?? s?.maxWidth,
        padding: padding ?? s?.padding ?? const EdgeInsets.all(16),
        borderColor: borderColor ?? s?.borderColor,
        borderWidth: borderWidth ?? s?.borderWidth,
        leftBarIndicatorColor: leftBarIndicatorColor ?? s?.leftBarIndicatorColor,
        boxShadows: boxShadows ?? s?.boxShadows,
        backgroundGradient: backgroundGradient ?? s?.backgroundGradient,
        mainButton: mainButton ?? s?.mainButton,
        onTap: onTap,
        onHover: onHover,
        isDismissible: isDismissible ?? s?.isDismissible ?? true,
        dismissDirection: dismissDirection,
        showProgressIndicator: showProgressIndicator ?? s?.showProgressIndicator ?? false,
        progressIndicatorController: progressIndicatorController,
        progressIndicatorBackgroundColor: progressIndicatorBackgroundColor,
        progressIndicatorValueColor: progressIndicatorValueColor,
        snackStyle: snackStyle ?? s?.snackStyle ?? SnackStyle.floating,
        forwardAnimationCurve: forwardAnimationCurve ?? s?.forwardAnimationCurve ?? Curves.easeOutCirc,
        reverseAnimationCurve: reverseAnimationCurve ?? s?.reverseAnimationCurve ?? Curves.easeOutCirc,
        animationDuration: animationDuration ?? s?.animationDuration ?? const Duration(seconds: 1),
        overlayBlur: overlayBlur ?? s?.overlayBlur ?? 0.0,
        overlayColor: overlayColor ?? s?.overlayColor ?? Colors.transparent,
        userInputForm: userInputForm);

    final controller = SnackbarController(getSnackBar);

    if (instantInit) {
      controller.show();
    } else {
      SintEngine.instance.addPostFrameCallback((_) {
        controller.show();
      });
    }
    return controller;
  }
}
