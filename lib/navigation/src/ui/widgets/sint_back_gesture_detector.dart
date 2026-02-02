import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sint/navigation/src/ui/widgets/sint_back_gesture_controller.dart';
import 'package:sint/sint.dart';

class SintBackGestureDetector<T> extends StatefulWidget {
  const SintBackGestureDetector({
    super.key,
    required this.limitedSwipe,
    required this.gestureWidth,
    required this.initialOffset,
    required this.popGestureEnable,
    required this.onStartPopGesture,
    required this.child,
  });

  final bool limitedSwipe;
  final double gestureWidth;
  final double initialOffset;

  final Widget child;
  final ValueGetter<bool> popGestureEnable;
  final ValueGetter<SintBackGestureController<T>> onStartPopGesture;

  @override
  SintBackGestureDetectorState<T> createState() =>
      SintBackGestureDetectorState<T>();
}

class SintBackGestureDetectorState<T> extends State<SintBackGestureDetector<T>> {
  SintBackGestureController<T>? _backGestureController;

  void _handleDragStart(DragStartDetails details) {
    assert(mounted);
    assert(_backGestureController == null);
    _backGestureController = widget.onStartPopGesture();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    assert(mounted);
    assert(_backGestureController != null);
    _backGestureController!.dragUpdate(
      _convertToLogical(details.primaryDelta! / context.size!.width),
    );
  }

  void _handleDragEnd(DragEndDetails details) {
    assert(mounted);
    assert(_backGestureController != null);
    _backGestureController!.dragEnd(_convertToLogical(
      details.velocity.pixelsPerSecond.dx / context.size!.width,
    ));
    _backGestureController = null;
  }

  void _handleDragCancel() {
    assert(mounted);
    // This can be called even if start is not called, paired with the "down"
    // event that we don't consider here.
    _backGestureController?.dragEnd(0);
    _backGestureController = null;
  }

  double _convertToLogical(double value) {
    switch (Directionality.of(context)) {
      case TextDirection.rtl:
        return -value;
      case TextDirection.ltr:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));

    final gestureDetector = RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: {
        DirectionalityDragGestureRecognizer:
        GestureRecognizerFactoryWithHandlers<
            DirectionalityDragGestureRecognizer>(
              () {
            final directionality = Directionality.of(context);
            return DirectionalityDragGestureRecognizer(
              debugOwner: this,
              isRTL: directionality == TextDirection.rtl,
              isLTR: directionality == TextDirection.ltr,
              hasbackGestureController: () => _backGestureController != null,
              popGestureEnable: widget.popGestureEnable,
            );
          },
              (directionalityDragGesture) => directionalityDragGesture
            ..onStart = _handleDragStart
            ..onUpdate = _handleDragUpdate
            ..onEnd = _handleDragEnd
            ..onCancel = _handleDragCancel,
        )
      },
    );

    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        if (widget.limitedSwipe)
          PositionedDirectional(
            start: widget.initialOffset,
            width: _dragAreaWidth(context),
            top: 0,
            bottom: 0,
            child: gestureDetector,
          )
        else
          Positioned.fill(child: gestureDetector),
      ],
    );
  }

  double _dragAreaWidth(BuildContext context) {
    // For devices with notches, the drag area needs to be larger on the side
    // that has the notch.
    final dragAreaWidth = Directionality.of(context) == TextDirection.ltr
        ? context.mediaQuery.padding.left
        : context.mediaQuery.padding.right;
    return max(dragAreaWidth, widget.gestureWidth);
  }
}
