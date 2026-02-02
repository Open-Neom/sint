import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class ZoomInTransition {
  Widget buildTransitions(
      BuildContext context,
      Curve? curve,
      Alignment? alignment,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return ScaleTransition(
      scale: animation,
      child: child,
    );
  }
}
