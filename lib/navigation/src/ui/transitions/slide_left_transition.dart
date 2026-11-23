import 'package:flutter/widgets.dart';

class SlideLeftTransition {
  const SlideLeftTransition();

  static final Animatable<Offset> _tween = Tween<Offset>(
    begin: const Offset(-1.0, 0.0),
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
