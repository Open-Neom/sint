import 'package:flutter/widgets.dart';

class SlideDownTransition {
  const SlideDownTransition();

  static final Animatable<Offset> _tween = Tween<Offset>(
    begin: const Offset(0.0, 1.0),
    end: Offset.zero,
  );

  Widget buildTransitions(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(position: animation.drive(_tween), child: child);
  }
}
