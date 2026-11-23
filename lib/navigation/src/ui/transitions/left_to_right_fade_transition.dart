import 'package:flutter/widgets.dart';

class LeftToRightFadeTransition {
  const LeftToRightFadeTransition();

  static final Animatable<Offset> _inTween = Tween<Offset>(
    begin: const Offset(-1.0, 0.0),
    end: Offset.zero,
  );

  static final Animatable<Offset> _outTween = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(1.0, 0.0),
  );

  Widget buildTransitions(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: animation.drive(_inTween),
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: secondaryAnimation.drive(_outTween),
          child: child,
        ),
      ),
    );
  }
}
