import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:sint/core/sint_core.dart';
import 'package:sint/navigation/src/domain/enums/transition.dart';
import 'package:sint/navigation/src/domain/extensions/navigation_extensions.dart';
import 'package:sint/navigation/src/router/sint_page_route.dart';
import 'package:sint/navigation/src/ui/sint_root.dart';
import 'package:sint/navigation/src/ui/transitions/circular_reveal_transition.dart';
import 'package:sint/navigation/src/ui/transitions/fade_in_transition.dart';
import 'package:sint/navigation/src/ui/transitions/left_to_right_fade_transition.dart';
import 'package:sint/navigation/src/ui/transitions/right_to_left_fade_transition.dart';
import 'package:sint/navigation/src/ui/transitions/size_transitions.dart';
import 'package:sint/navigation/src/ui/transitions/slide_down_transition.dart';
import 'package:sint/navigation/src/ui/transitions/slide_left_transition.dart';
import 'package:sint/navigation/src/ui/transitions/slide_right_transition.dart';
import 'package:sint/navigation/src/ui/transitions/slide_top_transition.dart';
import 'package:sint/navigation/src/ui/transitions/zoom_in_transition.dart';
import 'package:sint/navigation/src/ui/widgets/sint_back_gesture_controller.dart';
import 'package:sint/navigation/src/ui/widgets/sint_back_gesture_detector.dart';
import 'package:sint/navigation/src/utils/navigation_constants.dart';

