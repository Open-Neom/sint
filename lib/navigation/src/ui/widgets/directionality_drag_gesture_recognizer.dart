
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';


class DirectionalityDragGestureRecognizer extends HorizontalDragGestureRecognizer {
  final ValueGetter<bool> popGestureEnable;
  final ValueGetter<bool> hasbackGestureController;
  final bool isRTL;
  final bool isLTR;

  DirectionalityDragGestureRecognizer({
    required this.isRTL,
    required this.isLTR,
    required this.popGestureEnable,
    required this.hasbackGestureController,
    super.debugOwner,
  });

  @override
  void handleEvent(PointerEvent event) {
    final dx = event.delta.dx;
    if (hasbackGestureController() ||
        popGestureEnable() && (isRTL && dx < 0 || isLTR && dx > 0 || dx == 0)) {
      super.handleEvent(event);
    } else {
      stopTrackingPointer(event.pointer);
    }
  }
}