import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:sint/state_manager/src/domain/typedefs/state_typedefs.dart';
import 'package:sint/state_manager/src/engine/list_notifier.dart';

/// Holds reactive subscription state for a single `Obx` element or `Computed`
/// signal.
///
/// Uses an inline **Single-Source Fast Slot** (`0` collection allocations when
/// observing a single [ListNotifier], which covers ~85%+ of `Obx` widgets in
/// production) and lazily promotes to identity `HashMap`/`HashSet` structures
/// only when `>= 2` sources or external Flutter [Listenable]s are observed.
class NotifyData {
  NotifyData({
    required this.updater,
    this.throwException = true,
    this.onMarkCheck,
  });

  final SintStateUpdate updater;
  final bool throwException;

  /// Optional dirty-check propagation callback used by `Computed<T>` so
  /// diamond dependency graphs settle glitch-free without eager recomputation.
  final VoidCallback? onMarkCheck;

  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  // ── Inline Single-Source Fast Slot (0 heap collections for 1-signal Obx) ──
  ListNotifier? _primarySource;
  Disposer? _primaryDisposer;
  bool _primaryActive = false;

  // ── Lazy Multi-Source ListNotifier Reconciliation ─────────────────────────
  Map<ListNotifier, Disposer>? _trackedSubscriptions;
  Set<ListNotifier>? _activeSources;

  // ── Lazy Incremental External Flutter Listenable Reconciliation ───────────
  Map<Listenable, Disposer>? _externalSubscriptions;
  Set<Listenable>? _activeExternals;

  // ── Lazy Direct Disposers (e.g. Rx.bindStream inside Obx) ─────────────────
  List<VoidCallback>? _disposers;

  /// Lazily materialized list of one-pass disposers (`reportAdd`).
  List<VoidCallback> get disposers => _disposers ??= <VoidCallback>[];

  /// Resets per-pass tracking markers prior to evaluating `builder()`.
  @pragma('vm:prefer-inline')
  void beginPass() {
    final direct = _disposers;
    if (direct != null && direct.isNotEmpty) {
      for (final disposer in direct) {
        disposer();
      }
      direct.clear();
    }
    _primaryActive = false;
    _activeSources?.clear();
    _activeExternals?.clear();
  }

  @pragma('vm:prefer-inline')
  Disposer _subscribe(ListNotifier source) {
    final markCheck = onMarkCheck;
    if (markCheck != null) {
      return source.addComputedListener(updater, markCheck);
    }
    return source.addListener(updater);
  }

  /// Invokes [visitor] for each currently tracked [ListNotifier] dependency.
  void visitTrackedNotifiers(void Function(ListNotifier source) visitor) {
    if (_isDisposed) return;
    final primary = _primarySource;
    if (primary != null) {
      visitor(primary);
      return;
    }
    final tracked = _trackedSubscriptions;
    if (tracked != null && tracked.isNotEmpty) {
      for (final source in tracked.keys.toList(growable: false)) {
        if (_isDisposed) return;
        visitor(source);
      }
    }
  }

  /// Records a [ListNotifier] read inside the active pass.
  @pragma('vm:prefer-inline')
  void trackListNotifier(ListNotifier source) {
    if (_isDisposed) return;

    final tracked = _trackedSubscriptions;
    if (tracked == null) {
      final primary = _primarySource;
      if (identical(source, primary)) {
        _primaryActive = true;
        return;
      }
      if (primary == null) {
        final disposer = _subscribe(source);
        _primarySource = source;
        _primaryDisposer = disposer;
        _primaryActive = true;
        return;
      }
      // Subscribe to the 2nd source BEFORE promoting so an exception from
      // `addListener` (e.g. disposed notifier) leaves the 1-slot state intact.
      final secondDisposer = _subscribe(source);
      final map = HashMap<ListNotifier, Disposer>.identity();
      map[primary] = _primaryDisposer!;
      map[source] = secondDisposer;
      final active = HashSet<ListNotifier>.identity();
      if (_primaryActive) {
        active.add(primary);
      }
      active.add(source);
      _primarySource = null;
      _primaryDisposer = null;
      _primaryActive = false;
      _trackedSubscriptions = map;
      _activeSources = active;
      return;
    }

    if (!tracked.containsKey(source)) {
      tracked[source] = _subscribe(source);
    }
    (_activeSources ??= HashSet<ListNotifier>.identity()).add(source);
  }

