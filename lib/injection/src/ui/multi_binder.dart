import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:sint/core/sint_core.dart';
import 'package:sint/injection/src/bind.dart';
import 'package:sint/injection/src/domain/extensions/injection_extension.dart';
import 'package:sint/injection/src/domain/models/route_dependency.dart';
import 'package:sint/injection/src/lifecycle.dart';
import 'package:sint/injection/src/ui/sint_scope.dart';
import 'package:sint/state_manager/sint_state_manager.dart';

/// Flat, single-element host widget for `Binds` (`O(1)` widget-tree depth
/// regardless of how many `Bind` entries are registered on a route or app root).
///
/// Replaces `N` nested `Binder<T>` (`InheritedWidget`) wrappers with a single
/// [MultiBindElement] (`InheritedModelElement<Type>`), preserving `Bind.of<T>`
/// lookup, granular per-`Type` rebuilds, `Bind.create`, `onInit`/`onClose`, and
/// generation-safe `autoRemove` disposal.
class MultiBinder extends InheritedModel<Type> {
  const MultiBinder({
    super.key,
    required this.binds,
    required super.child,
  });

  final List<Bind<dynamic>> binds;

  @override
  MultiBindElement createElement() => MultiBindElement(this);

  @override
  bool updateShouldNotify(covariant MultiBinder oldWidget) => false;

  @override
  bool updateShouldNotifyDependent(
    covariant MultiBinder oldWidget,
    Set<Type> dependencies,
  ) =>
      false;

  /// Finds the nearest ancestor `(MultiBindElement, MultiBindSlot)` matching
  /// [type] (including contract/alias types) and optional [tag].
  static (MultiBindElement, MultiBindSlot<dynamic>)? findMatch(
    BuildContext context,
    Type type, {
    String? tag,
  }) {
    var element = context.getElementForInheritedWidgetOfExactType<MultiBinder>()
        as MultiBindElement?;
    while (element != null) {
      final slot = element.lookupSlot(type, tag: tag);
      if (slot != null) {
        return (element, slot);
      }
      element = element.parentMultiBinder;
    }
    return null;
  }

  /// Resolves [slot] inside [element]'s ancestor [SintScope] chain and
  /// subscribes [context] to granular `aspect: T` updates when [rebuild] is `true`.
  static T resolveMatch<T>(
    BuildContext context,
    MultiBindElement element,
    MultiBindSlot<dynamic> slot, {
    bool rebuild = false,
  }) {
    if (rebuild) {
      context.dependOnInheritedElement(element, aspect: T);
    }
    if (InjectionExtension.hasActiveScopes) {
      return InjectionExtension.runWithWidgetBuildScopes<T>(
        SintScope.ancestorContainersOf(element),
        () => slot.resolveUntyped(element.markTypeDirty) as T,
      );
    }
    return slot.resolveUntyped(element.markTypeDirty) as T;
  }

  /// Resolves [T] from the nearest ancestor [MultiBinder] containing a slot for
  /// `T` (and optional [tag]), walking parent [MultiBinder] scopes in `O(1)`
  /// hops without scanning intermediate non-binder elements.
  static T? resolveOrNull<T>(
    BuildContext context, {
    bool rebuild = false,
    String? tag,
  }) {
    final match = findMatch(context, T, tag: tag);
    if (match == null) return null;
    return resolveMatch<T>(context, match.$1, match.$2, rebuild: rebuild);
  }
}

/// Element backing [MultiBinder], managing `N` typed [MultiBindSlot] lifecycles
/// inside a single Flutter `Element`.
class MultiBindElement extends InheritedModelElement<Type> {
  MultiBindElement(MultiBinder super.widget);

  final List<MultiBindSlot<dynamic>> _slots = <MultiBindSlot<dynamic>>[];
  final Map<Type, List<MultiBindSlot<dynamic>>> _slotsByType =
      HashMap<Type, List<MultiBindSlot<dynamic>>>();
  final Set<Type> _dirtyTypes = HashSet<Type>();

  MultiBindElement? _parentMultiBinder;
  MultiBindElement? get parentMultiBinder => _parentMultiBinder;

  @override
  MultiBinder get widget => super.widget as MultiBinder;

  @override
  void mount(Element? parent, Object? newSlot) {
    _parentMultiBinder = parent
        ?.getElementForInheritedWidgetOfExactType<MultiBinder>()
        as MultiBindElement?;
    if (InjectionExtension.hasActiveScopes) {
      final scopes = parent == null
          ? const <SintScopeContainer>[]
          : SintScope.ancestorContainersOf(parent);
      InjectionExtension.runWithWidgetBuildScopes<void>(
        scopes,
        _mountInitialSlots,
      );
    } else {
      _mountInitialSlots();
    }
    super.mount(parent, newSlot);
  }

