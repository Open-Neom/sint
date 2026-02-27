import 'package:flutter/material.dart';
import 'package:sint/navigation/src/domain/enums/snackbar_position.dart';
import 'package:sint/navigation/src/domain/enums/snackbar_style.dart';

/// Global default style for `Sint.snackbar()` and `Sint.rawSnackbar()`.
///
/// Set once in [SintMaterialApp] and applied to every snackbar call
/// unless overridden at the call site.
///
/// ```dart
/// SintMaterialApp(
///   snackBarStyle: SintSnackBarStyle(
///     backgroundColor: Colors.blueGrey,
///     colorText: Colors.white,
///     snackPosition: SnackPosition.bottom,
///     borderRadius: 12,
///   ),
/// )
/// ```
class SintSnackBarStyle {
  final Color? colorText;
  final Color? backgroundColor;
  final Color? leftBarIndicatorColor;
  final Color? borderColor;
  final double? borderWidth;
  final double? borderRadius;
  final double? maxWidth;
  final double? barBlur;
  final double? overlayBlur;
  final Color? overlayColor;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final SnackPosition? snackPosition;
  final SnackStyle? snackStyle;
  final Duration? duration;
  final Duration? animationDuration;
  final Curve? forwardAnimationCurve;
  final Curve? reverseAnimationCurve;
  final bool? isDismissible;
  final bool? shouldIconPulse;
  final bool? showProgressIndicator;
  final Gradient? backgroundGradient;
  final List<BoxShadow>? boxShadows;
  final Widget? icon;
  final Widget? mainButton;

  const SintSnackBarStyle({
    this.colorText,
    this.backgroundColor,
    this.leftBarIndicatorColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.maxWidth,
    this.barBlur,
    this.overlayBlur,
    this.overlayColor,
    this.margin,
    this.padding,
    this.snackPosition,
    this.snackStyle,
    this.duration,
    this.animationDuration,
    this.forwardAnimationCurve,
    this.reverseAnimationCurve,
    this.isDismissible,
    this.shouldIconPulse,
    this.showProgressIndicator,
    this.backgroundGradient,
    this.boxShadows,
    this.icon,
    this.mainButton,
  });
}
