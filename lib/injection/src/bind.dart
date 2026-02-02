// ignore_for_file: overridden_fields

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sint/sint.dart';

abstract class Bind<T> extends StatelessWidget {
  const Bind({
    super.key,
    required this.child,
    this.init,
    this.global = true,
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

  final InitBuilder<T>? init;

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

  final Widget? child;

  static Bind put<S>(
      S dependency, {
        String? tag,
        bool permanent = false,
      }) {
    Sint.put<S>(dependency, tag: tag, permanent: permanent);
    return _FactoryBind<S>(
      autoRemove: permanent,
      assignId: true,
      tag: tag,
    );
  }

  static Bind lazyPut<S>(
      InstanceBuilderCallback<S> builder, {
        String? tag,
        bool fenix = false,
        VoidCallback? onInit,
        VoidCallback? onClose,
      }) {
    Sint.lazyPut<S>(builder, tag: tag, fenix: fenix);
    return _FactoryBind<S>(
      tag: tag,
      initState: (_) {
        onInit?.call();
      },
      dispose: (_) {
        onClose?.call();
      },
    );
  }

  static Bind create<S>(InstanceCreateBuilderCallback<S> builder,
      {String? tag, bool permanent = true}) {
    return _FactoryBind<S>(
      create: builder,
      tag: tag,
      global: false,
    );
  }

  static Bind spawn<S>(InstanceBuilderCallback<S> builder,
      {String? tag, bool permanent = true}) {
    Sint.spawn<S>(builder, tag: tag, permanent: permanent);
    return _FactoryBind<S>(
      tag: tag,
      global: false,
      autoRemove: permanent,
    );
  }

  static S find<S>({String? tag}) => Sint.find<S>(tag: tag);

  static Future<bool> delete<S>({String? tag, bool force = false}) async =>
      Sint.delete<S>(tag: tag, force: force);

  static Future<void> deleteAll({bool force = false}) async =>
      Sint.deleteAll(force: force);

  static void reloadAll({bool force = false}) => Sint.reloadAll(force: force);

  static void reload<S>({String? tag, String? key, bool force = false}) =>
      Sint.reload<S>(tag: tag, key: key, force: force);

  static bool isRegistered<S>({String? tag}) => Sint.isRegistered<S>(tag: tag);

  static bool isPrepared<S>({String? tag}) => Sint.isPrepared<S>(tag: tag);

  static void replace<P>(P child, {String? tag}) {
    final info = Sint.getInstanceInfo<P>(tag: tag);
    final permanent = (info.isPermanent ?? false);
    delete<P>(tag: tag, force: permanent);
    Sint.put(child, tag: tag, permanent: permanent);
  }

  static void lazyReplace<P>(InstanceBuilderCallback<P> builder,
      {String? tag, bool? fenix}) {
    final info = Sint.getInstanceInfo<P>(tag: tag);
    final permanent = (info.isPermanent ?? false);
    delete<P>(tag: tag, force: permanent);
    Sint.lazyPut(builder, tag: tag, fenix: fenix ?? permanent);
  }

  factory Bind.builder({
    Widget? child,
    InitBuilder<T>? init,
    InstanceCreateBuilderCallback<T>? create,
    bool global = true,
    bool autoRemove = true,
    bool assignId = false,
    Object Function(T value)? filter,
    String? tag,
    Object? id,
    void Function(BindElement<T> state)? initState,
    void Function(BindElement<T> state)? dispose,
    void Function(BindElement<T> state)? didChangeDependencies,
    void Function(Binder<T> oldWidget, BindElement<T> state)? didUpdateWidget,
  }) =>
      _FactoryBind<T>(
        // key: key,
        init: init,
        create: create,
        global: global,
        autoRemove: autoRemove,
        assignId: assignId,
        initState: initState,
        filter: filter,
        tag: tag,
        dispose: dispose,
        id: id,
        didChangeDependencies: didChangeDependencies,
        didUpdateWidget: didUpdateWidget,
        child: child,
      );

  static T of<T>(
      BuildContext context, {
        bool rebuild = false,
        // Object Function(T value)? filter,
      }) {
    final inheritedElement =
    context.getElementForInheritedWidgetOfExactType<Binder<T>>()
    as BindElement<T>?;

    if (inheritedElement == null) {
      throw BindError(controller: '$T', tag: null);
    }

    if (rebuild) {
      context.dependOnInheritedElement(inheritedElement);
    }

    final controller = inheritedElement.controller;

    return controller;
  }

  @factory
  Bind<T> copyWithChild(Widget child);
}

class _FactoryBind<T> extends Bind<T> {
  @override
  final InitBuilder<T>? init;

  final InstanceCreateBuilderCallback<T>? create;

  @override
  final bool global;
  @override
  final Object? id;
  @override
  final String? tag;
  @override
  final bool autoRemove;
  @override
  final bool assignId;
  @override
  final Object Function(T value)? filter;

  @override
  final void Function(BindElement<T> state)? initState,
      dispose,
      didChangeDependencies;
  @override
  final void Function(Binder<T> oldWidget, BindElement<T> state)?
  didUpdateWidget;

  @override
  final Widget? child;

  const _FactoryBind({
    super.key,
    this.child,
    this.init,
    this.create,
    this.global = true,
    this.autoRemove = true,
    this.assignId = false,
    this.initState,
    this.filter,
    this.tag,
    this.dispose,
    this.id,
    this.didChangeDependencies,
    this.didUpdateWidget,
  }) : super(child: child);

  @override
  Bind<T> copyWithChild(Widget child) {
    return Bind<T>.builder(
      init: init,
      create: create,
      global: global,
      autoRemove: autoRemove,
      assignId: assignId,
      initState: initState,
      filter: filter,
      tag: tag,
      dispose: dispose,
      id: id,
      didChangeDependencies: didChangeDependencies,
      didUpdateWidget: didUpdateWidget,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Binder<T>(
      create: create,
      global: global,
      autoRemove: autoRemove,
      assignId: assignId,
      initState: initState,
      filter: filter,
      tag: tag,
      dispose: dispose,
      id: id,
      didChangeDependencies: didChangeDependencies,
      didUpdateWidget: didUpdateWidget,
      child: child!,
    );
  }
}