  @override
  void activate() {
    super.activate();
    var ancestor = false;
    visitAncestorElements((el) {
      final found = el.getElementForInheritedWidgetOfExactType<MultiBinder>()
          as MultiBindElement?;
      _parentMultiBinder = identical(found, this) ? null : found;
      ancestor = true;
      return false;
    });
    if (!ancestor) {
      _parentMultiBinder = null;
    }
  }

  void _indexSlot(MultiBindSlot<dynamic> slot) {
    (_slotsByType[slot.boundType] ??= <MultiBindSlot<dynamic>>[]).add(slot);
    for (final extra in slot.extraBoundTypes) {
      if (extra != slot.boundType) {
        (_slotsByType[extra] ??= <MultiBindSlot<dynamic>>[]).add(slot);
      }
    }
  }

  void _mountInitialSlots() {
    for (final bind in widget.binds) {
      final slot = bind.createMultiBindSlot();
      _slots.add(slot);
      _indexSlot(slot);
      slot.mountSlot(this, markTypeDirty);
    }
  }

  MultiBindSlot<dynamic>? lookupSlot(Type type, {String? tag}) {
    final list = _slotsByType[type];
    if (list == null || list.isEmpty) return null;
    for (var i = list.length - 1; i >= 0; i--) {
      final candidate = list[i];
      if (candidate.tag == tag) {
        return candidate;
      }
    }
    if (tag == null) {
      return list.last;
    }
    return null;
  }

  void markTypeDirty(Type type) {
    if (!mounted) return;
    _dirtyTypes.add(type);
    markNeedsBuild();
  }

  @override
  void update(MultiBinder newWidget) {
    if (InjectionExtension.hasActiveScopes) {
      InjectionExtension.runWithWidgetBuildScopes<void>(
        SintScope.ancestorContainersOf(this),
        () => _reconcileSlots(newWidget.binds),
      );
    } else {
      _reconcileSlots(newWidget.binds);
    }
    super.update(newWidget);
  }

  void _reconcileSlots(List<Bind<dynamic>> nextBinds) {
    if (_slots.length == nextBinds.length) {
      var allMatch = true;
      for (var i = 0; i < _slots.length; i++) {
        if (_slots[i].boundType != nextBinds[i].boundType ||
            _slots[i].tag != nextBinds[i].tag) {
          allMatch = false;
          break;
        }
      }
      if (allMatch) {
        for (var i = 0; i < _slots.length; i++) {
          _slots[i].updateBind(nextBinds[i], markTypeDirty);
        }
        return;
      }
    }

    // Reconcile changed slots while preserving matching `(Type, tag)` entries.
    final reusable = <(Type, String?), List<MultiBindSlot<dynamic>>>{};
    for (final existing in _slots) {
      (reusable[(existing.boundType, existing.tag)] ??=
              <MultiBindSlot<dynamic>>[])
          .add(existing);
    }

    final nextSlots = <MultiBindSlot<dynamic>>[];
    _slotsByType.clear();
    for (final bind in nextBinds) {
      final bucket = reusable[(bind.boundType, bind.tag)];
      final MultiBindSlot<dynamic> slot;
      if (bucket != null && bucket.isNotEmpty) {
        slot = bucket.removeAt(0);
        slot.updateBind(bind, markTypeDirty);
      } else {
        slot = bind.createMultiBindSlot();
        slot.mountSlot(this, markTypeDirty);
      }
      nextSlots.add(slot);
      _indexSlot(slot);
    }

    for (final leftoverBucket in reusable.values) {
      for (final stale in leftoverBucket) {
        stale.unmountSlot();
      }
    }

    _slots
      ..clear()
      ..addAll(nextSlots);
  }

  @override
  Widget build() {
    if (_dirtyTypes.isNotEmpty) {
      notifyClients(widget);
    }
    return super.build();
  }

  @override
  void notifyClients(MultiBinder oldWidget) {
    super.notifyClients(oldWidget);
    _dirtyTypes.clear();
  }

  @override
  void notifyDependent(MultiBinder oldWidget, Element dependent) {
    final dependencies = getDependencies(dependent) as Set<Type>?;
    if (dependencies == null) return;
    if (dependencies.isEmpty || dependencies.any(_dirtyTypes.contains)) {
      dependent.didChangeDependencies();
    }
  }

  @override
  void unmount() {
    for (var i = _slots.length - 1; i >= 0; i--) {
      _slots[i].unmountSlot();
    }
    _slots.clear();
    _slotsByType.clear();
    _dirtyTypes.clear();
    _parentMultiBinder = null;
    super.unmount();
  }
}

/// Typed lifecycle slot managed inside [MultiBindElement].
class MultiBindSlot<T> {
  MultiBindSlot(this._bind);

  Bind<T> _bind;
  Type get boundType => T;
  List<Type> get extraBoundTypes => _bind.extraBoundTypes;
  String? get tag => _bind.tag;

