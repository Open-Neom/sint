import 'package:flutter/widgets.dart';
import 'package:sint/navigation/src/router/router_report_manager.dart';

class SintDialogRoute<T> extends PopupRoute<T> {
  SintDialogRoute({
    required RoutePageBuilder pageBuilder,
    bool barrierDismissible = true,
    String? barrierLabel,
    Color barrierColor = const Color(0x80000000),
    Duration transitionDuration = const Duration(milliseconds: 200),
    RouteTransitionsBuilder? transitionBuilder,
    super.settings,
  }) : widget = pageBuilder,
       // ignore: prefer_initializing_formals
       _barrierDismissible = barrierDismissible,
       // ignore: prefer_initializing_formals
       _barrierLabel = barrierLabel,
       // ignore: prefer_initializing_formals
       _barrierColor = barrierColor,
       // ignore: prefer_initializing_formals
       _transitionDuration = transitionDuration,
       // ignore: prefer_initializing_formals
       _transitionBuilder = transitionBuilder {
    RouterReportManager.instance.reportCurrentRoute(this);
  }

  final RoutePageBuilder widget;

  @override
  bool get barrierDismissible => _barrierDismissible;
  final bool _barrierDismissible;

  @override
  void dispose() {
    RouterReportManager.instance.reportRouteDispose(this);
    super.dispose();
  }

  @override
  String? get barrierLabel => _barrierLabel;
  final String? _barrierLabel;

  @override
  Color get barrierColor => _barrierColor;
  final Color _barrierColor;

  @override
  Duration get transitionDuration => _transitionDuration;
  final Duration _transitionDuration;

  final RouteTransitionsBuilder? _transitionBuilder;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: widget(context, animation, secondaryAnimation),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (_transitionBuilder == null) {
      return FadeTransition(opacity: animation, child: child);
    } // Some default transition
    return _transitionBuilder(context, animation, secondaryAnimation, child);
  }
}
