import 'package:sint/state_manager/src/domain/mixins/equality_mixin.dart';

/// Algebraic data type for async operation states.
///
/// Inspired by Riverpod's `AsyncValue` — provides exhaustive pattern
/// matching via [when] and [maybeWhen].
///
/// ```dart
/// final status = SintStatus<User>.loading().obs;
///
/// // In widget:
/// Obx(() => controller.status.value.when(
///   loading: () => CircularProgressIndicator(),
///   success: (user) => Text(user.name),
///   error: (e) => Text('Error: $e'),
///   empty: () => Text('No data'),
/// ));
/// ```
abstract class SintStatus<T> with Equality {
  const SintStatus();

  factory SintStatus.loading() => LoadingStatus<T>();

  factory SintStatus.error(Object message) => ErrorStatus<T, Object>(message);

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
  }) {
    if (this is SuccessStatus<T>) {
      return success((this as SuccessStatus<T>).data);
    } else if (this is ErrorStatus<T, Object>) {
      return error((this as ErrorStatus<T, Object>).error ?? 'Unknown error');
    } else if (this is LoadingStatus<T>) {
      return loading();
    } else if (this is EmptyStatus<T>) {
      return empty();
    } else {
      return (custom ?? empty)();
    }
  }

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
  }) {
    if (this is SuccessStatus<T> && success != null) {
      return success((this as SuccessStatus<T>).data);
    } else if (this is ErrorStatus<T, Object> && error != null) {
      return error((this as ErrorStatus<T, Object>).error ?? 'Unknown error');
    } else if (this is LoadingStatus<T> && loading != null) {
      return loading();
    } else if (this is EmptyStatus<T> && empty != null) {
      return empty();
    } else if (this is CustomStatus<T> && custom != null) {
      return custom();
    }
    return orElse();
  }

  // ─── Convenience Getters ──────────────────────────────────

  bool get isLoading => this is LoadingStatus<T>;
  bool get isSuccess => this is SuccessStatus<T>;
  bool get isError => this is ErrorStatus<T, Object>;
  bool get isEmpty => this is EmptyStatus<T>;

  /// Returns the data if [isSuccess], otherwise `null`.
  T? get dataOrNull =>
      this is SuccessStatus<T> ? (this as SuccessStatus<T>).data : null;

  /// Returns the error if [isError], otherwise `null`.
  Object? get errorOrNull => this is ErrorStatus<T, Object>
      ? (this as ErrorStatus<T, Object>).error
      : null;
}

class CustomStatus<T> extends SintStatus<T> {
  @override
  List get props => [];
}

class LoadingStatus<T> extends SintStatus<T> {
  @override
  List get props => [];
}

class SuccessStatus<T> extends SintStatus<T> {
  final T data;

  const SuccessStatus(this.data);

  @override
  List get props => [data];
}

class ErrorStatus<T, S> extends SintStatus<T> {
  final S? error;

  const ErrorStatus([this.error]);

  @override
  List get props => [error];
}

class EmptyStatus<T> extends SintStatus<T> {
  @override
  List get props => [];
}
