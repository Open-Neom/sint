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
          // Keep the legacy callback usable for direct SintNavigator consumers.
          // SintDelegate uses onDidRemovePage to synchronize completed removals.
          // ignore: deprecated_member_use
          onPopPage: onDidRemovePage == null ? onPopPage : null,
          onDidRemovePage: onDidRemovePage ??
              (onPopPage == null ? _defaultOnDidRemovePage : null),
          observers: [
            HeroController(),
            ...?observers,
          ],
          transitionDelegate:
              transitionDelegate ?? const DefaultTransitionDelegate<dynamic>(),
        );

  static void _defaultOnDidRemovePage(Page<dynamic> route) {}
}
