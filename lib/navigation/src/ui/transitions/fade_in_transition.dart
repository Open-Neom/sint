import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class FadeInTransition {
  Widget buildTransitions(
      BuildContext context,
      Curve? curve,
      Alignment? alignment,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return FadeTransition(opacity: animation, child: child);
  }
}
