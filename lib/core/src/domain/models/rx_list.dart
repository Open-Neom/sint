import 'dart:collection';

import 'package:sint/core/src/domain/typedefs/core_typedefs.dart';
import 'package:sint/core/src/domain/models/rx_impl.dart';
import 'package:sint/state_manager/src/sint_listenable.dart';

/// Create a list similar to `List<T>`
class RxList<E> extends SintListenable<List<E>>
    with ListMixin<E>, RxObjectMixin<List<E>> {
  RxList([List<E> initial = const []])
      : super(initial.isEmpty ? <E>[] : List<E>.of(initial));

  RxList._(super.initial);

  factory RxList.filled(int length, E fill, {bool growable = false}) {
    return RxList._(List.filled(length, fill, growable: growable));
  }

  factory RxList.empty({bool growable = false}) {
    return RxList._(List.empty(growable: growable));
  }

  /// Creates a list containing all [elements].
  factory RxList.from(Iterable elements, {bool growable = true}) {
    return RxList._(List.from(elements, growable: growable));
  }

  /// Creates a list from [elements].
  factory RxList.of(Iterable<E> elements, {bool growable = true}) {
    return RxList._(List.of(elements, growable: growable));
  }

  /// Generates a list of values.
  factory RxList.generate(int length, E Function(int index) generator,
      {bool growable = true}) {
    return RxList._(List.generate(length, generator, growable: growable));
  }

  /// Creates an unmodifiable list containing all [elements].
  factory RxList.unmodifiable(Iterable elements) {
    return RxList._(List.unmodifiable(elements));
  }

  @override
  Iterator<E> get iterator => value.iterator;

  @override
  void operator []=(int index, E val) {
    final target = peek;
    if (target[index] != val) {
      target[index] = val;
      refresh();
    }
  }

  /// Special override to push() element(s) in a reactive way
  /// inside the List,
  @override
  RxList<E> operator +(Iterable<E> val) {
    addAll(val);
    return this;
  }

  @override
  E operator [](int index) {
    return value[index];
  }

  @override
  void add(E element) {
    peek.add(element);
    refresh();
  }

  @override
  void addAll(Iterable<E> iterable) {
    final target = peek;
    if (identical(this, iterable) || identical(target, iterable)) {
      if (target.isEmpty) return;
      target.addAll(List<E>.of(target));
      refresh();
      return;
    }
    final prevLength = target.length;
    target.addAll(iterable);
    if (target.length != prevLength) {
      refresh();
    }
  }

  @override
  void insert(int index, E element) {
    peek.insert(index, element);
    refresh();
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    final target = peek;
    final source = (identical(this, iterable) || identical(target, iterable))
        ? List<E>.of(target)
        : iterable;
    final prevLength = target.length;
    target.insertAll(index, source);
    if (target.length != prevLength) {
      refresh();
    }
  }

  @override
  bool remove(Object? element) {
    final removed = peek.remove(element);
    if (removed) {
      refresh();
    }
    return removed;
  }

  @override
  E removeAt(int index) {
    final removed = peek.removeAt(index);
    refresh();
    return removed;
  }

  @override
  E removeLast() {
    final removed = peek.removeLast();
    refresh();
    return removed;
  }

  @override
  void removeRange(int start, int end) {
    final target = peek;
    final prevLength = target.length;
    target.removeRange(start, end);
    if (target.length != prevLength) {
      refresh();
    }
  }

  @override
  void removeWhere(bool Function(E element) test) {
    final target = peek;
    final prevLength = target.length;
    target.removeWhere(test);
    if (target.length != prevLength) {
      refresh();
    }
  }

  @override
  void retainWhere(bool Function(E element) test) {
    final target = peek;
    final prevLength = target.length;
    target.retainWhere(test);
    if (target.length != prevLength) {
      refresh();
    }
  }

  @override
  void setAll(int index, Iterable<E> iterable) {
    final target = peek;
    final source = (identical(this, iterable) || identical(target, iterable))
        ? List<E>.of(target)
        : iterable;
    target.setAll(index, source);
    refresh();
  }

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    final target = peek;
    final source = (identical(this, iterable) || identical(target, iterable))
        ? List<E>.of(target)
        : iterable;
    target.setRange(start, end, source, skipCount);
    if (end > start) {
      refresh();
    }
  }

  @override
  void replaceRange(int start, int end, Iterable<E> newContents) {
    final target = peek;
    final source =
        (identical(this, newContents) || identical(target, newContents))
            ? List<E>.of(target)
            : newContents;
    final prevLength = target.length;
    target.replaceRange(start, end, source);
    if (end > start || target.length != prevLength) {
      refresh();
    }
  }

  @override
  void fillRange(int start, int end, [E? fill]) {
    peek.fillRange(start, end, fill);
    if (end > start) {
      refresh();
    }
  }

  @override
  int get length => value.length;

  @override
  bool get isEmpty => value.isEmpty;

  @override
  bool get isNotEmpty => value.isNotEmpty;

  @override
  bool contains(Object? element) => value.contains(element);

  @override
  set length(int newLength) {
    final target = peek;
    if (target.length != newLength) {
      target.length = newLength;
      refresh();
    }
  }

  @override
  void clear() {
    final target = peek;
    if (target.isNotEmpty) {
      target.clear();
      refresh();
    }
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
    final target = peek;
    if (target.length > 1) {
      target.sort(compare);
      refresh();
    }
  }

  /// Replaces all existing items with [item] in a reactive way,
  /// triggering [refresh] only if the list actually changes.
  void assign(E item) {
    final target = peek;
    if (target.length == 1 && target.first == item) return;
    target.clear();
    target.add(item);
    refresh();
  }

  /// Replaces all existing items with [items] in a reactive way,
  /// triggering [refresh] only if the contents actually change.
  void assignAll(Iterable<E> items) {
    final current = peek;
    if (identical(this, items) || identical(current, items)) return;
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
  RxList<E> get obs => RxList<E>._(this);

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
