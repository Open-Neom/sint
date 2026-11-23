import 'dart:collection';

import 'package:sint/core/src/domain/typedefs/core_typedefs.dart';
import 'package:sint/core/src/domain/models/rx_impl.dart';
import 'package:sint/state_manager/src/sint_listenable.dart';

class RxSet<E> extends SintListenable<Set<E>>
    with SetMixin<E>, RxObjectMixin<Set<E>> {
  RxSet([Set<E> initial = const {}])
    : super(initial.isEmpty ? <E>{} : Set<E>.of(initial));

  RxSet._(super.initial);

  factory RxSet.from(Iterable elements) {
    return RxSet._(Set.from(elements));
  }

  factory RxSet.of(Iterable<E> elements) {
    return RxSet._(Set.of(elements));
  }

  factory RxSet.unmodifiable(Iterable<E> elements) {
    return RxSet._(Set.unmodifiable(elements));
  }

  factory RxSet.identity() {
    return RxSet._(Set.identity());
  }

  /// Special override to push() element(s) in a reactive way
  /// inside the Set.
  RxSet<E> operator +(Set<E> val) {
    addAll(val);
    return this;
  }

  void update(void Function(Iterable<E>? value) fn) {
    fn(peek);
    refresh();
  }

  @override
  bool add(E value) {
    final hasAdded = peek.add(value);
    if (hasAdded) {
      refresh();
    }
    return hasAdded;
  }

  @override
  bool contains(Object? element) {
    return value.contains(element);
  }

  @override
  Iterator<E> get iterator => value.iterator;

  @override
  int get length => value.length;

  @override
  bool get isEmpty => value.isEmpty;

  @override
  bool get isNotEmpty => value.isNotEmpty;

  @override
  E? lookup(Object? element) {
    return value.lookup(element);
  }

  @override
  bool remove(Object? value) {
    final hasRemoved = peek.remove(value);
    if (hasRemoved) {
      refresh();
    }
    return hasRemoved;
  }

  @override
  Set<E> toSet() {
    return value.toSet();
  }

  @override
  void addAll(Iterable<E> elements) {
    final target = peek;
    if (identical(this, elements) || identical(target, elements)) return;
    final prevLength = target.length;
    target.addAll(elements);
    if (target.length != prevLength) {
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
  void removeAll(Iterable<Object?> elements) {
    final target = peek;
    if (target.isEmpty) return;
    if (identical(this, elements) || identical(target, elements)) {
      target.clear();
      refresh();
      return;
    }
    final prevLength = target.length;
    target.removeAll(elements);
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
  void retainAll(Iterable<Object?> elements) {
    final target = peek;
    if (target.isEmpty ||
        identical(this, elements) ||
        identical(target, elements)) {
      return;
    }
    final prevLength = target.length;
    target.retainAll(elements);
    if (target.length != prevLength) {
      refresh();
    }
  }

  @override
  void retainWhere(bool Function(E) test) {
    final target = peek;
    final prevLength = target.length;
    target.retainWhere(test);
    if (target.length != prevLength) {
      refresh();
    }
  }

  /// Replaces all existing items with [item], triggering [refresh] only if
  /// the set contents actually change.
  void assign(E item) {
    final target = peek;
    if (target.length == 1 && target.contains(item)) return;
    target
      ..clear()
      ..add(item);
    refresh();
  }

  /// Replaces all existing items with [items], triggering [refresh] only if
  /// the set contents actually change.
  void assignAll(Iterable<E> items) {
    final target = peek;
    if (identical(this, items) || identical(target, items)) return;
    final nextItems = Set<E>.of(items);
    if (target.length == nextItems.length && target.containsAll(nextItems)) {
      return;
    }
    target
      ..clear()
      ..addAll(nextItems);
    refresh();
  }
}

extension SetExtension<E> on Set<E> {
  RxSet<E> get obs {
    return RxSet<E>._(this);
  }

  /// Add [item] to [Set<E>] only if [condition] is true.
  void addIf(dynamic condition, E item) {
    if (condition is Condition) condition = condition();
    if (condition is bool && condition) add(item);
  }

  /// Adds [Iterable<E>] to [Set<E>] only if [condition] is true.
  void addAllIf(dynamic condition, Iterable<E> items) {
    if (condition is Condition) condition = condition();
    if (condition is bool && condition) addAll(items);
  }

  /// Replaces all existing items of this set with [item].
  void assign(E item) {
    if (this is RxSet<E>) {
      (this as RxSet<E>).assign(item);
    } else {
      clear();
      add(item);
    }
  }

  /// Replaces all existing items of this set with [items].
  void assignAll(Iterable<E> items) {
    if (this is RxSet<E>) {
      (this as RxSet<E>).assignAll(items);
    } else {
      if (identical(this, items)) return;
      final nextItems = List<E>.of(items);
      clear();
      addAll(nextItems);
    }
  }
}
