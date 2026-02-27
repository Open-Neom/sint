import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sint/core/src/domain/models/rx_interface.dart';

/// Listens to an [Rx] value and calls [listener] on every change
/// **without rebuilding** the widget tree.
///
/// Use this for side effects: showing snackbars, navigating, logging, etc.
/// Equivalent to BLoC's `BlocListener`.
///
/// ```dart
/// SintListener<String>(
///   rx: controller.errorMsg,
///   listener: (value) {
///     if (value.isNotEmpty) Sint.snackbar(value);
///   },
///   child: MyWidget(),
/// )
/// ```
///
/// For multiple listeners, nest them or use workers inside a controller:
/// ```dart
/// SintListener<int>(
///   rx: controller.count,
///   listener: (val) => print('Count: $val'),
///   child: SintListener<String>(
///     rx: controller.name,
///     listener: (val) => print('Name: $val'),
///     child: MyWidget(),
///   ),
/// )
/// ```
class SintListener<T> extends StatefulWidget {
  /// The reactive value to listen to.
  final RxInterface<T> rx;

  /// Called whenever [rx] emits a new value. NOT called during build.
  final void Function(T value) listener;

  /// The child widget (not rebuilt on changes).
  final Widget child;

  const SintListener({
    super.key,
    required this.rx,
    required this.listener,
    required this.child,
  });

  @override
  State<SintListener<T>> createState() => _SintListenerState<T>();
}

class _SintListenerState<T> extends State<SintListener<T>> {
  StreamSubscription<T>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.rx.listen(widget.listener);
  }

  @override
  void didUpdateWidget(covariant SintListener<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rx != widget.rx) {
      _sub?.cancel();
      _sub = widget.rx.listen(widget.listener);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
