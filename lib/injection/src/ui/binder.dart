import 'package:flutter/material.dart';
import 'package:sint/injection/src/domain/typedefs/injection_typedefs.dart';
import 'package:sint/injection/src/ui/bind_element.dart';
import 'package:sint/state_manager/src/domain/typedefs/state_typedefs.dart';

class Binder<T> extends InheritedWidget {
  /// Create an inherited widget that updates its dependents when [controller]
  /// sends notifications.
  ///
  /// The [child] argument is required
  const Binder({
    super.key,
    required super.child,
    this.init,
    this.global = true,
    this.autoRemove = true,
    this.assignId = false,
    this.lazy = true,
    this.initState,
    this.filter,
    this.tag,
    this.dispose,
    this.id,
    this.didChangeDependencies,
    this.didUpdateWidget,
    this.create,
  });

  final InitBuilder<T>? init;
  final InstanceCreateBuilderCallback? create;
  final bool global;
  final Object? id;
  final String? tag;
  final bool lazy;
  final bool autoRemove;
  final bool assignId;
  final Object Function(T value)? filter;
  final void Function(BindElement<T> state)? initState,
      dispose,
      didChangeDependencies;
  final void Function(Binder<T> oldWidget, BindElement<T> state)?
  didUpdateWidget;

  @override
  bool updateShouldNotify(Binder<T> oldWidget) {
    return oldWidget.id != id ||
        oldWidget.global != global ||
        oldWidget.autoRemove != autoRemove ||
        oldWidget.assignId != assignId;
  }

  @override
  InheritedElement createElement() => BindElement<T>(this);
}