  InitBuilder<T>? _controllerBuilder;
  T? _controller;
  RouteDependency? _ownedDependency;
  bool _isCreator = false;
  bool _needStart = false;
  bool _wasStarted = false;
  VoidCallback? _remove;
  Object? _filter;

  void mountSlot(
    BuildContext context,
    void Function(Type type) onDirty,
  ) {
    _bind.onMountCallback?.call();

    var isRegistered = Sint.isRegistered<T>(tag: _bind.tag);
    if (!isRegistered && _bind.ensureRegisteredCallback != null) {
      _bind.ensureRegisteredCallback!();
      isRegistered = Sint.isRegistered<T>(tag: _bind.tag);
    }
    if (_bind.global) {
      if (isRegistered) {
        _isCreator = Sint.isPrepared<T>(tag: _bind.tag);
        _controllerBuilder = () => Sint.find<T>(tag: _bind.tag);
      } else {
        _controllerBuilder =
            () => (_bind.createSource?.call(context) ?? _bind.init!.call());
        _isCreator = true;
        Sint.lazyPut<T>(_controllerBuilder!, tag: _bind.tag);
      }
      if (_isCreator || _bind.assignId) {
        _ownedDependency = Sint.captureInstanceLifecycle<T>(tag: _bind.tag);
      }
    } else {
      final creator = _bind.createSource;
      if (creator != null) {
        _controllerBuilder = () => creator(context);
        Sint.spawn<T>(_controllerBuilder!, tag: _bind.tag, permanent: false);
        if (!isRegistered) {
          _ownedDependency = Sint.captureInstanceLifecycle<T>(tag: _bind.tag);
        }
        _isCreator = true;
        _needStart = true;
      } else if (_bind.init != null) {
        _controllerBuilder = _bind.init;
        _isCreator = true;
        _needStart = true;
      } else if (isRegistered) {
        _controllerBuilder = () => Sint.find<T>(tag: _bind.tag);
        _ownedDependency = Sint.captureInstanceLifecycle<T>(tag: _bind.tag);
        _isCreator = true;
        _needStart = false;
      } else {
        _isCreator = true;
        _needStart = true;
      }
    }
  }

  void updateBind(Bind<dynamic> next, void Function(Type type) onDirty) {
    final oldId = _bind.id;
    _bind = next as Bind<T>;
    if (oldId != _bind.id && _wasStarted) {
      _subscribeToController(onDirty);
    }
  }

  Object? resolveUntyped(void Function(Type type) onDirty) =>
      resolveController(onDirty);

  T resolveController(void Function(Type type) onDirty) {
    final existing = _controller;
    if (existing != null) return existing;

    final created = _controllerBuilder?.call();
    if (created == null) {
      throw BindError(controller: T, tag: _bind.tag);
    }
    _controller = created;
    _subscribeToController(onDirty);
    if (_bind.global && (_isCreator || _bind.assignId)) {
      _ownedDependency = Sint.captureInstanceLifecycle<T>(tag: _bind.tag);
    }
    return created;
  }

  void _subscribeToController(void Function(Type type) onDirty) {
    final localController = _controller;
    if (localController == null) return;

    if (_bind.filter != null) {
      _filter = _bind.filter!(localController);
    }
    void notifyDirty() {
      onDirty(T);
      for (final extra in _bind.extraBoundTypes) {
        if (extra != T) onDirty(extra);
      }
    }

    void triggerUpdate() => notifyDirty();
    void filteredUpdate() {
      final newFilter = _bind.filter!(_controller as T);
      if (newFilter != _filter) {
        _filter = newFilter;
        notifyDirty();
      }
    }

    final listener = _bind.filter != null ? filteredUpdate : triggerUpdate;

    if (_needStart && localController is SintLifeCycleMixin) {
      localController.onStart();
      _needStart = false;
      _wasStarted = true;
    }

    if (localController is SintController) {
      _remove?.call();
      _remove = (_bind.id == null)
          ? localController.addListener(listener)
          : localController.addListenerId(_bind.id, listener);
    } else if (localController is Listenable) {
      _remove?.call();
      localController.addListener(listener);
      _remove = () => localController.removeListener(listener);
    } else if (localController is StreamController) {
      _remove?.call();
      final sub = localController.stream.listen((_) => listener());
      _remove = sub.cancel;
    }
  }

  void unmountSlot() {
    _bind.onUnmountCallback?.call();
    if (_isCreator || _bind.assignId) {
      if (_bind.autoRemove) {
        _ownedDependency?.delete();
        final controller = _controller;
        if (!_bind.global && controller is SintLifeCycleMixin) {
          controller.onDelete();
        }
      }
    }
    _remove?.call();
    _remove = null;
    _controller = null;
    _ownedDependency = null;
    _controllerBuilder = null;
    _filter = null;
  }
}
