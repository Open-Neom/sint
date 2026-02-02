import 'package:flutter/widgets.dart';

class SintNavigator extends Navigator {
  SintNavigator({
    super.key,
    bool Function(Route<dynamic>, dynamic)? onPopPage,
    DidRemovePageCallback? onDidRemovePage,
    required super.pages,
    List<NavigatorObserver>? observers,
    super.reportsRouteUpdateToEngine,
    TransitionDelegate? transitionDelegate,
    super.initialRoute,
    super.restorationScopeId,
  }) : super(
    onDidRemovePage: onDidRemovePage ?? _defaultOnDidRemovePage,
    observers: [
      HeroController(),
      ...?observers,
    ],
    transitionDelegate:
    transitionDelegate ?? const DefaultTransitionDelegate<dynamic>(),
  );

  static void _defaultOnDidRemovePage(
      Page<dynamic> route) {
  }

}
