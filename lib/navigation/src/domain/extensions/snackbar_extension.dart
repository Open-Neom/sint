
import 'package:flutter/material.dart';
import 'package:sint/core/src/domain/interfaces/sint_interface.dart';
import 'package:sint/core/src/sint_engine.dart';
import 'package:sint/navigation/src/domain/enums/snackbar_position.dart';
import 'package:sint/navigation/src/domain/enums/snackbar_style.dart';
import 'package:sint/navigation/src/domain/extensions/navigation_extensions.dart';
import 'package:sint/navigation/src/domain/navigation_typedef.dart';
import 'package:sint/navigation/src/ui/snackbar/snackbar.dart';
import 'package:sint/navigation/src/ui/snackbar/snackbar_controller.dart';

extension SnackbarExtension on SintInterface {
  SnackbarController rawSnackbar({
    String? title,
    String? message,
    Widget? titleText,
    Widget? messageText,
    Widget? icon,
    bool instantInit = true,
    bool shouldIconPulse = true,
    double? maxWidth,
    EdgeInsets margin = const EdgeInsets.all(0.0),
    EdgeInsets padding = const EdgeInsets.all(16),
    double borderRadius = 0.0,
    Color? borderColor,
    double borderWidth = 1.0,
    Color backgroundColor = const Color(0xFF303030),
    Color? leftBarIndicatorColor,
    List<BoxShadow>? boxShadows,
    Gradient? backgroundGradient,
    Widget? mainButton,
    OnTap? onTap,
    Duration? duration = const Duration(seconds: 3),
    bool isDismissible = true,
    DismissDirection? dismissDirection,
    bool showProgressIndicator = false,
    AnimationController? progressIndicatorController,
    Color? progressIndicatorBackgroundColor,
    Animation<Color>? progressIndicatorValueColor,
    SnackPosition snackPosition = SnackPosition.bottom,
    SnackStyle snackStyle = SnackStyle.floating,
    Curve forwardAnimationCurve = Curves.easeOutCirc,
    Curve reverseAnimationCurve = Curves.easeOutCirc,
    Duration animationDuration = const Duration(seconds: 1),
    SnackbarStatusCallback? snackbarStatus,
    double barBlur = 0.0,
    double overlayBlur = 0.0,
    Color? overlayColor,
    Form? userInputForm,
  }) {
    final getSnackBar = SintSnackBar(
      snackbarStatus: snackbarStatus,
      title: title,
      message: message,
      titleText: titleText,
      messageText: messageText,
      snackPosition: snackPosition,
      borderRadius: borderRadius,
      margin: margin,
      duration: duration,
      barBlur: barBlur,
      backgroundColor: backgroundColor,
      icon: icon,
      shouldIconPulse: shouldIconPulse,
      maxWidth: maxWidth,
      padding: padding,
      borderColor: borderColor,
      borderWidth: borderWidth,
      leftBarIndicatorColor: leftBarIndicatorColor,
      boxShadows: boxShadows,
      backgroundGradient: backgroundGradient,
      mainButton: mainButton,
      onTap: onTap,
      isDismissible: isDismissible,
      dismissDirection: dismissDirection,
      showProgressIndicator: showProgressIndicator,
      progressIndicatorController: progressIndicatorController,
      progressIndicatorBackgroundColor: progressIndicatorBackgroundColor,
      progressIndicatorValueColor: progressIndicatorValueColor,
      snackStyle: snackStyle,
      forwardAnimationCurve: forwardAnimationCurve,
      reverseAnimationCurve: reverseAnimationCurve,
      animationDuration: animationDuration,
      overlayBlur: overlayBlur,
      overlayColor: overlayColor,
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
        Duration? duration = const Duration(seconds: 3),

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
    final getSnackBar = SintSnackBar(
        snackbarStatus: snackbarStatus,
        titleText: titleText ??
            Text(
              title,
              style: TextStyle(
                color: colorText ?? iconColor ?? Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
        messageText: messageText ??
            Text(
              message,
              style: TextStyle(
                color: colorText ?? iconColor ?? Colors.black,
                fontWeight: FontWeight.w300,
                fontSize: 14,
              ),
            ),
        snackPosition: snackPosition ?? SnackPosition.top,
        borderRadius: borderRadius ?? 15,
        margin: margin ?? const EdgeInsets.symmetric(horizontal: 10),
        duration: duration,
        barBlur: barBlur ?? 7.0,
        backgroundColor: backgroundColor ?? Colors.grey.withValues(alpha: 0.2),
        icon: icon,
        shouldIconPulse: shouldIconPulse ?? true,
        maxWidth: maxWidth,
        padding: padding ?? const EdgeInsets.all(16),
        borderColor: borderColor,
        borderWidth: borderWidth,
        leftBarIndicatorColor: leftBarIndicatorColor,
        boxShadows: boxShadows,
        backgroundGradient: backgroundGradient,
        mainButton: mainButton,
        onTap: onTap,
        onHover: onHover,
        isDismissible: isDismissible ?? true,
        dismissDirection: dismissDirection,
        showProgressIndicator: showProgressIndicator ?? false,
        progressIndicatorController: progressIndicatorController,
        progressIndicatorBackgroundColor: progressIndicatorBackgroundColor,
        progressIndicatorValueColor: progressIndicatorValueColor,
        snackStyle: snackStyle ?? SnackStyle.floating,
        forwardAnimationCurve: forwardAnimationCurve ?? Curves.easeOutCirc,
        reverseAnimationCurve: reverseAnimationCurve ?? Curves.easeOutCirc,
        animationDuration: animationDuration ?? const Duration(seconds: 1),
        overlayBlur: overlayBlur ?? 0.0,
        overlayColor: overlayColor ?? Colors.transparent,
        userInputForm: userInputForm);

    final controller = SnackbarController(getSnackBar);

    if (instantInit) {
      controller.show();
    } else {
      //routing.isSnackbar = true;
      SintEngine.instance.addPostFrameCallback((_) {
        controller.show();
      });
    }
    return controller;
  }
}
