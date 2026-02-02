import 'package:flutter/widgets.dart';
import 'package:sint/injection/src/domain/interfaces/bindings_interface.dart';
import 'package:sint/navigation/src/domain/enums/pop_mode.dart';
import 'package:sint/navigation/src/router/sint_page.dart';

import '../enums/transition.dart';

mixin SintNavigationMixin {
  Future<T?> to<T>(
    Widget Function() page, {
    bool? opaque,
    Transition? transition,
    Curve? curve,
    Duration? duration,
    String? id,
    String? routeName,
    bool fullscreenDialog = false,
    dynamic arguments,
    List<BindingsInterface> bindings = const [],
    bool preventDuplicates = true,
    bool? popGesture,
    bool showCupertinoParallax = true,
    double Function(BuildContext context)? gestureWidth,
  });

  Future<void> popModeUntil(
    String fullRoute, {
    PopMode popMode = PopMode.history,
  });

  Future<T?> off<T>(
    Widget Function() page, {
    bool? opaque,
    Transition? transition,
    Curve? curve,
    Duration? duration,
    String? id,
    String? routeName,
    bool fullscreenDialog = false,
    dynamic arguments,
    List<BindingsInterface> bindings = const [],
    bool preventDuplicates = true,
    bool? popGesture,
    bool showCupertinoParallax = true,
    double Function(BuildContext context)? gestureWidth,
  });

  Future<T?>? offAll<T>(
    Widget Function() page, {
    bool Function(SintPage route)? predicate,
    bool opaque = true,
    bool? popGesture,
    String? id,
    String? routeName,
    dynamic arguments,
    List<BindingsInterface> bindings = const [],
    bool fullscreenDialog = false,
    Transition? transition,
    Curve? curve,
    Duration? duration,
    bool showCupertinoParallax = true,
    double Function(BuildContext context)? gestureWidth,
  });

  Future<T?> toNamed<T>(
    String page, {
    dynamic arguments,
    String? id,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
  });

  Future<T?> offNamed<T>(
    String page, {
    dynamic arguments,
    String? id,
    Map<String, String>? parameters,
  });

  Future<T?>? offAllNamed<T>(
    String newRouteName, {
    dynamic arguments,
    String? id,
    Map<String, String>? parameters,
  });

  Future<T?>? offNamedUntil<T>(
    String page, {
    bool Function(SintPage route)? predicate,
    dynamic arguments,
    String? id,
    Map<String, String>? parameters,
  });

  Future<T?> toNamedAndOffUntil<T>(
    String page,
    bool Function(SintPage) predicate, [
    Object? data,
  ]);

  Future<T?> offUntil<T>(
    Widget Function() page,
    bool Function(SintPage) predicate, [
    Object? arguments,
  ]);

  void removeRoute<T>(String name);

  void back<T>([T? result]);

  Future<R?> backAndtoNamed<T, R>(String page, {T? result, Object? arguments});

  void backUntil(bool Function(SintPage) predicate);

  void goToUnknownPage([bool clearPages = true]);
}
