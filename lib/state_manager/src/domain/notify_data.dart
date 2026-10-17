
import 'package:sint/state_manager/src/domain/typedefs/state_typedefs.dart';
import 'package:sint/state_manager/src/engine/list_notifier.dart';

class NotifyData {
  const NotifyData({
    required this.updater,
    required this.disposers,
    this.throwException = true,
    this.trackedSubscriptions,
    this.activeSources,
  });

  final SintStateUpdate updater;
  final List<VoidCallback> disposers;
  final bool throwException;

  /// Persistent map of active [ListNotifier] subscriptions for incremental
  /// $O(1)$ steady-state reconciliation across rebuilds.
  final Map<ListNotifier, Disposer>? trackedSubscriptions;

  /// Scratch set populated during a build/compute pass to identify which
  /// [ListNotifier] sources were read in the current pass.
  final Set<ListNotifier>? activeSources;
}