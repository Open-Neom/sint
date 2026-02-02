// ignore_for_file: overridden_fields

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sint/injection/src/bind.dart';
import 'package:sint/injection/src/domain/interfaces/bindings_interface.dart';
import 'package:sint/navigation/src/domain/enums/prevent_duplicate_handling_mode.dart';
import 'package:sint/navigation/src/domain/interfaces/sint_middleware.dart';
import 'package:sint/navigation/src/domain/models/path_decoded.dart';
import 'package:sint/navigation/src/domain/typedefs/navigation_typedefs.dart';
import 'package:sint/navigation/src/router/index.dart';

class SintPage<T> extends Page<T> {
  final GetPageBuilder page;
  final bool? popGesture;
  final Map<String, String>? parameters;
  final String? title;
  final Transition? transition;
  final Curve curve;
  final bool? participatesInRootNavigator;
  final Alignment? alignment;
  final bool maintainState;
  final bool opaque;
  final double Function(BuildContext context)? gestureWidth;
  final BindingsInterface? binding;
  final List<BindingsInterface> bindings;
  final List<Bind> binds;
  final CustomTransition? customTransition;
  final Duration? transitionDuration;
  final Duration? reverseTransitionDuration;
  final bool fullscreenDialog;
  final bool preventDuplicates;
  final Completer<T?>? completer;

  @override
  final Object? arguments;

  @override
  final String name;

  final bool inheritParentPath;

  final List<SintPage> children;
  final List<SintMiddleware> middlewares;
  final PathDecoded path;
  final SintPage? unknownRoute;
  final bool showCupertinoParallax;

  final PreventDuplicateHandlingMode preventDuplicateHandlingMode;

  static void _defaultPopInvokedHandler(bool didPop, Object? result) {}

  SintPage({
    required this.name,
    required this.page,
    this.title,
    this.participatesInRootNavigator,
    this.gestureWidth,
    this.maintainState = true,
    this.curve = Curves.linear,
    this.alignment,
    this.parameters,
    this.opaque = true,
    this.transitionDuration,
    this.reverseTransitionDuration,
    this.popGesture,
    this.binding,
    this.bindings = const [],
    this.binds = const [],
    this.transition,
    this.customTransition,
    this.fullscreenDialog = false,
    this.children = const <SintPage>[],
    this.middlewares = const [],
    this.unknownRoute,
    this.arguments,
    this.showCupertinoParallax = true,
    this.preventDuplicates = true,
    this.preventDuplicateHandlingMode =
        PreventDuplicateHandlingMode.reorderRoutes,
    this.completer,
    this.inheritParentPath = true,
    LocalKey? key,
    super.canPop,
    super.onPopInvoked = _defaultPopInvokedHandler,
    super.restorationId,
  })  : path = _nameToRegex(name),
        assert(name.startsWith('/'),
            'It is necessary to start route name [$name] with a slash: /$name'),
        super(
          key: key ?? ValueKey(name),
          name: name,
        );

  SintPage<T> copyWith({
    LocalKey? key,
    String? name,
    GetPageBuilder? page,
    bool? popGesture,
    Map<String, String>? parameters,
    String? title,
    Transition? transition,
    Curve? curve,
    Alignment? alignment,
    bool? maintainState,
    bool? opaque,
    List<BindingsInterface>? bindings,
    BindingsInterface? binding,
    List<Bind>? binds,
    CustomTransition? customTransition,
    Duration? transitionDuration,
    Duration? reverseTransitionDuration,
    bool? fullscreenDialog,
    RouteSettings? settings,
    List<SintPage<T>>? children,
    SintPage? unknownRoute,
    List<SintMiddleware>? middlewares,
    bool? preventDuplicates,
    final double Function(BuildContext context)? gestureWidth,
    bool? participatesInRootNavigator,
    Object? arguments,
    bool? showCupertinoParallax,
    Completer<T?>? completer,
    bool? inheritParentPath,
    bool? canPop,
    PopInvokedWithResultCallback<T>? onPopInvoked,
    String? restorationId,
  }) {
    return SintPage(
      key: key ?? this.key,
      participatesInRootNavigator:
          participatesInRootNavigator ?? this.participatesInRootNavigator,
      preventDuplicates: preventDuplicates ?? this.preventDuplicates,
      name: name ?? this.name,
      page: page ?? this.page,
      popGesture: popGesture ?? this.popGesture,
      parameters: parameters ?? this.parameters,
      title: title ?? this.title,
      transition: transition ?? this.transition,
      curve: curve ?? this.curve,
      alignment: alignment ?? this.alignment,
      maintainState: maintainState ?? this.maintainState,
      opaque: opaque ?? this.opaque,
      bindings: bindings ?? this.bindings,
      binds: binds ?? this.binds,
      binding: binding ?? this.binding,
      customTransition: customTransition ?? this.customTransition,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      reverseTransitionDuration:
          reverseTransitionDuration ?? this.reverseTransitionDuration,
      fullscreenDialog: fullscreenDialog ?? this.fullscreenDialog,
      children: children ?? this.children,
      unknownRoute: unknownRoute ?? this.unknownRoute,
      middlewares: middlewares ?? this.middlewares,
      gestureWidth: gestureWidth ?? this.gestureWidth,
      arguments: arguments ?? this.arguments,
      showCupertinoParallax:
          showCupertinoParallax ?? this.showCupertinoParallax,
      completer: completer ?? this.completer,
      inheritParentPath: inheritParentPath ?? this.inheritParentPath,
      canPop: canPop ?? this.canPop,
      onPopInvoked: onPopInvoked ?? this.onPopInvoked,
      restorationId: restorationId ?? restorationId,
    );
  }

  @override
  Route<T> createRoute(BuildContext context) {
    // return GetPageRoute<T>(settings: this, page: page);
    final page = PageRedirect(
      route: this,
      settings: this,
      unknownRoute: unknownRoute,
    ).getPageToRoute<T>(this, unknownRoute, context);

    return page;
  }

  static PathDecoded _nameToRegex(String path) {
    var keys = <String?>[];

    String recursiveReplace(Match pattern) {
      var buffer = StringBuffer('(?:');

      if (pattern[1] != null) buffer.write('.');
      buffer.write('([\\w%+-._~!\$&\'()*,;=:@]+))');
      if (pattern[3] != null) buffer.write('?');

      keys.add(pattern[2]);
      return "$buffer";
    }

    var stringPath = '$path/?'
        .replaceAllMapped(RegExp(r'(\.)?:(\w+)(\?)?'), recursiveReplace)
        .replaceAll('//', '/');

    return PathDecoded(RegExp('^$stringPath\$'), keys);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SintPage<T> && other.key == key;
  }

  @override
  String toString() =>
      '${objectRuntimeType(this, 'Page')}("$name", $key, $arguments)';

  @override
  int get hashCode {
    return key.hashCode;
  }
  
}
