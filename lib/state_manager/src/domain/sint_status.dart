import 'package:sint/state_manager/src/domain/mixins/equality_mixin.dart';

/// Algebraic data type for async operation states.
///
/// Declared as a Dart 3 `sealed class` so consumers can use either native
/// exhaustive `switch` expressions/statements OR [when] / [maybeWhen].
///
/// ```dart
/// final status = SintStatus<User>.loading().obs;
///
/// // Native Dart 3 exhaustive switch:
/// Obx(() => switch (controller.status.value) {
///   LoadingStatus(:final previousData) => previousData != null
///       ? Text('${previousData.name} (refreshing...)')
///       : const CircularProgressIndicator(),
///   SuccessStatus(:final data) => Text(data.name),
///   ErrorStatus(:final error) => Text('Error: $error'),
///   EmptyStatus() || CustomStatus() => const Text('No data'),
/// });
/// ```
sealed class SintStatus<T> with Equality {
  const SintStatus();

  factory SintStatus.loading([T? previousData]) =>
      LoadingStatus<T>(previousData);

  /// Loading state that retains [previousData] for stale-while-revalidate UI.
  factory SintStatus.refreshing(T previousData) =>
      LoadingStatus<T>(previousData);

  factory SintStatus.error(Object message, {T? previousData}) =>
      ErrorStatus<T, Object>(message, previousData);

  factory SintStatus.empty() => EmptyStatus<T>();

  factory SintStatus.success(T data) => SuccessStatus<T>(data);

  factory SintStatus.custom() => CustomStatus<T>();

  // ─── Pattern Matching ─────────────────────────────────────

  /// Exhaustive pattern matching — all cases must be handled.
  ///
  /// ```dart
  /// status.when(
  ///   loading: () => showSpinner(),
  ///   success: (data) => showContent(data),
  ///   error: (err) => showError(err),
  ///   empty: () => showEmpty(),
  /// );
  /// ```
  R when<R>({
    required R Function() loading,
    required R Function(T data) success,
    required R Function(Object error) error,
    required R Function() empty,
    R Function()? custom,
  }) =>
      switch (this) {
        SuccessStatus(:final data) => success(data),
        ErrorStatus<Object?, Object?>(error: final err) =>
          error(err ?? 'Unknown error'),
        LoadingStatus() => loading(),
        EmptyStatus() => empty(),
        CustomStatus() => (custom ?? empty)(),
      };

  /// Partial pattern matching with a required [orElse] fallback.
  ///
  /// ```dart
  /// status.maybeWhen(
  ///   success: (data) => showContent(data),
  ///   orElse: () => showSpinner(),
  /// );
  /// ```
  R maybeWhen<R>({
    R Function()? loading,
    R Function(T data)? success,
    R Function(Object error)? error,
    R Function()? empty,
    R Function()? custom,
    required R Function() orElse,
  }) =>
      switch (this) {
        SuccessStatus(:final data) when success != null => success(data),
        ErrorStatus(error: final err) when error != null =>
          error(err ?? 'Unknown error'),
        LoadingStatus() when loading != null => loading(),
        EmptyStatus() when empty != null => empty(),
        CustomStatus() when custom != null => custom(),
        _ => orElse(),
      };

  // ─── Convenience Getters ──────────────────────────────────

  bool get isLoading => this is LoadingStatus<T>;
  bool get isRefreshing =>
      switch (this) { LoadingStatus(previousData: _?) => true, _ => false };
  bool get isSuccess => this is SuccessStatus<T>;
  bool get isError => this is ErrorStatus<T, Object?>;
  bool get isEmpty => this is EmptyStatus<T>;

  /// Returns the data if [isSuccess], or retained `previousData` during
  /// [SintStatus.refreshing] / [SintStatus.error], otherwise `null`.
  T? get dataOrNull => switch (this) {
        SuccessStatus(:final data) => data,
        LoadingStatus(:final previousData) => previousData,
        ErrorStatus<T, Object?>(:final previousData) => previousData,
        ErrorStatus<Object?, Object?>() => null,
        EmptyStatus() || CustomStatus() => null,
      };

  /// Returns the error if [isError], otherwise `null`.
  Object? get errorOrNull => switch (this) {
        ErrorStatus(:final error) => error,
        _ => null,
      };
}

class CustomStatus<T> extends SintStatus<T> {
  const CustomStatus();

  @override
  List get props => const [];
}

class LoadingStatus<T> extends SintStatus<T> {
  final T? previousData;

  const LoadingStatus([this.previousData]);

  @override
  List get props => [previousData];
}

class SuccessStatus<T> extends SintStatus<T> {
  final T data;

  const SuccessStatus(this.data);

  @override
  List get props => [data];
}

class ErrorStatus<T, S> extends SintStatus<T> {
  final S? error;
  final T? previousData;

  const ErrorStatus([this.error, this.previousData]);

  @override
  List get props => [error, previousData];
}

class EmptyStatus<T> extends SintStatus<T> {
  const EmptyStatus();

  @override
  List get props => const [];
}
