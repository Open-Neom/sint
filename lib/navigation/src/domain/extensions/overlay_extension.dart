import 'package:flutter/widgets.dart';
import 'package:sint/core/sint_core.dart';
import 'package:sint/navigation/src/domain/extensions/navigation_extensions.dart';

extension OverlayExtension on SintInterface {
  Future<T> showOverlay<T>({
    required Future<T> Function() asyncFunction,
    Color opacityColor = const Color(0xFF000000),
    Widget? loadingWidget,
    double opacity = .5,
  }) async {
    final overlayCtx = Sint.overlayContext;
    final navigatorState = overlayCtx != null
        ? Navigator.of(overlayCtx, rootNavigator: false)
        : resolveNavigator(rootNavigator: false)!;
    final overlayState = navigatorState.overlay!;

    final overlayEntryOpacity = OverlayEntry(
      builder: (context) {
        return Opacity(
          opacity: opacity,
          child: Container(color: opacityColor),
        );
      },
    );
    final overlayEntryLoader = OverlayEntry(
      builder: (context) {
        return loadingWidget ??
            const Center(
              child: SizedBox(height: 90, width: 90, child: Text('Loading...')),
            );
      },
    );
    overlayState.insert(overlayEntryOpacity);
    overlayState.insert(overlayEntryLoader);

    try {
      return await asyncFunction();
    } finally {
      if (overlayEntryLoader.mounted) {
        overlayEntryLoader.remove();
      }
      if (overlayEntryOpacity.mounted) {
        overlayEntryOpacity.remove();
      }
    }
  }
}