  /// Records an external Flutter [Listenable] (`ValueNotifier`, `Animation`,
  /// `TextEditingController`, etc.) with incremental subscription reuse across
  /// rebuilds.
  void trackExternal(Listenable listenable) {
    if (_isDisposed) return;
    final tracked = (_externalSubscriptions ??=
        HashMap<Listenable, Disposer>.identity());
    if (!tracked.containsKey(listenable)) {
      listenable.addListener(updater);
      tracked[listenable] = () => listenable.removeListener(updater);
    }
    (_activeExternals ??= HashSet<Listenable>.identity()).add(listenable);
  }

  /// Whether at least one reactive source was read during the current pass.
  @pragma('vm:prefer-inline')
  bool get hasActiveSubscriptions =>
      _primaryActive ||
      (_activeSources != null && _activeSources!.isNotEmpty) ||
      (_activeExternals != null && _activeExternals!.isNotEmpty) ||
      (_disposers != null && _disposers!.isNotEmpty);

  /// Prunes any subscriptions that were not read during the completed pass.
  @pragma('vm:prefer-inline')
  void endPass() {
    if (_primarySource != null && !_primaryActive) {
      final disposer = _primaryDisposer;
      _primarySource = null;
      _primaryDisposer = null;
      disposer?.call();
    }

    final tracked = _trackedSubscriptions;
    final active = _activeSources;
    if (tracked != null && active != null && tracked.length > active.length) {
      List<ListNotifier>? stale;
      for (final source in tracked.keys) {
        if (!active.contains(source)) {
          (stale ??= <ListNotifier>[]).add(source);
        }
      }
      if (stale != null) {
        for (final source in stale) {
          tracked.remove(source)?.call();
        }
      }
      active.clear();
    } else {
      active?.clear();
    }

    final extTracked = _externalSubscriptions;
    final extActive = _activeExternals;
    if (extTracked != null &&
        extActive != null &&
        extTracked.length > extActive.length) {
      List<Listenable>? staleExt;
      for (final source in extTracked.keys) {
        if (!extActive.contains(source)) {
          (staleExt ??= <Listenable>[]).add(source);
        }
      }
      if (staleExt != null) {
        for (final source in staleExt) {
          extTracked.remove(source)?.call();
        }
      }
      extActive.clear();
    } else {
      extActive?.clear();
    }
  }

  /// Releases all tracked subscriptions permanently on unmount / disposal.
  void disposeAll() {
    if (_isDisposed) return;
    _isDisposed = true;

    final primaryDisp = _primaryDisposer;
    _primarySource = null;
    _primaryDisposer = null;
    _primaryActive = false;
    primaryDisp?.call();

    final subs = _trackedSubscriptions;
    _trackedSubscriptions = null;
    _activeSources?.clear();
    _activeSources = null;
    if (subs != null) {
      for (final disposer in subs.values) {
        disposer();
      }
      subs.clear();
    }

    final extSubs = _externalSubscriptions;
    _externalSubscriptions = null;
    _activeExternals?.clear();
    _activeExternals = null;
    if (extSubs != null) {
      for (final disposer in extSubs.values) {
        disposer();
      }
      extSubs.clear();
    }

    final direct = _disposers;
    _disposers = null;
    if (direct != null) {
      for (final disposer in direct) {
        disposer();
      }
      direct.clear();
    }
  }
}
