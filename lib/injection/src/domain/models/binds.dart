import 'package:flutter/material.dart';
import 'package:sint/injection/src/bind.dart';

class Binds extends StatelessWidget {

  final List<Bind<dynamic>> binds;
  final Widget child;

  Binds({
    super.key,
    required this.binds,
    required this.child,
  }) : assert(binds.isNotEmpty);

  @override
  Widget build(BuildContext context) =>
      binds.reversed.fold(child, (widget, e) => e.copyWithChild(widget));
}
