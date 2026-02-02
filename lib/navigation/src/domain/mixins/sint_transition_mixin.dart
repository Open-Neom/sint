import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sint/navigation/src/ui/widgets/sint_back_gesture_controller.dart';

import '../../../../sint.dart';

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
    assert(
      _previousTitle != null,
      '''
Cannot read the previousTitle for a route that has not yet been installed''',
    );
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
  // A relatively rigorous eyeball estimation.
  Duration get transitionDuration;

  @override
  Duration get reverseTransitionDuration;

  /// Builds the primary contents of the route.
  @protected
  Widget buildContent(BuildContext context);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    final child = buildContent(context);
    final Widget result = Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: child,
    );
    return result;
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return buildPageTransitions<T>(
        this, context, animation, secondaryAnimation, child);
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
        (nextRoute is CupertinoSheetRoute &&
            !nextRoute.fullscreenDialog);
  }

  @override
  void didChangePrevious(Route<dynamic>? previousRoute) {
    final previousTitleString = previousRoute is CupertinoRouteTransitionMixin
        ? previousRoute.title
        : null;
    if (_previousTitle == null) {
      _previousTitle = ValueNotifier<String?>(previousTitleString);
    } else {
      _previousTitle!.value = previousTitleString;
    }
    super.didChangePrevious(previousRoute);
  }

  static bool canSwipe(SintPageRoute route) =>
      route.popGesture ?? Sint.defaultPopGesture ?? Platform.isIOS;

  /// Returns a [CupertinoFullscreenDialogTransition] if [route] is a full
  /// screen dialog, otherwise a [CupertinoPageTransition] is returned.
  ///
  /// Used by [CupertinoPageRoute.buildTransitions].
  ///
  /// This method can be applied to any [PageRoute], not just
  /// [CupertinoPageRoute]. It's typically used to provide a Cupertino style
  /// horizontal transition for material ui when the target platform
  /// is [TargetPlatform.iOS].
  ///
  /// See also:
  ///
  ///  * [CupertinoPageTransitionsBuilder], which uses this method to define a
  ///    [PageTransitionsBuilder] for the [PageTransitionsTheme].
  static Widget buildPageTransitions<T>(
    PageRoute<T> rawRoute,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child, {
    bool limitedSwipe = false,
    double initialOffset = 0,
  }) {
    // Check if the route has an animation that's currently participating
    // in a back swipe gesture.
    //
    // In the middle of a back gesture drag, let the transition be linear to
    // match finger motions.
    final route = rawRoute as SintPageRoute<T>;
    final linearTransition = route.popGestureInProgress;
    final finalCurve = route.curve ?? Sint.defaultTransitionCurve;
    final hasCurve = route.curve != null;
    if (route.fullscreenDialog && route.transition == null) {
      return CupertinoFullscreenDialogTransition(
        primaryRouteAnimation: hasCurve
            ? CurvedAnimation(parent: animation, curve: finalCurve)
            : animation,
        secondaryRouteAnimation: secondaryAnimation,
        linearTransition: linearTransition,
        child: child,
      );
    } else {
      if (route.customTransition != null) {
        return route.customTransition!.buildTransition(
          context,
          finalCurve,
          route.alignment,
          animation,
          secondaryAnimation,
          SintBackGestureDetector<T>(
            popGestureEnable: () =>
                _isPopGestureEnabled(route, canSwipe(route), context),
            onStartPopGesture: () {
              assert(_isPopGestureEnabled(route, canSwipe(route), context));
              return _startPopGesture(route);
            },
            limitedSwipe: limitedSwipe,
            gestureWidth:
                route.gestureWidth?.call(context) ?? kBackGestureWidth,
            initialOffset: initialOffset,
            child: child,
          ),
        );
      }

      /// Apply the curve by default...
      final iosAnimation = animation;
      animation = CurvedAnimation(parent: animation, curve: finalCurve);

      switch (route.transition ?? Sint.defaultTransition) {
        case Transition.leftToRight:
          return SlideLeftTransition().buildTransitions(
              context,
              route.curve,
              route.alignment,
              animation,
              secondaryAnimation,
              SintBackGestureDetector<T>(
                popGestureEnable: () =>
                    _isPopGestureEnabled(route, canSwipe(route), context),
                onStartPopGesture: () {
                  assert(_isPopGestureEnabled(route, canSwipe(route), context));
                  return _startPopGesture(route);
                },
                limitedSwipe: limitedSwipe,
                gestureWidth:
                    route.gestureWidth?.call(context) ?? kBackGestureWidth,
                initialOffset: initialOffset,
                child: child,
              ));

        case Transition.downToUp:
          return SlideDownTransition().buildTransitions(
              context,
              route.curve,
              route.alignment,
              animation,
              secondaryAnimation,
              SintBackGestureDetector<T>(
                popGestureEnable: () =>
                    _isPopGestureEnabled(route, canSwipe(route), context),
                onStartPopGesture: () {
                  assert(_isPopGestureEnabled(route, canSwipe(route), context));
                  return _startPopGesture(route);
                },
                limitedSwipe: limitedSwipe,
                gestureWidth:
                    route.gestureWidth?.call(context) ?? kBackGestureWidth,
                initialOffset: initialOffset,
                child: child,
              ));

        case Transition.upToDown:
          return SlideTopTransition().buildTransitions(
              context,
              route.curve,
              route.alignment,
              animation,
              secondaryAnimation,
              SintBackGestureDetector<T>(
                popGestureEnable: () =>
                    _isPopGestureEnabled(route, canSwipe(route), context),
                onStartPopGesture: () {
                  assert(_isPopGestureEnabled(route, canSwipe(route), context));
                  return _startPopGesture(route);
                },
                limitedSwipe: limitedSwipe,
                gestureWidth:
                    route.gestureWidth?.call(context) ?? kBackGestureWidth,
                initialOffset: initialOffset,
                child: child,
              ));

        case Transition.noTransition:
          return SintBackGestureDetector<T>(
            popGestureEnable: () =>
                _isPopGestureEnabled(route, canSwipe(route), context),
            onStartPopGesture: () {
              assert(_isPopGestureEnabled(route, canSwipe(route), context));
              return _startPopGesture(route);
            },
            limitedSwipe: limitedSwipe,
            gestureWidth:
                route.gestureWidth?.call(context) ?? kBackGestureWidth,
            initialOffset: initialOffset,
            child: child,
          );

        case Transition.rightToLeft:
          return SlideRightTransition().buildTransitions(
              context,
              route.curve,
              route.alignment,
              animation,
              secondaryAnimation,
              SintBackGestureDetector<T>(
                popGestureEnable: () =>
                    _isPopGestureEnabled(route, canSwipe(route), context),
                onStartPopGesture: () {
                  assert(_isPopGestureEnabled(route, canSwipe(route), context));
                  return _startPopGesture(route);
                },
                limitedSwipe: limitedSwipe,
                gestureWidth:
                    route.gestureWidth?.call(context) ?? kBackGestureWidth,
                initialOffset: initialOffset,
                child: child,
              ));

        case Transition.zoom:
          return ZoomInTransition().buildTransitions(
              context,
              route.curve,
              route.alignment,
              animation,
              secondaryAnimation,
              SintBackGestureDetector<T>(
                popGestureEnable: () =>
                    _isPopGestureEnabled(route, canSwipe(route), context),
                onStartPopGesture: () {
                  assert(_isPopGestureEnabled(route, canSwipe(route), context));
                  return _startPopGesture(route);
                },
                limitedSwipe: limitedSwipe,
                gestureWidth:
                    route.gestureWidth?.call(context) ?? kBackGestureWidth,
                initialOffset: initialOffset,
                child: child,
              ));

        case Transition.fadeIn:
          return FadeInTransition().buildTransitions(
              context,
              route.curve,
              route.alignment,
              animation,
              secondaryAnimation,
              SintBackGestureDetector<T>(
                popGestureEnable: () =>
                    _isPopGestureEnabled(route, canSwipe(route), context),
                onStartPopGesture: () {
                  assert(_isPopGestureEnabled(route, canSwipe(route), context));
                  return _startPopGesture(route);
                },
                limitedSwipe: limitedSwipe,
                gestureWidth:
                    route.gestureWidth?.call(context) ?? kBackGestureWidth,
                initialOffset: initialOffset,
                child: child,
              ));

        case Transition.rightToLeftWithFade:
          return RightToLeftFadeTransition().buildTransitions(
              context,
              route.curve,
              route.alignment,
              animation,
              secondaryAnimation,
              SintBackGestureDetector<T>(
                popGestureEnable: () =>
                    _isPopGestureEnabled(route, canSwipe(route), context),
                onStartPopGesture: () {
                  assert(_isPopGestureEnabled(route, canSwipe(route), context));
                  return _startPopGesture(route);
                },
                limitedSwipe: limitedSwipe,
                gestureWidth:
                    route.gestureWidth?.call(context) ?? kBackGestureWidth,
                initialOffset: initialOffset,
                child: child,
              ));

        case Transition.leftToRightWithFade:
          return LeftToRightFadeTransition().buildTransitions(
              context,
              route.curve,
              route.alignment,
              animation,
              secondaryAnimation,
              SintBackGestureDetector<T>(
                popGestureEnable: () =>
                    _isPopGestureEnabled(route, canSwipe(route), context),
                onStartPopGesture: () {
                  assert(_isPopGestureEnabled(route, canSwipe(route), context));
                  return _startPopGesture(route);
                },
                limitedSwipe: limitedSwipe,
                gestureWidth:
                    route.gestureWidth?.call(context) ?? kBackGestureWidth,
                initialOffset: initialOffset,
                child: child,
              ));

        case Transition.cupertino:
          return CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: linearTransition,
              child: SintBackGestureDetector<T>(
                popGestureEnable: () =>
                    _isPopGestureEnabled(route, canSwipe(route), context),
                onStartPopGesture: () {
                  assert(_isPopGestureEnabled(route, canSwipe(route), context));
                  return _startPopGesture(route);
                },
                limitedSwipe: limitedSwipe,
                gestureWidth:
                    route.gestureWidth?.call(context) ?? kBackGestureWidth,
                initialOffset: initialOffset,
                child: child,
              ));

        case Transition.size:
          return SizeTransitions().buildTransitions(
              context,
              route.curve!,
              route.alignment,
              animation,
              secondaryAnimation,
              SintBackGestureDetector<T>(
                popGestureEnable: () =>
                    _isPopGestureEnabled(route, canSwipe(route), context),
                onStartPopGesture: () {
                  assert(_isPopGestureEnabled(route, canSwipe(route), context));
                  return _startPopGesture(route);
                },
                limitedSwipe: limitedSwipe,
                gestureWidth:
                    route.gestureWidth?.call(context) ?? kBackGestureWidth,
                initialOffset: initialOffset,
                child: child,
              ));

        case Transition.fade:
          return const FadeUpwardsPageTransitionsBuilder().buildTransitions(
              route,
              context,
              animation,
              secondaryAnimation,
              SintBackGestureDetector<T>(
                popGestureEnable: () =>
                    _isPopGestureEnabled(route, canSwipe(route), context),
                onStartPopGesture: () {
                  assert(_isPopGestureEnabled(route, canSwipe(route), context));
                  return _startPopGesture(route);
                },
                limitedSwipe: limitedSwipe,
                gestureWidth:
                    route.gestureWidth?.call(context) ?? kBackGestureWidth,
                initialOffset: initialOffset,
                child: child,
              ));

        case Transition.topLevel:
          return const ZoomPageTransitionsBuilder().buildTransitions(
              route,
              context,
              animation,
              secondaryAnimation,
              SintBackGestureDetector<T>(
                popGestureEnable: () =>
                    _isPopGestureEnabled(route, canSwipe(route), context),
                onStartPopGesture: () {
                  assert(_isPopGestureEnabled(route, canSwipe(route), context));
                  return _startPopGesture(route);
                },
                limitedSwipe: limitedSwipe,
                gestureWidth:
                    route.gestureWidth?.call(context) ?? kBackGestureWidth,
                initialOffset: initialOffset,
                child: child,
              ));

        case Transition.native:
          return const PageTransitionsTheme().buildTransitions(
              route,
              context,
              iosAnimation,
              secondaryAnimation,
              SintBackGestureDetector<T>(
                popGestureEnable: () =>
                    _isPopGestureEnabled(route, canSwipe(route), context),
                onStartPopGesture: () {
                  assert(_isPopGestureEnabled(route, canSwipe(route), context));
                  return _startPopGesture(route);
                },
                limitedSwipe: limitedSwipe,
                gestureWidth:
                    route.gestureWidth?.call(context) ?? kBackGestureWidth,
                initialOffset: initialOffset,
                child: child,
              ));

        case Transition.circularReveal:
          return CircularRevealTransition().buildTransitions(
              context,
              route.curve,
              route.alignment,
              animation,
              secondaryAnimation,
              SintBackGestureDetector<T>(
                popGestureEnable: () =>
                    _isPopGestureEnabled(route, canSwipe(route), context),
                onStartPopGesture: () {
                  assert(_isPopGestureEnabled(route, canSwipe(route), context));
                  return _startPopGesture(route);
                },
                limitedSwipe: limitedSwipe,
                gestureWidth:
                    route.gestureWidth?.call(context) ?? kBackGestureWidth,
                initialOffset: initialOffset,
                child: child,
              ));

        default:
          final customTransition = SintRoot.of(context).config.customTransition;

          if (customTransition != null) {
            return customTransition.buildTransition(context, route.curve,
                route.alignment, animation, secondaryAnimation, child);
          }

          PageTransitionsTheme pageTransitionsTheme =
              Theme.of(context).pageTransitionsTheme;

          return pageTransitionsTheme.buildTransitions(
              route,
              context,
              iosAnimation,
              secondaryAnimation,
              SintBackGestureDetector<T>(
                popGestureEnable: () =>
                    _isPopGestureEnabled(route, canSwipe(route), context),
                onStartPopGesture: () {
                  assert(
                    _isPopGestureEnabled(route, canSwipe(route), context),
                  );
                  return _startPopGesture(route);
                },
                limitedSwipe: limitedSwipe,
                gestureWidth:
                    route.gestureWidth?.call(context) ?? kBackGestureWidth,
                initialOffset: initialOffset,
                child: child,
              ));
      }
    }
  }

  // Called by SintBackGestureDetector when a pop ("back") drag start
  // gesture is detected. The returned controller handles all of the subsequent
  // drag events.
  /// True if an iOS-style back swipe pop gesture is currently
  /// underway for [route].
  ///
  /// This just check the route's [NavigatorState.userGestureInProgress].
  ///
  /// See also:
  ///
  ///  * [popGestureEnabled], which returns true if a user-triggered pop gesture
  ///    would be allowed.
  static bool isPopGestureInProgress(BuildContext context) {
    final route = ModalRoute.of(context)!;
    return route.navigator!.userGestureInProgress;
  }

  static bool _isPopGestureEnabled<T>(
      PageRoute<T> route, bool canSwipe, BuildContext context) {
    // If there's nothing to go back to, then obviously we don't support
    // the back gesture.
    if (route.isFirst) return false;
    // If the route wouldn't actually pop if we popped it, then the gesture
    // would be really confusing (or would skip internal router),
    // so disallow it.
    if (route.willHandlePopInternally) return false;
    // support [PopScope]
    if (route.popDisposition == RoutePopDisposition.doNotPop) return false;
    // Fullscreen dialogs aren't dismissible by back swipe.
    if (route.fullscreenDialog) return false;
    // If we're in an animation already, we cannot be manually swiped.
    if (route.animation!.status != AnimationStatus.completed) return false;
    // If we're being popped into, we also cannot be swiped until the pop above
    // it completes. This translates to our secondary animation being
    // dismissed.
    if (route.secondaryAnimation!.status != AnimationStatus.dismissed) {
      return false;
    }
    // If we're in a gesture already, we cannot start another.
    if (SintPageRouteTransitionMixin.isPopGestureInProgress(context)) {
      return false;
    }

    // Don't perfome swipe if canSwipe be false
    if (!canSwipe) return false;

    // Looks like a back gesture would be welcome!
    return true;
  }

  static SintBackGestureController<T> _startPopGesture<T>(
    PageRoute<T> route,
  ) {
    return SintBackGestureController<T>(
      navigator: route.navigator!,
      controller: route.controller!, // protected access
    );
  }
}
