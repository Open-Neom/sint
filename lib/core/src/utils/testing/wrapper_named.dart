import 'package:flutter/material.dart';
import 'package:sint/navigation/sint_navigation.dart';

class WrapperNamed extends StatelessWidget {
  final Widget? child;
  final List<SintPage>? namedRoutes;
  final String? initialRoute;
  final Transition? defaultTransition;

  const WrapperNamed({
    super.key,
    this.child,
    this.namedRoutes,
    this.initialRoute,
    this.defaultTransition,
  });

  @override
  Widget build(BuildContext context) {
    return SintMaterialApp(
      defaultTransition: defaultTransition,
      initialRoute: initialRoute,
      sintPages: namedRoutes,
    );
  }
}
