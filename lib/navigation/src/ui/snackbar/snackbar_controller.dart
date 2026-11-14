import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sint/core/sint_core.dart';
import 'package:sint/navigation/src/domain/enums/snackbar_position.dart';
import 'package:sint/navigation/src/domain/enums/snackbar_status.dart';
import 'package:sint/navigation/src/domain/enums/snack_hover_state.dart';
import 'package:sint/navigation/src/domain/extensions/navigation_extensions.dart';
import 'package:sint/navigation/src/ui/snackbar/snackbar.dart';
import 'package:sint/navigation/src/ui/sint_root.dart';
import 'package:sint/navigation/src/domain/navigation_typedef.dart';

class SnackbarController {
  final key = GlobalKey<SintSnackBarState>();

  static bool get isSnackbarBeingShown =>
      SintRoot.treeInitialized &&
      SintRootState.controller.config.snackBarQueue.isJobInProgress;

  late Animation<double> _filterBlurAnimation;
  late Animation<Color?> _filterColorAnimation;

  final SintSnackBar snackbar;
  final _transitionCompleter = Completer();

  SnackbarStatusCallback? _snackbarStatus;
  Alignment? _initialAlignment;
  Alignment? _endAlignment;

  bool _wasDismissedBySwipe = false;

  bool _onTappedDismiss = false;

  Timer? _timer;

  /// The animation that drives the route's transition and the previous route's
  /// forward transition.
  late final Animation<Alignment> _animation;

  /// The animation controller that the route uses to drive the transitions.
  ///
  /// The animation itself is exposed by the [animation] property.
  late final AnimationController controller;
  bool _hasController = false;
  bool _isDisposed = false;

  SnackbarStatus? _currentStatus;

  final _overlayEntries = <OverlayEntry>[];

  OverlayState? _overlayState;

  SnackbarController(this.snackbar);

  Future<void> get future => _transitionCompleter.future;

  /// Close the snackbar with animation
  Future<void> close({bool withAnimations = true}) async {
    if (!withAnimations) {
      removeOverlay();
      return;
    }
    _removeEntry();
    await future;
  }

  /// Adds SintSnackBar to a view queue.
  /// Only one SintSnackBar will be displayed at a time, and this method returns
  /// a future to when the snackbar disappears.
  Future<void> show() {
    return SintRootState.controller.config.snackBarQueue.addJob(this);
  }

