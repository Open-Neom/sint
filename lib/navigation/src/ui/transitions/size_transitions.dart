import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class SizeTransitions {
  Widget buildTransitions(
      BuildContext context,
      Curve? curve,
      Alignment? alignment,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return Align(
      alignment: alignment ?? Alignment.center,
      child: SizeTransition(
        sizeFactor: curve != null
            ? animation.drive(CurveTween(curve: curve))
            : animation,
        child: child,
      ),
    );
  }
}
