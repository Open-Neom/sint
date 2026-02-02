
import 'package:sint/core/src/domain/models/rx_impl.dart';

/// Foundation class used for custom `Types` outside the common native Dart
/// types.
/// For example, any custom "Model" class, like User().obs will use `Rx` as
/// wrapper.
class Rx<T> extends RxImpl<T> {
  Rx(super.initial);

  @override
  dynamic toJson() {
    try {
      return (value as dynamic)?.toJson();
    } on Exception catch (_) {
      throw '$T has not method [toJson]';
    }
  }
}

class Rxn<T> extends Rx<T?> {
  Rxn([super.initial]);

  @override
  dynamic toJson() {
    try {
      return (value as dynamic)?.toJson();
    } on Exception catch (_) {
      throw '$T has not method [toJson]';
    }
  }
}

extension RxT<T extends Object> on T {
  /// Returns a `Rx` instance with [this] `T` as initial value.
  Rx<T> get obs => Rx<T>(this);
}

/// This method will replace the old `.obs` method.
/// It's a breaking change, but it is essential to avoid conflicts with
/// the new dart 3 features. T will be inferred by contextual type inference
/// rather than the extension type.
extension RxTnew on Object {
  /// Returns a `Rx` instance with [this] `T` as initial value.
  Rx<T> obs<T>() => Rx<T>(this as T);
}