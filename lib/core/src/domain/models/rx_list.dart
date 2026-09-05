import 'dart:collection';

import 'package:sint/core/src/domain/typedefs/core_typedefs.dart';
import 'package:sint/core/src/domain/models/rx_impl.dart';
import 'package:sint/state_manager/src/sint_listenable.dart';

/// Create a list similar to `List<T>`
class RxList<E> extends SintListenable<List<E>>
    with ListMixin<E>, RxObjectMixin<List<E>> {
  RxList([super.initial = const []]);

  factory RxList.filled(int length, E fill, {bool growable = false}) {
    return RxList(List.filled(length, fill, growable: growable));
  }

  factory RxList.empty({bool growable = false}) {
    return RxList(List.empty(growable: growable));
  }

  /// Creates a list containing all [elements].
  factory RxList.from(Iterable elements, {bool growable = true}) {
    return RxList(List.from(elements, growable: growable));
  }

  /// Creates a list from [elements].
  factory RxList.of(Iterable<E> elements, {bool growable = true}) {
    return RxList(List.of(elements, growable: growable));
  }

  /// Generates a list of values.
  factory RxList.generate(int length, E Function(int index) generator,
      {bool growable = true}) {
    return RxList(List.generate(length, generator, growable: growable));
  }

  /// Creates an unmodifiable list containing all [elements].
  factory RxList.unmodifiable(Iterable elements) {
    return RxList(List.unmodifiable(elements));
  }

  @override
  Iterator<E> get iterator => value.iterator;

  @override
  void operator []=(int index, E val) {
    if (value[index] != val) {
      value[index] = val;
      refresh();
    }
  }

  /// Special override to push() element(s) in a reactive way
  /// inside the List,
  @override
  RxList<E> operator +(Iterable<E> val) {
    addAll(val);
    // refresh();
    return this;
  }

  @override
  E operator [](int index) {
    return value[index];
  }

  @override
  void add(E element) {
    value.add(element);
    refresh();
  }

  @override
  void addAll(Iterable<E> iterable) {
    value.addAll(iterable);
    refresh();
  }

  @override
  bool remove(Object? element) {
    final removed = value.remove(element);
    if (removed) {
      refresh();
    }
    return removed;
  }

  @override
  void removeWhere(bool Function(E element) test) {
    final prevLength = value.length;
    value.removeWhere(test);
    if (value.length != prevLength) {
      refresh();
    }
  }

  @override
  void retainWhere(bool Function(E element) test) {
    final prevLength = value.length;
    value.retainWhere(test);
    if (value.length != prevLength) {
      refresh();
    }
  }

  @override
  int get length => value.length;

  @override
  set length(int newLength) {
    if (value.length != newLength) {
      value.length = newLength;
      refresh();
    }
  }

  @override
  void clear() {
    if (value.isNotEmpty) {
      value.clear();
      refresh();
    }
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    value.insertAll(index, iterable);
    refresh();
  }

  @override
  Iterable<E> get reversed => value.reversed;

  @override
  Iterable<E> where(bool Function(E) test) {
    return value.where(test);
  }

  @override
  Iterable<T> whereType<T>() {
    return value.whereType<T>();
  }

  @override
  void sort([int Function(E a, E b)? compare]) {
    value.sort(compare);
    refresh();
  }

  /// Replaces all existing items with [item] in a reactive way,
  /// triggering [refresh] only if the list actually changes.
  void assign(E item) {
    if (value.length == 1 && value.first == item) return;
    value.clear();
    value.add(item);
    refresh();
  }

  /// Replaces all existing items with [items] in a reactive way,
  /// triggering [refresh] only if the contents actually change.
  void assignAll(Iterable<E> items) {
    final current = value;
    if (identical(current, items)) return;
    // Iterables and list views may read this very list lazily. Consume them
    // before clearing the backing collection (also preserves it on failure).
    // A List can be compared without allocating when its contents are equal.
    final source = items is List<E> ? items : List<E>.of(items);
    if (source.length == current.length) {
      bool isSame = true;
      for (int i = 0; i < current.length; i++) {
        if (current[i] != source[i]) {
          isSame = false;
          break;
        }
      }
      if (isSame) return;
    }
    final replacement = items is List<E> ? List<E>.of(source) : source;
    current.clear();
    current.addAll(replacement);
    refresh();
  }
}

extension ListExtension<E> on List<E> {
  RxList<E> get obs => RxList<E>(this);

  /// Add [item] to [List<E>] only if [item] is not null.
  void addNonNull(E item) {
    if (item != null) add(item);
  }

  /// Add [item] to [List<E>] only if [condition] is true.
  void addIf(dynamic condition, E item) {
    if (condition is Condition) condition = condition();
    if (condition is bool && condition) add(item);
  }

  /// Adds [Iterable<E>] to [List<E>] only if [condition] is true.
  void addAllIf(dynamic condition, Iterable<E> items) {
    if (condition is Condition) condition = condition();
    if (condition is bool && condition) addAll(items);
  }

  /// Replaces all existing items of this list with [item]
  void assign(E item) {
    if (this is RxList<E>) {
      (this as RxList<E>).assign(item);
    } else {
      clear();
      add(item);
    }
  }

  /// Replaces all existing items of this list with [items]
  void assignAll(Iterable<E> items) {
    if (this is RxList<E>) {
      (this as RxList<E>).assignAll(items);
    } else {
      if (identical(this, items)) return;
      final replacement = List<E>.of(items);
      clear();
      addAll(replacement);
    }
  }
}
