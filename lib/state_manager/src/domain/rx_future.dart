import 'dart:async';

import 'package:sint/core/src/domain/models/rx_custom.dart';
import 'package:sint/state_manager/src/domain/sint_status.dart';

/// Reactive async state holder built on [Rx] and [SintStatus].
///
/// Automatically transitions between [LoadingStatus], [SuccessStatus],
/// [EmptyStatus], and [ErrorStatus], supports stale-while-revalidate via
/// [revalidate], and discards stale out-of-order responses when [reload]
/// or [revalidate] is called again before an earlier Future completes.
///
/// ```dart
/// class ProfileController extends SintController {
///   late final user = rxFuture(() => api.fetchUser());
/// }
/// ```
class RxFuture<T> extends Rx<SintStatus<T>> {
  RxFuture(
    this._loader, {
    bool immediate = true,
    this.isEmpty,
  }) : super(
          immediate ? SintStatus<T>.loading() : SintStatus<T>.empty(),
        ) {
    if (immediate) {
      unawaited(reload());
    }
  }

  /// Creates an [RxFuture] that starts in [EmptyStatus] without running
  /// the loader until [reload] or [revalidate] is invoked.
  RxFuture.idle(
    this._loader, {
    this.isEmpty,
  }) : super(SintStatus<T>.empty());

  Future<T> Function() _loader;
  final bool Function(T data)? isEmpty;
  int _requestId = 0;

  /// Executes [task] and captures its outcome into a [SintStatus] without
  /// throwing (`SuccessStatus` on completion, `ErrorStatus` on exception).
  static Future<SintStatus<T>> guard<T>(
    Future<T> Function() task, {
    T? previousData,
    bool Function(T data)? isEmpty,
  }) async {
    try {
      final result = await task();
      if (isEmpty != null && isEmpty(result)) {
        return SintStatus<T>.empty();
      }
      return SintStatus<T>.success(result);
    } catch (error) {
      return SintStatus<T>.error(error, previousData: previousData);
    }
  }

  /// Replaces the async loader and triggers a fresh [reload] (retaining
  /// previous data when [keepPreviousData] is `true`).
  Future<SintStatus<T>> run(
    Future<T> Function() nextLoader, {
    bool keepPreviousData = false,
  }) {
    _loader = nextLoader;
    return reload(keepPreviousData: keepPreviousData);
  }

  /// Reloads while preserving the latest [dataOrNull] inside [LoadingStatus]
  /// (`isRefreshing == true`) for stale-while-revalidate UIs.
  Future<SintStatus<T>> revalidate() => reload(keepPreviousData: true);

  /// Executes the loader and updates [value] to the resulting [SintStatus].
  ///
  /// Any earlier in-flight call is superseded so out-of-order completions
  /// never overwrite newer state.
  Future<SintStatus<T>> reload({bool keepPreviousData = false}) async {
    if (isDisposed) return peek;
    final currentRequestId = ++_requestId;
    final retained = keepPreviousData ? peek.dataOrNull : null;
    value = retained != null
        ? SintStatus<T>.refreshing(retained)
        : SintStatus<T>.loading();

    try {
      final result = await _loader();
      if (isDisposed || currentRequestId != _requestId) return peek;
      final next = (isEmpty != null && isEmpty!(result))
          ? SintStatus<T>.empty()
          : SintStatus<T>.success(result);
      value = next;
      return next;
    } catch (error) {
      if (isDisposed || currentRequestId != _requestId) return peek;
      final next = SintStatus<T>.error(error, previousData: retained);
      value = next;
      return next;
    }
  }

  @override
  void dispose() {
    _requestId++;
    super.dispose();
  }
}
