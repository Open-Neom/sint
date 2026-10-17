import 'dart:collection';
import 'package:sint/state_manager/src/domain/notify_data.dart';
import 'package:sint/state_manager/src/domain/typedefs/state_typedefs.dart';
import 'package:sint/state_manager/src/engine/list_notifier.dart';
import 'package:sint/state_manager/src/engine/notifier.dart';
import 'package:sint/state_manager/src/sint_listenable.dart';

/// A memoized, derived reactive value for Pillar S (`Sint.computed`).
///
/// Automatically tracks any `Rx` or [ListNotifier] sources read inside
/// [_compute] using SINT's incremental subscription reconciliation engine,
/// and only notifies downstream listeners (`Obx`, `ever`, `stream`, or other
/// [Computed] instances) when the recomputed value actually changes (`!=`).
class Computed<T> extends SintListenable<T> {
  factory Computed(T Function() compute) {
    final subscriptions = HashMap<ListNotifier, Disposer>.identity();
    final directDisposers = <Disposer>[];
    late Computed<T> instance;
    void handleDependencyChanged() => instance._onDependencyChanged();
    final notifyData = NotifyData(
      disposers: directDisposers,
      updater: handleDependencyChanged,
      throwException: false,
      trackedSubscriptions: subscriptions,
      activeSources: HashSet<ListNotifier>.identity(),
    );

    final initial = Notifier.instance.append(notifyData, compute);

    instance = Computed._(
      compute,
      initial,
      subscriptions,
      directDisposers,
      notifyData,
    );
    return instance;
  }

  Computed._(
    this._compute,
    super.initial,
    this._subscriptions,
    this._directDisposers,
    this._notifyData,
  ) : _lastNotifiedValue = initial;

  final T Function() _compute;
  final NotifyData _notifyData;
  Map<ListNotifier, Disposer>? _subscriptions;
  List<Disposer>? _directDisposers;
  T _lastNotifiedValue;
  bool _isComputing = false;
  bool _queuedInBatch = false;

  @override
  T get value {
    reportRead();
    if (ListNotifier.isBatching && !isDisposed && !_isComputing) {
      rawValue = _evaluate();
    }
    return rawValue;
  }

  @override
  T get peek {
    if (ListNotifier.isBatching && !isDisposed && !_isComputing) {
      rawValue = _evaluate();
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
    final subs = _subscriptions;
    final direct = _directDisposers;
    if (subs == null || direct == null) {
      return rawValue;
    }
    if (direct.isNotEmpty) {
      for (final disposer in direct) {
        disposer();
      }
      direct.clear();
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
    if (ListNotifier.isFlushingBatch) {
      if (!_queuedInBatch) {
        _queuedInBatch = true;
        ListNotifier.enqueueBatchedComputed(_recomputeAndNotify);
      }
      return;
    }
    _recomputeAndNotify();
  }

  void _recomputeAndNotify() {
    _queuedInBatch = false;
    if (isDisposed || _isComputing) return;
    final next = _evaluate();
    rawValue = next;
    if (next != _lastNotifiedValue) {
      _lastNotifiedValue = next;
      refresh();
    }
  }

  @override
  void dispose() {
    if (isDisposed) return;
    final subs = _subscriptions;
    _subscriptions = null;
    if (subs != null) {
      for (final disposer in subs.values) {
        disposer();
      }
      subs.clear();
    }
    final direct = _directDisposers;
    _directDisposers = null;
    if (direct != null) {
      for (final disposer in direct) {
        disposer();
      }
      direct.clear();
    }
    super.dispose();
  }
}
