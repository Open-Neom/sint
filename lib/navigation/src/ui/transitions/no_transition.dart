import 'package:flutter/widgets.dart';

class NoTransition {
  const NoTransition();

  Widget buildTransitions(
    BuildContext context,
    Curve curve,
    Alignment alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
