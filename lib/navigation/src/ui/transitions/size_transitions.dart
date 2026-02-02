import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class SizeTransitions {
  Widget buildTransitions(
      BuildContext context,
      Curve curve,
      Alignment? alignment,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return Align(
      alignment: Alignment.center,
      child: SizeTransition(
        sizeFactor: CurvedAnimation(
          parent: animation,
          curve: curve,
        ),
        child: child,
      ),
    );
  }
}
