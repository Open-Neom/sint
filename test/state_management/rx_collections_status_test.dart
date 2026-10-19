// Sint RxMap, RxSet, RxBool and SintStatus pattern matching tests.
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Sint.reset);

  group('RxMap', () {
    test('[]= notifies listeners', () async {
      final m = <String, int>{}.obs;
      var fired = 0;
      m.listen((_) => fired++);
      await Future<void>.delayed(Duration.zero);
      final baseline = fired;
      m['a'] = 1;
      m['b'] = 2;
      await Future<void>.delayed(Duration.zero);
      expect(fired, greaterThan(baseline));
      expect(m['a'], 1);
      expect(m['b'], 2);
      expect(m.length, 2);
    });

    test('remove notifies and returns the value', () async {
      final m = {'a': 1, 'b': 2}.obs;
      var fired = 0;
      m.listen((_) => fired++);
      await Future<void>.delayed(Duration.zero);
      final baseline = fired;
      final r = m.remove('a');
      await Future<void>.delayed(Duration.zero);
      expect(r, 1);
      expect(m.containsKey('a'), isFalse);
      expect(fired, greaterThan(baseline));
    });

    test('clear empties and notifies', () async {
      final m = {'a': 1, 'b': 2}.obs;
      var fired = 0;
      m.listen((_) => fired++);
      await Future<void>.delayed(Duration.zero);
      final baseline = fired;
      m.clear();
      await Future<void>.delayed(Duration.zero);
      expect(m.isEmpty, isTrue);
      expect(fired, greaterThan(baseline));
    });

    test('addIf with true predicate inserts, false skips', () {
      final m = <String, int>{}.obs;
      m.addIf(true, 'k', 1);
      m.addIf(false, 'k2', 2);
      expect(m['k'], 1);
      expect(m.containsKey('k2'), isFalse);
    });

    test('factory RxMap.from copies the source map', () {
      final src = {'a': 1};
      final m = RxMap<String, int>.from(src);
      m['b'] = 2;
      expect(src.containsKey('b'), isFalse,
          reason: 'changes to RxMap must not bleed back to source');
    });

    test('default RxMap() and const-initialized RxMap are mutable (Issue #13)',
        () {
      final emptyMap = RxMap<String, int>();
      emptyMap['a'] = 1;
      emptyMap.remove('a');
      expect(emptyMap, isEmpty);

      final seededMap = RxMap<String, int>(const {'x': 10});
      seededMap['y'] = 20;
      expect(seededMap, {'x': 10, 'y': 20});
    });
  });

  group('RxList default constructor mutability (Issue #13)', () {
    test('default RxList() creates a mutable, growable list', () {
      final items = RxList<int>();
      expect(() => items.removeWhere((item) => item == 1), returnsNormally);
      items.add(1);
      items.addAll([2, 3]);
      items.removeWhere((item) => item == 2);
      expect(items.toList(), [1, 3]);
    });

    test('RxList initialized with const list creates a mutable copy', () {
      final items = RxList<int>(const [1, 2]);
      items.add(3);
      expect(items.toList(), [1, 2, 3]);
    });

    test('RxList.unmodifiable still enforces unmodifiability', () {
      final items = RxList<int>.unmodifiable([1, 2]);
      expect(() => items.add(3), throwsUnsupportedError);
    });
  });

  group('RxSet', () {
    test('default RxSet() and const-initialized RxSet are mutable (Issue #13)',
        () {
      final items = RxSet<int>();
      items.add(1);
      items.retainWhere((e) => e != 1);
      expect(items, isEmpty);

      final seeded = RxSet<int>(const {1, 2});
      seeded.add(3);
      expect(seeded.toSet(), {1, 2, 3});
    });

    test('add and remove notify', () async {
      final s = <int>{1, 2}.obs;
      var fired = 0;
      s.listen((_) => fired++);
      await Future<void>.delayed(Duration.zero);
      final baseline = fired;
      s.add(3);
      s.remove(1);
      await Future<void>.delayed(Duration.zero);
      expect(s.contains(3), isTrue);
      expect(s.contains(1), isFalse);
      expect(s.length, 2);
      expect(fired, greaterThan(baseline));
    });

    test('add of existing element does not duplicate', () {
      final s = <int>{1}.obs;
      s.add(1);
      expect(s.length, 1);
    });
  });

  group('RxBool', () {
    test('toggle by direct assignment notifies once per change', () async {
      final b = false.obs;
      var fired = 0;
      b.listen((_) => fired++);
      await Future<void>.delayed(Duration.zero);
      final baseline = fired;
      b.value = true;
      b.value = true; // deduped
      b.value = false;
      await Future<void>.delayed(Duration.zero);
      expect(fired - baseline, 2);
    });
  });

  group('SintStatus pattern matching', () {
    test('when matches Loading branch', () {
      final s = SintStatus<int>.loading();
      final r = s.when(
        loading: () => 'L',
        success: (d) => 'S$d',
        error: (e) => 'E',
        empty: () => 'M',
      );
      expect(r, 'L');
      expect(s.isLoading, isTrue);
      expect(s.dataOrNull, isNull);
    });

    test('when matches Success branch and exposes data', () {
      final s = SintStatus<int>.success(42);
      final r = s.when(
        loading: () => -1,
        success: (d) => d * 2,
        error: (e) => -2,
        empty: () => -3,
      );
      expect(r, 84);
      expect(s.isSuccess, isTrue);
      expect(s.dataOrNull, 42);
      expect(s.errorOrNull, isNull);
    });

    test('when matches Error branch and unwraps message', () {
      final s = SintStatus<int>.error('boom');
      final r = s.when(
        loading: () => 'L',
        success: (d) => 'S',
        error: (e) => 'E:$e',
        empty: () => 'M',
      );
      expect(r, 'E:boom');
      expect(s.isError, isTrue);
      expect(s.errorOrNull, 'boom');
    });

    test('maybeWhen falls back to orElse when not matched', () {
      final s = SintStatus<int>.empty();
      final r = s.maybeWhen<String>(
        success: (_) => 'S',
        orElse: () => 'else',
      );
      expect(r, 'else');
      expect(s.isEmpty, isTrue);
    });

    test('Equality: two SuccessStatus with same payload are equal', () {
      final a = SintStatus<int>.success(7);
      final b = SintStatus<int>.success(7);
      final c = SintStatus<int>.success(8);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('Two LoadingStatus instances are equal', () {
      expect(SintStatus<String>.loading(), equals(SintStatus<String>.loading()));
    });
  });
}
