
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sint/state_manager/src/engine/sint_controller.dart';


/// Used like `TickerProviderMixin` but only with Sint Controllers.
/// Simplifies multiple AnimationController creation inside SintController.
///
/// Example:
///```
///class SplashController extends SintController with
///    SintTickerProviderStateMixin {
///  AnimationController first_controller;
///  AnimationController second_controller;
///
///  @override
///  void onInit() {
///    final duration = const Duration(seconds: 2);
///    first_controller =
///        AnimationController.unbounded(duration: duration, vsync: this);
///    second_controller =
///        AnimationController.unbounded(duration: duration, vsync: this);
///    first_controller.repeat();
///    first_controller.addListener(() =>
///        print("Animation Controller value: ${first_controller.value}"));
///    second_controller.addListener(() =>
///        print("Animation Controller value: ${second_controller.value}"));
///  }
///  ...
/// ```
mixin SintTickerProviderStateMixin on SintController implements TickerProvider {
  Set<Ticker>? _tickers;

  @override
  Ticker createTicker(TickerCallback onTick) {
    _tickers ??= <_WidgetTicker>{};
    final result = _WidgetTicker(onTick, this,
        debugLabel: kDebugMode ? 'created by ${describeIdentity(this)}' : null);
    _tickers!.add(result);
    return result;
  }

  void _removeTicker(_WidgetTicker ticker) {
    assert(_tickers != null);
    assert(_tickers!.contains(ticker));
    _tickers!.remove(ticker);
  }

  void didChangeDependencies(BuildContext context) {
    final muted = !TickerMode.of(context);
    if (_tickers != null) {
      for (final ticker in _tickers!) {
        ticker.muted = muted;
      }
    }
  }

  @override
  void onClose() {
    assert(() {
      if (_tickers != null) {
        for (final ticker in _tickers!) {
          if (ticker.isActive) {
            throw FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary('$this was disposed with an active Ticker.'),
              ErrorDescription(
                '$runtimeType created a Ticker via its GetTickerProviderStateMixin, but at the time '
                'dispose() was called on the mixin, that Ticker was still active. All Tickers must '
                'be disposed before calling super.dispose().',
              ),
              ErrorHint(
                'Tickers used by AnimationControllers '
                'should be disposed by calling dispose() on the AnimationController itself. '
                'Otherwise, the ticker will leak.',
              ),
              ticker.describeForError('The offending ticker was'),
            ]);
          }
        }
      }
      return true;
    }());
    super.onClose();
  }
}

class _WidgetTicker extends Ticker {
  _WidgetTicker(super.onTick, this._creator, {super.debugLabel});

  final SintTickerProviderStateMixin _creator;

  @override
  void dispose() {
    _creator._removeTicker(this);
    super.dispose();
  }
}
