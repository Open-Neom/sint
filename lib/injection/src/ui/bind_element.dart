
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sint/sint.dart';

/// The BindElement is responsible for injecting dependencies into the widget
/// tree so that they can be observed
class BindElement<T> extends InheritedElement {
  BindElement(Binder<T> super.widget) {
    initState();
  }

  final disposers = <Disposer>[];

  InitBuilder<T>? _controllerBuilder;

  T? _controller;

  T get controller {
    if (_controller == null) {
      _controller = _controllerBuilder?.call();
      _subscribeToController();
      if (_controller == null) {
        throw BindError(controller: T, tag: widget.tag);
      }
      return _controller!;
    } else {
      return _controller!;
    }
  }

  bool? _isCreator = false;
  bool? _needStart = false;
  bool _wasStarted = false;
  VoidCallback? _remove;
  Object? _filter;

  void initState() {
    widget.initState?.call(this);

    var isRegistered = Sint.isRegistered<T>(tag: widget.tag);

    if (widget.global) {
      if (isRegistered) {
        if (Sint.isPrepared<T>(tag: widget.tag)) {
          _isCreator = true;
        } else {
          _isCreator = false;
        }

        _controllerBuilder = () => Sint.find<T>(tag: widget.tag);
      } else {
        _controllerBuilder =
            () => (widget.create?.call(this) ?? widget.init?.call());
        _isCreator = true;
        if (widget.lazy) {
          Sint.lazyPut<T>(_controllerBuilder!, tag: widget.tag);
        } else {
          Sint.put<T>(_controllerBuilder!(), tag: widget.tag);
        }
      }
    } else {
      if (widget.create != null) {
        _controllerBuilder = () => widget.create!.call(this);
        Sint.spawn<T>(_controllerBuilder!, tag: widget.tag, permanent: false);
      } else {
        _controllerBuilder = widget.init;
      }
      _controllerBuilder =
          (widget.create != null ? () => widget.create!.call(this) : null) ??
              widget.init;
      _isCreator = true;
      _needStart = true;
    }
  }

  /// Register to listen Controller's events.
  /// It gets a reference to the remove() callback, to delete the
  /// setState "link" from the Controller.
  void _subscribeToController() {
    if (widget.filter != null) {
      _filter = widget.filter!(_controller as T);
    }
    final filter = _filter != null ? _filterUpdate : _getUpdate;
    final localController = _controller;

    if (_needStart == true && localController is SintLifeCycleMixin) {
      localController.onStart();
      _needStart = false;
      _wasStarted = true;
    }

    if (localController is SintController) {
      _remove?.call();
      _remove = (widget.id == null)
          ? localController.addListener(filter)
          : localController.addListenerId(widget.id, filter);
    } else if (localController is Listenable) {
      _remove?.call();
      localController.addListener(filter);
      _remove = () => localController.removeListener(filter);
    } else if (localController is StreamController) {
      _remove?.call();
      final stream = localController.stream.listen((_) => filter());
      _remove = () => stream.cancel();
    }
  }

  void _getUpdate() {
    _dirty = true;
    markNeedsBuild();
  }

  void _filterUpdate() {
    var newFilter = widget.filter!(_controller as T);
    if (newFilter != _filter) {
      _filter = newFilter;
      _getUpdate();
    }
  }

  void _dispose() {
    widget.dispose?.call(this);
    if (_isCreator! || widget.assignId) {
      if (widget.autoRemove && Sint.isRegistered<T>(tag: widget.tag)) {
        Sint.delete<T>(tag: widget.tag);
      }
    }

    for (final disposer in disposers) {
      disposer();
    }

    disposers.clear();

    _remove?.call();
    _controller = null;
    _isCreator = null;
    _remove = null;
    _filter = null;
    _needStart = null;
    _controllerBuilder = null;
    _controller = null;
  }

  @override
  Binder<T> get widget => super.widget as Binder<T>;

  var _dirty = false;

  @override
  void update(Binder<T> newWidget) {
    final oldNotifier = widget.id;
    final newNotifier = newWidget.id;
    if (oldNotifier != newNotifier && _wasStarted) {
      _subscribeToController();
    }
    widget.didUpdateWidget?.call(widget, this);
    super.update(newWidget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.didChangeDependencies?.call(this);
  }

  @override
  Widget build() {
    if (_dirty) {
      notifyClients(widget);
    }
    return super.build();
  }


  @override
  void notifyClients(Binder<T> oldWidget) {
    super.notifyClients(oldWidget);
    _dirty = false;
  }

  @override
  void unmount() {
    _dispose();
    super.unmount();
  }
}