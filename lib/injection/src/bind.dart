// ignore_for_file: overridden_fields

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sint/core/sint_core.dart';
import 'package:sint/injection/src/domain/extensions/injection_extension.dart';
import 'package:sint/injection/src/domain/typedefs/injection_typedefs.dart';
import 'package:sint/injection/src/sint_service.dart';
import 'package:sint/injection/src/ui/bind_element.dart';
import 'package:sint/injection/src/ui/binder.dart';
import 'package:sint/injection/src/ui/multi_binder.dart';
import 'package:sint/state_manager/sint_state_manager.dart';

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

  /// Reified generic type bound by this [Bind].
  Type get boundType => T;

  /// Optional context-based factory (`Bind.create`).
  InstanceCreateBuilderCallback<T>? get createSource => null;

  /// Optional element-free mount hook (`Bind.lazyPut` / `Bind.contract` `onInit`).
  VoidCallback? get onMountCallback => null;

  /// Optional element-free unmount hook (`Bind.lazyPut` / `Bind.contract` `onClose`).
  VoidCallback? get onUnmountCallback => null;

  /// Repeatable registration hook invoked on mount if a route/widget [Bind]
  /// is remounted after a previous `autoRemove` disposal.
  VoidCallback? get ensureRegisteredCallback => null;

  /// Additional contract/alias types exposed by this [Bind] for `Bind.of<I>(context)`.
  List<Type> get extraBoundTypes => const <Type>[];

  /// Whether this [Bind] can be hosted inside a flat [MultiBinder] instead of
  /// allocating its own nested `Binder<T>` `InheritedElement`.
  bool get canFlattenIntoMultiBinder => false;

  /// Creates a typed [MultiBindSlot] preserving generic type [T].
  MultiBindSlot<T> createMultiBindSlot() => MultiBindSlot<T>(this);

  /// Returns `Bind<dynamic>` on the static signature so downward context from
  /// `List<Bind>` (`List<Bind<dynamic>>` in `Binding.dependencies()`,
  /// `SintMaterialApp(binds: [...])`, `SintPage(binds: [...])`, `Binds(...)`)
  /// never coerces `S` to `dynamic` when callers omit `<S>`; the underlying
  /// `_FactoryBind<S>` still preserves the reified `S` at runtime.
  static Bind<dynamic> put<S>(
    S dependency, {
    String? tag,
    bool? permanent,
    List<Type>? aliases,
  }) {
    final isPermanent = permanent ?? (dependency is SintService);
    void register() {
      Sint.put<S>(
        dependency,
        tag: tag,
        permanent: isPermanent,
        aliases: aliases,
      );
    }

    register();
    return _FactoryBind<S>(
      autoRemove: !isPermanent,
      assignId: true,
      tag: tag,
      ensureRegistered: register,
      extraBoundTypes: aliases ?? const <Type>[],
    );
  }

  /// Eager contract-first registration: registers [dependency] primarily under
  /// service contract [S] while also aliasing [I] for intra-module consumers.
  static Bind<dynamic> putContract<S, I extends S>(
    I dependency, {
    String? tag,
    bool? permanent,
    bool? isDefault,
    List<Type>? aliases,
  }) {
    final isPermanent = permanent ?? (dependency is SintService);
    final extraTypes = <Type>[if (I != S) I, ...?aliases];
    void register() {
      Sint.putContract<S, I>(
        dependency,
        tag: tag,
        permanent: isPermanent,
        isDefault: isDefault,
        aliases: aliases,
      );
    }

    register();
    return _FactoryBind<S>(
      autoRemove: !isPermanent,
      assignId: true,
      tag: tag,
      ensureRegistered: register,
      extraBoundTypes: extraTypes,
    );
  }

  static Bind<dynamic> lazyPut<S>(
    InstanceBuilderCallback<S> builder, {
    String? tag,
    bool fenix = false,
    bool? permanent,
    List<Type>? aliases,
    VoidCallback? onInit,
    VoidCallback? onClose,
  }) {
    final isPermanent =
        permanent ?? (builder is InstanceBuilderCallback<SintService>);
    void register() {
      Sint.lazyPut<S>(
        builder,
        tag: tag,
        fenix: fenix,
        permanent: isPermanent,
        aliases: aliases,
      );
    }

    register();
    return _FactoryBind<S>(
      tag: tag,
      autoRemove: !isPermanent,
      onMount: onInit,
      onUnmount: onClose,
      ensureRegistered: register,
      extraBoundTypes: aliases ?? const <Type>[],
    );
  }

  /// Lazy contract-first registration (`lazyPut` with service [S] first and
  /// concrete implementation [I] second).
  ///
  /// - External modules resolve via `Sint.find<S>()` (default),
  ///   `Sint.find<S>(tag: 'id')` (by ID), or `Sint.findAt<S>(index)` /
  ///   `Sint.findAll<S>()` (by registration order).
  /// - Intra-module screens inside the owning package can also resolve
  ///   `Sint.find<I>()` from the exact same shared factory.
  static Bind<dynamic> contract<S, I extends S>(
    InstanceBuilderCallback<I> builder, {
    String? tag,
    bool fenix = false,
    bool? permanent,
    bool? isDefault,
    List<Type>? aliases,
    VoidCallback? onInit,
    VoidCallback? onClose,
  }) {
    final isPermanent =
        permanent ?? (builder is InstanceBuilderCallback<SintService>);
    final extraTypes = <Type>[if (I != S) I, ...?aliases];
    void register() {
      Sint.contract<S, I>(
        builder,
        tag: tag,
        fenix: fenix,
        permanent: isPermanent,
        isDefault: isDefault,
        aliases: aliases,
      );
    }

    register();
    return _FactoryBind<S>(
      tag: tag,
      autoRemove: !isPermanent,
      onMount: onInit,
      onUnmount: onClose,
      ensureRegistered: register,
      extraBoundTypes: extraTypes,
    );
  }

  static Bind<dynamic> create<S>(
    InstanceCreateBuilderCallback<S> builder, {
    String? tag,
    bool permanent = true,
  }) {
    return _FactoryBind<S>(
      create: builder,
      tag: tag,
      global: false,
      autoRemove: !permanent,
    );
  }

  static Bind<dynamic> spawn<S>(
    InstanceBuilderCallback<S> builder, {
    String? tag,
    bool permanent = true,
  }) {
    void register() {
      Sint.spawn<S>(builder, tag: tag, permanent: permanent);
    }

    register();
    return _FactoryBind<S>(
      tag: tag,
      global: false,
      autoRemove: !permanent,
      ensureRegistered: register,
    );
  }

  static Future<S> putAsync<S>(
    Future<S> Function() asyncBuilder, {
    String? tag,
    bool? permanent,
    List<Type>? aliases,
  }) => Sint.putAsync<S>(
    asyncBuilder,
    tag: tag,
    permanent: permanent,
    aliases: aliases,
  );

  static Future<I> putContractAsync<S, I extends S>(
    Future<I> Function() asyncBuilder, {
    String? tag,
    bool? permanent,
    bool? isDefault,
    List<Type>? aliases,
  }) => Sint.putContractAsync<S, I>(
    asyncBuilder,
    tag: tag,
    permanent: permanent,
    isDefault: isDefault,
    aliases: aliases,
  );

  static S find<S>({String? tag}) => Sint.find<S>(tag: tag);

  static S? findOrNull<S>({String? tag}) => Sint.findOrNull<S>(tag: tag);

  static List<S> findAll<S>() => Sint.findAll<S>();

  static S findAt<S>(int index) => Sint.findAt<S>(index);

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
    Sint.replace<P>(child, tag: tag);
  }

  static void lazyReplace<P>(
    InstanceBuilderCallback<P> builder, {
    String? tag,
    bool? fenix,
  }) {
    Sint.lazyReplace<P>(builder, tag: tag, fenix: fenix);
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
  }) => _FactoryBind<T>(
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

  static T of<T>(BuildContext context, {bool rebuild = false, String? tag}) {
    var inheritedElement =
        context.getElementForInheritedWidgetOfExactType<Binder<T>>()
            as BindElement<T>?;
    if (inheritedElement != null &&
        tag != null &&
        inheritedElement.widget.tag != tag) {
      inheritedElement = null;
    }

    final multiMatch = MultiBinder.findMatch(context, T, tag: tag);

    if (inheritedElement != null && multiMatch != null) {
      if (multiMatch.$1.depth > inheritedElement.depth) {
        return MultiBinder.resolveMatch<T>(
          context,
          multiMatch.$1,
          multiMatch.$2,
          rebuild: rebuild,
        );
      }
      if (rebuild) {
        context.dependOnInheritedElement(inheritedElement);
      }
      return inheritedElement.controller;
    }

    if (inheritedElement != null) {
      if (rebuild) {
        context.dependOnInheritedElement(inheritedElement);
      }
      return inheritedElement.controller;
    }

    if (multiMatch != null) {
      return MultiBinder.resolveMatch<T>(
        context,
        multiMatch.$1,
        multiMatch.$2,
        rebuild: rebuild,
      );
    }

    throw BindError(controller: '$T', tag: tag);
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

  final VoidCallback? onMount;
  final VoidCallback? onUnmount;
  final VoidCallback? ensureRegistered;
  @override
  final List<Type> extraBoundTypes;

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
    this.onMount,
    this.onUnmount,
    this.ensureRegistered,
    this.extraBoundTypes = const <Type>[],
  }) : super(child: child);

  @override
  InstanceCreateBuilderCallback<T>? get createSource => create;

  @override
  VoidCallback? get onMountCallback => onMount;

  @override
  VoidCallback? get onUnmountCallback => onUnmount;

  @override
  VoidCallback? get ensureRegisteredCallback => ensureRegistered;

  @override
  bool get canFlattenIntoMultiBinder =>
      initState == null &&
      dispose == null &&
      didChangeDependencies == null &&
      didUpdateWidget == null;

  @override
  Bind<T> copyWithChild(Widget child) {
    return _FactoryBind<T>(
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
      onMount: onMount,
      onUnmount: onUnmount,
      ensureRegistered: ensureRegistered,
      extraBoundTypes: extraBoundTypes,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Binder<T>(
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
      onMount: onMount,
      onUnmount: onUnmount,
      ensureRegistered: ensureRegistered,
      child: child!,
    );
  }
}
