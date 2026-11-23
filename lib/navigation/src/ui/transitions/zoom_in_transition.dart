import 'package:flutter/widgets.dart';

class ZoomInTransition {
  const ZoomInTransition();

  Widget buildTransitions(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(scale: animation, child: child);
  }
}
