
import 'package:flutter/widgets.dart';
import 'package:sint/state_manager/src/domain/typedefs/state_typedefs.dart';
import 'package:sint/state_manager/src/ui/obx_reacive_element.dart';

/// The simplest reactive widget in SINT.
///
/// Just pass your Rx variable in the root scope of the callback to have it
/// automatically registered for changes.
///
/// final _name = "SINT".obs;
/// Obx(() => Text( _name.value )),... ;
class Obx extends StatelessWidget {
  final WidgetCallback builder;

  const Obx(this.builder, {super.key});

  @override
  Widget build(BuildContext context) {
    return builder();
  }

  @override
  StatelessElement createElement() => ObxReactiveElement(this);
}