  void _cancelTimer() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
  }

  // ignore: avoid_returning_this
  void _configureAlignment(SnackPosition snackPosition) {
    switch (snackbar.snackPosition) {
      case SnackPosition.top:
        {
          _initialAlignment = const Alignment(-1.0, -2.0);
          _endAlignment = const Alignment(-1.0, -1.0);
          break;
        }
      case SnackPosition.bottom:
        {
          _initialAlignment = const Alignment(-1.0, 2.0);
          _endAlignment = const Alignment(-1.0, 1.0);
          break;
        }
    }
  }

  bool _isTesting = false;

  void _configureOverlay() {
    if (_isDisposed) return;
    final resolvedOverlay = Sint.key.currentState?.overlay;
    _isTesting = Sint.overlayContext == null ||
        resolvedOverlay == null ||
        !resolvedOverlay.mounted;
    if (_isTesting) {
      _currentStatus = SnackbarStatus.closed;
      _snackbarStatus?.call(_currentStatus);
      if (!_transitionCompleter.isCompleted) {
        _transitionCompleter.complete();
      }
      return;
    }
    _overlayState = resolvedOverlay;
    _overlayEntries.clear();
    _overlayEntries.addAll(_createOverlayEntries(_getBodyWidget()));
    _overlayState!.insertAll(_overlayEntries);

    _configureSnackBarDisplay();
  }

  void _configureSnackBarDisplay() {
    if (_isDisposed || _transitionCompleter.isCompleted) return;
    controller = _createAnimationController();
    _hasController = true;
    _configureAlignment(snackbar.snackPosition);
    _snackbarStatus = snackbar.snackbarStatus;
    _filterBlurAnimation = _createBlurFilterAnimation();
    _filterColorAnimation = _createColorOverlayColor();
    _animation = _createAnimation();
    _animation.addStatusListener(_handleStatusChanged);
    _configureTimer();
    controller.forward();
  }

  void _configureTimer() {
    if (snackbar.duration != null) {
      if (_timer != null && _timer!.isActive) {
        _timer!.cancel();
      }
      _timer = Timer(snackbar.duration!, _removeEntry);
    } else {
      if (_timer != null) {
        _timer!.cancel();
      }
    }
  }

  /// Called to create the animation that exposes the current progress of
  /// the transition controlled by the animation controller created by
  /// `createAnimationController()`.
  Animation<Alignment> _createAnimation() {
    assert(!_transitionCompleter.isCompleted,
        'Cannot create a animation from a disposed snackbar');
    return AlignmentTween(begin: _initialAlignment, end: _endAlignment).animate(
      CurvedAnimation(
        parent: controller,
        curve: snackbar.forwardAnimationCurve,
        reverseCurve: snackbar.reverseAnimationCurve,
      ),
    );
  }

  /// Called to create the animation controller that will drive the transitions
  /// to this route from the previous one, and back to the previous route
  /// from this one.
  AnimationController _createAnimationController() {
    assert(!_transitionCompleter.isCompleted,
        'Cannot create a animationController from a disposed snackbar');
    assert(snackbar.animationDuration >= Duration.zero);
    return AnimationController(
      duration: snackbar.animationDuration,
      debugLabel: '$runtimeType',
      vsync: _overlayState!,
    );
  }

  Animation<double> _createBlurFilterAnimation() {
    return Tween(begin: 0.0, end: snackbar.overlayBlur).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(
          0.0,
          0.35,
          curve: Curves.easeInOutCirc,
        ),
      ),
    );
  }

  Animation<Color?> _createColorOverlayColor() {
    return ColorTween(
            begin: const Color(0x00000000), end: snackbar.overlayColor)
        .animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(
          0.0,
          0.35,
          curve: Curves.easeInOutCirc,
        ),
      ),
    );
  }

  Iterable<OverlayEntry> _createOverlayEntries(Widget child) {
    return <OverlayEntry>[
      if (snackbar.overlayBlur > 0.0) ...[
        OverlayEntry(
          builder: (context) => GestureDetector(
            onTap: () {
              if (snackbar.isDismissible && !_onTappedDismiss) {
                _onTappedDismiss = true;
                close();
              }
            },
            child: AnimatedBuilder(
              animation: _filterBlurAnimation,
              builder: (context, child) {
                return BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: max(0.001, _filterBlurAnimation.value),
                    sigmaY: max(0.001, _filterBlurAnimation.value),
                  ),
                  child: Container(
                    constraints: const BoxConstraints.expand(),
                    color: _filterColorAnimation.value,
                  ),
                );
              },
            ),
          ),
          maintainState: false,
          opaque: false,
        ),
      ],
      OverlayEntry(
        builder: (context) => Semantics(
          focused: false,
          container: true,
          explicitChildNodes: true,
          child: AlignTransition(
            alignment: _animation,
            child: snackbar.isDismissible
                ? _getDismissibleSnack(child)
                : _getSnackbarContainer(child),
          ),
        ),
        maintainState: false,
        opaque: false,
      ),
    ];
  }

  Widget _getBodyWidget() {
    return Builder(builder: (_) {
      return MouseRegion(
        onEnter: (_) =>
            snackbar.onHover?.call(snackbar, SnackHoverState.entered),
        onExit: (_) => snackbar.onHover?.call(snackbar, SnackHoverState.exited),
        child: GestureDetector(
          behavior: snackbar.hitTestBehavior ?? HitTestBehavior.deferToChild,
          onTap: snackbar.onTap != null
              ? () => snackbar.onTap?.call(snackbar)
              : null,
          child: snackbar,
        ),
      );
    });
  }

  DismissDirection _getDefaultDismissDirection() {
    if (snackbar.snackPosition == SnackPosition.top) {
      return DismissDirection.up;
    }
    return DismissDirection.down;
  }

  Widget _getDismissibleSnack(Widget child) {
    return Dismissible(
      behavior: snackbar.hitTestBehavior ?? HitTestBehavior.opaque,
      direction: snackbar.dismissDirection ?? _getDefaultDismissDirection(),
      resizeDuration: null,
      confirmDismiss: (_) {
        if (_currentStatus == SnackbarStatus.opening ||
            _currentStatus == SnackbarStatus.closing) {
          return Future.value(false);
        }
        return Future.value(true);
      },
      key: const Key('dismissible'),
      onDismissed: (_) {
        _wasDismissedBySwipe = true;
        _removeEntry();
      },
      child: _getSnackbarContainer(child),
    );
  }

  Widget _getSnackbarContainer(Widget child) {
    return Container(
      margin: snackbar.margin,
      child: child,
    );
  }

  void _handleStatusChanged(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.completed:
        _currentStatus = SnackbarStatus.open;
        _snackbarStatus?.call(_currentStatus);
        if (_overlayEntries.isNotEmpty) _overlayEntries.first.opaque = false;

        break;
      case AnimationStatus.forward:
        _currentStatus = SnackbarStatus.opening;
        _snackbarStatus?.call(_currentStatus);
        break;
      case AnimationStatus.reverse:
        _currentStatus = SnackbarStatus.closing;
        _snackbarStatus?.call(_currentStatus);
        if (_overlayEntries.isNotEmpty) _overlayEntries.first.opaque = false;
        break;
      case AnimationStatus.dismissed:
        assert(!_overlayEntries.first.opaque);
        _currentStatus = SnackbarStatus.closed;
        _snackbarStatus?.call(_currentStatus);
        removeOverlay();
        break;
    }
  }

  void _removeEntry() {
    if (_isDisposed || _transitionCompleter.isCompleted) return;

    _cancelTimer();

    if (!_hasController) {
      removeOverlay();
      return;
    }

    if (_wasDismissedBySwipe) {
      _timer = Timer(const Duration(milliseconds: 200), () {
        if (!_isDisposed && _hasController) {
          controller.reset();
        }
        removeOverlay();
      });
      _wasDismissedBySwipe = false;
    } else {
      controller.reverse();
    }
  }

  void removeOverlay() {
    if (_isDisposed) return;
    _isDisposed = true;
    _cancelTimer();
    if (!_isTesting) {
      for (var element in _overlayEntries) {
        if (element.mounted) {
          element.remove();
        }
      }
    }

    if (_hasController) {
      controller.dispose();
    }
    _overlayEntries.clear();
    if (!_transitionCompleter.isCompleted) {
      _transitionCompleter.complete();
    }
  }

  Future<void> showOverlay() {
    _configureOverlay();
    return future;
  }

  static Future<void> cancelAllSnackbars() async {
    if (!SintRoot.treeInitialized) return;
    await SintRootState.controller.config.snackBarQueue.cancelAllJobs();
  }

  static Future<void> closeCurrentSnackbar() async {
    if (!SintRoot.treeInitialized) return;
    await SintRootState.controller.config.snackBarQueue.closeCurrentJob();
  }
}
