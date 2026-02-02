import 'package:sint/state_manager/src/domain/mixins/equality_mixin.dart';

abstract class SintStatus<T> with Equality {
  const SintStatus();

  factory SintStatus.loading() => LoadingStatus<T>();

  factory SintStatus.error(Object message) => ErrorStatus<T, Object>(message);

  factory SintStatus.empty() => EmptyStatus<T>();

  factory SintStatus.success(T data) => SuccessStatus<T>(data);

  factory SintStatus.custom() => CustomStatus<T>();
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

