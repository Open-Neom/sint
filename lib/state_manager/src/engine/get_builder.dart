import 'package:flutter/material.dart';
import 'package:sint/injection/src/bind.dart';
import 'package:sint/injection/src/ui/bind_element.dart';
import 'package:sint/injection/src/ui/binder.dart';
import 'package:sint/state_manager/src/domain/typedefs/state_typedefs.dart';
import 'package:sint/state_manager/src/engine/sint_controller.dart';


class SintBuilder<T extends SintController> extends StatelessWidget {
  final SintControllerBuilder<T> builder;
  final bool global;
  final Object? id;
  final String? tag;
  final bool autoRemove;
  final bool assignId;
  final Object Function(T value)? filter;
  final void Function(BindElement<T> state)? initState,
      dispose,
      didChangeDependencies;
  final void Function(Binder<T> oldWidget, BindElement<T> state)?
      didUpdateWidget;
  final T? init;

  const SintBuilder({
    super.key,
    this.init,
    this.global = true,
    required this.builder,
    this.autoRemove = true,
    this.assignId = false,
    this.initState,
    this.filter,
    this.tag,
    this.dispose,
    this.id,
    this.didChangeDependencies,
    this.didUpdateWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Binder(
      init: init == null ? null : () => init!,
      global: global,
      autoRemove: autoRemove,
      assignId: assignId,
      initState: initState,
      filter: filter,
      tag: tag,
      dispose: dispose,
      id: id,
      lazy: false,
      didChangeDependencies: didChangeDependencies,
      didUpdateWidget: didUpdateWidget,
      child: Builder(builder: (context) {
        final controller = Bind.of<T>(context, rebuild: true);
        return builder(controller);
      }),
    );
  }
}







