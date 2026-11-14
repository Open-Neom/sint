import 'package:sint/state_manager/src/domain/notify_data.dart';
import 'package:sint/state_manager/src/domain/typedefs/state_typedefs.dart';
import 'package:sint/state_manager/src/engine/list_notifier.dart';
import 'package:sint/state_manager/src/engine/notifier.dart';
import 'package:sint/state_manager/src/sint_listenable.dart';

/// A memoized, glitch-free derived reactive value for Pillar S (`Sint.computed`).
///
/// Automatically tracks any `Rx` or [ListNotifier] sources read inside
/// [_compute] using SINT's single-source fast slot / incremental subscription
/// reconciliation engine:
/// - **Glitch-free diamond propagation**: Uses push-dirty / pull-value
///   tri-color state (`clean`, `check`, `dirty`) so diamond dependency graphs
///   recompute each node at most once per update wave without intermediate
///   inconsistent values, both inside and outside `Sint.batch`.
/// - **Optional lazy demand mode (`lazy: true`)**: While no `Obx`, worker
///   (`ever`/`everSync`), or `stream` listener is attached, upstream mutations
///   mark the node dirty in `O(1)` without executing [_compute] until [value],
///   [peek], or a listener demands the current value.
class Computed<T> extends SintListenable<T> {
  static const int _stateClean = 0;
  static const int _stateCheck = 1;
  static const int _stateDirty = 2;

  factory Computed(T Function() compute, {bool lazy = false}) {
    Computed<T>? instance;
    void handleDependencyChanged() => instance?._onDependencyChanged();
    void handleMarkCheck() => instance?._onUpstreamCheck();
    final notifyData = NotifyData(
      updater: handleDependencyChanged,
      onMarkCheck: handleMarkCheck,
      throwException: false,
    );

    final initial = Notifier.instance.append(notifyData, compute);

    instance = Computed._(
      compute,
      initial,
      notifyData,
      lazy: lazy,
    );
    return instance;
  }

  Computed._(
    this._compute,
    super.initial,
    this._notifyData, {
    required this.lazy,
  }) : _lastNotifiedValue = initial;

  /// Whether unobserved upstream mutations defer evaluation until [value],
  /// [peek], or an active listener demands the current result.
  final bool lazy;

  final T Function() _compute;
  final NotifyData _notifyData;
  T _lastNotifiedValue;
  int _state = _stateClean;
  bool _isComputing = false;
  bool _queuedInBatch = false;

  @override
  Disposer addListener(SintStateUpdate listener) {
    if (_state != _stateClean && !isDisposed && !_isComputing) {
      _ensureUpToDate(notifyEagerListeners: false);
    }
    return super.addListener(listener);
  }

  @override
  Disposer addComputedListener(
    SintStateUpdate listener,
    VoidCallback onMarkCheck,
  ) {
    if (_state != _stateClean && !isDisposed && !_isComputing) {
      _ensureUpToDate(notifyEagerListeners: false);
    }
    return super.addComputedListener(listener, onMarkCheck);
  }

  @override
  T get value {
    reportRead();
    if (!isDisposed && !_isComputing) {
      if (ListNotifier.isBatching) {
        rawValue = _evaluate();
      } else if (_state != _stateClean) {
        _ensureUpToDate(notifyEagerListeners: !lazy || hasEagerListeners);
      }
    }
    return rawValue;
  }

  @override
  T get peek {
    if (!isDisposed && !_isComputing) {
      if (ListNotifier.isBatching) {
        rawValue = _evaluate();
      } else if (_state != _stateClean) {
        _ensureUpToDate(notifyEagerListeners: !lazy || hasEagerListeners);
      }
    }
    return rawValue;
  }

  @override
  set value(T newValue) {
    throw UnsupportedError('Cannot assign to a Computed value directly.');
  }

  @override
  T? call([T? v]) {
    if (v != null) {
      throw UnsupportedError('Cannot assign to a Computed value directly.');
    }
    return value;
  }

  T _evaluate() {
    if (_notifyData.isDisposed) {
      return rawValue;
    }
    _isComputing = true;
    try {
      return Notifier.instance.append(_notifyData, _compute);
    } finally {
      _isComputing = false;
    }
  }

  void _onDependencyChanged() {
    if (isDisposed || _isComputing) return;
    final wasClean = _state == _stateClean;
    _state = _stateDirty;
    if (wasClean) {
      propagateComputedCheck();
    }
    _scheduleSettleIfNeeded();
  }

  void _onUpstreamCheck() {
    if (isDisposed || _isComputing) return;
    if (_state == _stateClean) {
      _state = _stateCheck;
      propagateComputedCheck();
    }
    _scheduleSettleIfNeeded();
  }

  void _scheduleSettleIfNeeded() {
    if (lazy && !hasEagerListeners) return;
    if (ListNotifier.isBatching ||
        ListNotifier.isPropagating ||
        ListNotifier.isFlushingBatch) {
      if (!_queuedInBatch) {
        _queuedInBatch = true;
        ListNotifier.enqueueBatchedComputed(_settleFromQueue);
      }
      return;
    }
    _ensureUpToDate(notifyEagerListeners: true);
  }

  void _settleFromQueue() {
    _queuedInBatch = false;
    if (isDisposed || _isComputing || _state == _stateClean) return;
    if (lazy && !hasEagerListeners) return;
    _ensureUpToDate(notifyEagerListeners: true);
  }

  void _ensureUpToDate({required bool notifyEagerListeners}) {
    if (isDisposed || _isComputing || _state == _stateClean) return;

    if (_state == _stateCheck) {
      _notifyData.visitTrackedNotifiers((source) {
        if (_state == _stateDirty) return;
        if (source is Computed) {
          source._ensureUpToDate(
            notifyEagerListeners: !source.lazy || source.hasEagerListeners,
          );
        }
      });
      if (_state == _stateCheck) {
        // Every upstream Computed settled without changing its value.
        _state = _stateClean;
        return;
      }
    }

    if (_state == _stateDirty) {
      _state = _stateClean;
      final next = _evaluate();
      rawValue = next;
      if (next != _lastNotifiedValue) {
        _lastNotifiedValue = next;
        if (notifyEagerListeners || listenersLength > 0) {
          refresh();
        }
      }
    }
  }

  @override
  void dispose() {
    if (isDisposed) return;
    _state = _stateClean;
    _notifyData.disposeAll();
    super.dispose();
  }
}