mixin SintPageRouteTransitionMixin<T> on PageRoute<T> {
  ValueNotifier<String?>? _previousTitle;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  double Function(BuildContext context)? get gestureWidth;

  /// The title string of the previous [CupertinoPageRoute].
  ///
  /// The [ValueListenable]'s value is readable after the route is installed
  /// onto a [Navigator]. The [ValueListenable] will also notify its listeners
  /// if the value changes (such as by replacing the previous route).
  ///
  /// The [ValueListenable] itself will be null before the route is installed.
  /// Its content value will be null if the previous route has no title or
  /// is not a [CupertinoPageRoute].
  ///
  /// See also:
  ///
  ///  * [ValueListenableBuilder], which can be used to listen and rebuild
  ///    ui based on a ValueListenable.
  ValueListenable<String?> get previousTitle {
    assert(_previousTitle != null, '''
Cannot read the previousTitle for a route that has not yet been installed''');
    return _previousTitle!;
  }

  bool get showCupertinoParallax;

  /// {@template flutter.cupertino.CupertinoRouteTransitionMixin.title}
  /// A title string for this route.
  ///
  /// Used to auto-populate [CupertinoNavigationBar] and
  /// [CupertinoSliverNavigationBar]'s `middle`/`largeTitle` ui when
  /// one is not manually supplied.
  /// {@endtemplate}
  String? get title;

  @override
  Duration get transitionDuration;

  @override
  Duration get reverseTransitionDuration;

  /// Builds the primary contents of the route.
  @protected
  Widget buildContent(BuildContext context);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final child = buildContent(context);
    return Semantics(scopesRoute: true, explicitChildNodes: true, child: child);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return buildPageTransitions<T>(
      this,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    // Don't perform outgoing animation if the next route is a
    // fullscreen dialog.
    return (nextRoute is SintPageRouteTransitionMixin &&
            !nextRoute.fullscreenDialog &&
            nextRoute.showCupertinoParallax) ||
        (nextRoute is CupertinoRouteTransitionMixin &&
            !nextRoute.fullscreenDialog) ||
        (nextRoute is cupertino.CupertinoRouteTransitionMixin &&
            !nextRoute.fullscreenDialog) ||
        (nextRoute is CupertinoSheetRoute && !nextRoute.fullscreenDialog) ||
        (nextRoute is cupertino.CupertinoSheetRoute &&
            !nextRoute.fullscreenDialog);
  }

  @override
  void didChangePrevious(Route<dynamic>? previousRoute) {
    final String? previousTitleString;
    if (previousRoute is cupertino.CupertinoRouteTransitionMixin) {
      previousTitleString = previousRoute.title;
    } else if (previousRoute is CupertinoRouteTransitionMixin) {
      previousTitleString = previousRoute.title;
    } else {
      previousTitleString = null;
    }
    if (_previousTitle == null) {
      _previousTitle = ValueNotifier<String?>(previousTitleString);
    } else {
      _previousTitle!.value = previousTitleString;
    }
    super.didChangePrevious(previousRoute);
  }

  static bool canSwipe(SintPageRoute route) =>
      route.popGesture ??
      (SintRoot.treeInitialized ? Sint.defaultPopGesture : null) ??
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS);

  /// Returns a [CupertinoFullscreenDialogTransition] if `route` is a full
  /// screen dialog, otherwise builds the configured SINT or platform transition.
  static Widget buildPageTransitions<T>(
    PageRoute<T> rawRoute,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child, {
    bool limitedSwipe = false,
    double initialOffset = 0,
  }) {
    final route = rawRoute as SintPageRoute<T>;
    final linearTransition = route.popGestureInProgress;
    final standalone =
        SintRoot.treeInitialized &&
        SintRootState.controller.config.useStandaloneDesign;
    final finalCurve =
        route.curve ??
        (SintRoot.treeInitialized
            ? Sint.defaultTransitionCurve
            : Curves.easeOutQuad);
    final hasCurve = route.curve != null;

    if (route.fullscreenDialog && route.transition == null) {
      final primary = hasCurve
          ? animation.drive(CurveTween(curve: finalCurve))
          : animation;
      return standalone
          ? cupertino.CupertinoFullscreenDialogTransition(
              primaryRouteAnimation: primary,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: linearTransition,
              child: child,
            )
          : CupertinoFullscreenDialogTransition(
              primaryRouteAnimation: primary,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: linearTransition,
              child: child,
            );
    }

    final gestureChild = SintBackGestureDetector<T>(
      popGestureEnable: () =>
          _isPopGestureEnabled(route, canSwipe(route), context),
      onStartPopGesture: () {
        assert(_isPopGestureEnabled(route, canSwipe(route), context));
        return _startPopGesture(route);
      },
      limitedSwipe: limitedSwipe,
      gestureWidth: route.gestureWidth?.call(context) ?? kBackGestureWidth,
      initialOffset: initialOffset,
      child: child,
    );

    if (route.customTransition != null) {
      return route.customTransition!.buildTransition(
        context,
        finalCurve,
        route.alignment,
        animation,
        secondaryAnimation,
        gestureChild,
      );
    }

    /// Apply the curve by default without allocating a leaked CurvedAnimation.
    final iosAnimation = animation;
    final curvedAnimation = animation.drive(CurveTween(curve: finalCurve));
    final effectiveTransition =
        route.transition ??
        (SintRoot.treeInitialized ? Sint.defaultTransition : null);

    switch (effectiveTransition) {
      case Transition.leftToRight:
        return const SlideLeftTransition().buildTransitions(
          context,
          route.curve,
          route.alignment,
          curvedAnimation,
          secondaryAnimation,
          gestureChild,
        );

      case Transition.downToUp:
        return const SlideDownTransition().buildTransitions(
          context,
          route.curve,
          route.alignment,
          curvedAnimation,
          secondaryAnimation,
          gestureChild,
        );

      case Transition.upToDown:
        return const SlideTopTransition().buildTransitions(
          context,
          route.curve,
          route.alignment,
          curvedAnimation,
          secondaryAnimation,
          gestureChild,
        );

      case Transition.noTransition:
        return gestureChild;

      case Transition.rightToLeft:
        return const SlideRightTransition().buildTransitions(
          context,
          route.curve,
          route.alignment,
          curvedAnimation,
          secondaryAnimation,
          gestureChild,
        );

      case Transition.zoom:
        return const ZoomInTransition().buildTransitions(
          context,
          route.curve,
          route.alignment,
          curvedAnimation,
          secondaryAnimation,
          gestureChild,
        );

      case Transition.fadeIn:
        return const FadeInTransition().buildTransitions(
          context,
          route.curve,
          route.alignment,
          curvedAnimation,
          secondaryAnimation,
          gestureChild,
        );

      case Transition.rightToLeftWithFade:
        return const RightToLeftFadeTransition().buildTransitions(
          context,
          route.curve,
          route.alignment,
          curvedAnimation,
          secondaryAnimation,
          gestureChild,
        );

      case Transition.leftToRightWithFade:
        return const LeftToRightFadeTransition().buildTransitions(
          context,
          route.curve,
          route.alignment,
          curvedAnimation,
          secondaryAnimation,
          gestureChild,
        );

      case Transition.cupertino:
        return standalone
            ? cupertino.CupertinoPageTransition(
                primaryRouteAnimation: curvedAnimation,
                secondaryRouteAnimation: secondaryAnimation,
                linearTransition: linearTransition,
                child: gestureChild,
              )
            : CupertinoPageTransition(
                primaryRouteAnimation: curvedAnimation,
                secondaryRouteAnimation: secondaryAnimation,
                linearTransition: linearTransition,
                child: gestureChild,
              );

      case Transition.size:
        return const SizeTransitions().buildTransitions(
          context,
          null,
          route.alignment,
          curvedAnimation,
          secondaryAnimation,
          gestureChild,
        );

      case Transition.fade:
        return standalone
            ? const material.FadeUpwardsPageTransitionsBuilder()
                  .buildTransitions(
                    route,
                    context,
                    curvedAnimation,
                    secondaryAnimation,
                    gestureChild,
                  )
            : const FadeUpwardsPageTransitionsBuilder().buildTransitions(
                route,
                context,
                curvedAnimation,
                secondaryAnimation,
                gestureChild,
              );

      case Transition.topLevel:
        return standalone
            ? const material.ZoomPageTransitionsBuilder().buildTransitions(
                route,
                context,
                curvedAnimation,
                secondaryAnimation,
                gestureChild,
              )
            : const ZoomPageTransitionsBuilder().buildTransitions(
                route,
                context,
                curvedAnimation,
                secondaryAnimation,
                gestureChild,
              );

      case Transition.native:
        return standalone
            ? const material.PageTransitionsTheme().buildTransitions(
                route,
                context,
                iosAnimation,
                secondaryAnimation,
                gestureChild,
              )
            : const PageTransitionsTheme().buildTransitions(
                route,
                context,
                iosAnimation,
                secondaryAnimation,
                gestureChild,
              );

      case Transition.circularReveal:
        return const CircularRevealTransition().buildTransitions(
          context,
          route.curve,
          route.alignment,
          curvedAnimation,
          secondaryAnimation,
          gestureChild,
        );

      default:
        final customTransition = SintRoot.treeInitialized
            ? SintRoot.of(context).config.customTransition
            : null;

        if (customTransition != null) {
          return customTransition.buildTransition(
            context,
            route.curve,
            route.alignment,
            curvedAnimation,
            secondaryAnimation,
            child,
          );
        }

        if (standalone) {
          return material.Theme.of(context).pageTransitionsTheme
              .buildTransitions(
                route,
                context,
                iosAnimation,
                secondaryAnimation,
                gestureChild,
              );
        }

        return Theme.of(context).pageTransitionsTheme.buildTransitions(
          route,
          context,
          iosAnimation,
          secondaryAnimation,
          gestureChild,
        );
    }
  }

  /// True if an iOS-style back swipe pop gesture is currently
  /// underway for the current modal route in [context].
  static bool isPopGestureInProgress(BuildContext context) {
    final route = ModalRoute.of(context)!;
    return route.navigator!.userGestureInProgress;
  }

  static bool _isPopGestureEnabled<T>(
    PageRoute<T> route,
    bool canSwipe,
    BuildContext context,
  ) {
    if (route.isFirst) return false;
    if (route.willHandlePopInternally) return false;
    if (route.popDisposition == RoutePopDisposition.doNotPop) return false;
    if (route.fullscreenDialog) return false;
    if (route.animation!.status != AnimationStatus.completed) return false;
    if (route.secondaryAnimation!.status != AnimationStatus.dismissed) {
      return false;
    }
    if (SintPageRouteTransitionMixin.isPopGestureInProgress(context)) {
      return false;
    }
    if (!canSwipe) return false;
    return true;
  }

  static SintBackGestureController<T> _startPopGesture<T>(PageRoute<T> route) {
    return SintBackGestureController<T>(
      navigator: route.navigator!,
      controller: route.controller!,
    );
  }
}
