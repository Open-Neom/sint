import 'dart:collection';

import 'package:sint/core/src/domain/typedefs/core_typedefs.dart';
import 'package:sint/core/src/domain/models/rx_impl.dart';
import 'package:sint/state_manager/src/sint_listenable.dart';

class RxMap<K, V> extends SintListenable<Map<K, V>>
    with MapMixin<K, V>, RxObjectMixin<Map<K, V>> {
  RxMap([Map<K, V> initial = const {}])
    : super(initial.isEmpty ? <K, V>{} : Map<K, V>.of(initial));

  RxMap._(super.initial);

  factory RxMap.from(Map<K, V> other) {
    return RxMap._(Map.from(other));
  }

  /// Creates a [LinkedHashMap] with the same keys and values as [other].
  factory RxMap.of(Map<K, V> other) {
    return RxMap._(Map.of(other));
  }

  /// Creates an unmodifiable hash based map containing the entries of [other].
  factory RxMap.unmodifiable(Map<dynamic, dynamic> other) {
    return RxMap._(Map.unmodifiable(other));
  }

  /// Creates an identity map with the default implementation, [LinkedHashMap].
  factory RxMap.identity() {
    return RxMap._(Map.identity());
  }

  @override
  V? operator [](Object? key) {
    return value[key];
  }

  @override
  int get length => value.length;

  @override
  bool get isEmpty => value.isEmpty;

  @override
  bool get isNotEmpty => value.isNotEmpty;

  @override
  bool containsKey(Object? key) => value.containsKey(key);

  @override
  bool containsValue(Object? value) => this.value.containsValue(value);

  @override
  Iterable<K> get keys => value.keys;

  @override
  Iterable<V> get values => value.values;

  @override
  Iterable<MapEntry<K, V>> get entries => value.entries;

  @override
  void operator []=(K key, V value) {
    final target = peek;
    if (!target.containsKey(key) || target[key] != value) {
      target[key] = value;
      refresh();
    }
  }

  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    final target = peek;
    if (target.containsKey(key)) {
      return target[key] as V;
    }
    final next = ifAbsent();
    target[key] = next;
    refresh();
    return next;
  }

  @override
  void addAll(Map<K, V> other) {
    if (other.isEmpty) return;
    final target = peek;
    if (identical(this, other) || identical(target, other)) return;
    var changed = false;
    for (final entry in other.entries) {
      if (!target.containsKey(entry.key) || target[entry.key] != entry.value) {
        target[entry.key] = entry.value;
        changed = true;
      }
    }
    if (changed) {
      refresh();
    }
  }

  @override
  void addEntries(Iterable<MapEntry<K, V>> newEntries) {
    final target = peek;
    final entriesList = identical(newEntries, target.entries)
        ? List<MapEntry<K, V>>.of(newEntries)
        : newEntries;
    var changed = false;
    for (final entry in entriesList) {
      if (!target.containsKey(entry.key) || target[entry.key] != entry.value) {
        target[entry.key] = entry.value;
        changed = true;
      }
    }
    if (changed) {
      refresh();
    }
  }

  @override
  V update(K key, V Function(V value) update, {V Function()? ifAbsent}) {
    final target = peek;
    if (target.containsKey(key)) {
      final prev = target[key] as V;
      final next = update(prev);
      if (prev != next) {
        target[key] = next;
        refresh();
      }
      return next;
    }
    if (ifAbsent != null) {
      final next = ifAbsent();
      target[key] = next;
      refresh();
      return next;
    }
    throw ArgumentError.value(key, 'key', 'Key not in map.');
  }

  @override
  void updateAll(V Function(K key, V value) update) {
    final target = peek;
    if (target.isEmpty) return;
    var changed = false;
    for (final key in target.keys.toList(growable: false)) {
      final prev = target[key] as V;
      final next = update(key, prev);
      if (prev != next) {
        target[key] = next;
        changed = true;
      }
    }
    if (changed) {
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
  V? remove(Object? key) {
    final target = peek;
    if (target.containsKey(key)) {
      final val = target.remove(key);
      refresh();
      return val;
    }
    return null;
  }

  @override
  void removeWhere(bool Function(K key, V value) test) {
    final target = peek;
    final prevLength = target.length;
    target.removeWhere(test);
    if (target.length != prevLength) {
      refresh();
    }
  }

  /// Replaces all existing entries with the single `(key, val)` pair,
  /// notifying listeners only if the map contents actually change.
  void assign(K key, V val) {
    final target = peek;
    if (target.length == 1 && target.containsKey(key) && target[key] == val) {
      return;
    }
    target.clear();
    target[key] = val;
    refresh();
  }

  /// Replaces all existing entries with [val], notifying listeners only if
  /// the map contents actually change (`O(N)` content comparison).
  void assignAll(Map<K, V> val) {
    final target = peek;
    if (identical(this, val) || identical(target, val)) return;
    final source = val is RxMap<K, V> ? val.peek : val;
    if (identical(target, source)) return;
    if (target.length == source.length) {
      var isSame = true;
      for (final entry in source.entries) {
        if (!target.containsKey(entry.key) ||
            target[entry.key] != entry.value) {
          isSame = false;
          break;
        }
      }
      if (isSame) return;
    }
    final replacement = Map<K, V>.of(source);
    target
      ..clear()
      ..addAll(replacement);
    refresh();
  }
}

extension MapExtension<K, V> on Map<K, V> {
  RxMap<K, V> get obs {
    return RxMap<K, V>._(this);
  }

  void addIf(dynamic condition, K key, V value) {
    if (condition is Condition) condition = condition();
    if (condition is bool && condition) {
      this[key] = value;
    }
  }

  void addAllIf(dynamic condition, Map<K, V> values) {
    if (condition is Condition) condition = condition();
    if (condition is bool && condition) addAll(values);
  }

  void assign(K key, V val) {
    if (this is RxMap<K, V>) {
      (this as RxMap<K, V>).assign(key, val);
    } else {
      clear();
      this[key] = val;
    }
  }

  void assignAll(Map<K, V> val) {
    if (this is RxMap<K, V>) {
      (this as RxMap<K, V>).assignAll(val);
    } else {
      if (identical(this, val)) return;
      final replacement = Map<K, V>.of(val);
      clear();
      addAll(replacement);
    }
  }
}
