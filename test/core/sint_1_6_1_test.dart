import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

class _SampleService {
  final String name;
  _SampleService(this.name);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Sint.reset);

  group('Sint 1.6.1 - Pillar I: O(1) Route-Dispose DI Optimization', () {
    test('delete by String key cleans up _typeSingl registry without generic type', () {
      Sint.put<_SampleService>(_SampleService('test1'));
      expect(Sint.isRegistered<_SampleService>(), isTrue);

      // Simulate RouterReportManager which invokes Sint.delete(key: element)
      final key = '_SampleService';
      final deleted = Sint.delete(key: key);
      expect(deleted, isTrue);
      expect(Sint.isRegistered<_SampleService>(), isFalse);
      expect(() => Sint.find<_SampleService>(), throwsA(isA<String>()));
    });

    test('delete by String key with tag cleans up tagged _typeSingl registry', () {
      Sint.put<_SampleService>(_SampleService('tagged'), tag: 'custom_tag');
      expect(Sint.isRegistered<_SampleService>(tag: 'custom_tag'), isTrue);

      final key = '_SampleServicecustom_tag';
      final deleted = Sint.delete(key: key);
      expect(deleted, isTrue);
      expect(Sint.isRegistered<_SampleService>(tag: 'custom_tag'), isFalse);
    });
  });

  group('Sint 1.6.1 - Pillar S: RxList Conditional assign and assignAll', () {
    test('RxList.assign does not notify if assigning same single element', () {
      final list = <String>['apple'].obs;
      var notifications = 0;
      list.addListener(() => notifications++);

      // Assign identical single element
      list.assign('apple');
      expect(notifications, 0);

      // Assign different element
      list.assign('banana');
      expect(notifications, 1);
      expect(list, ['banana']);
    });

    test('RxList.assignAll does not notify if assigning identical list', () {
      final list = <int>[1, 2, 3].obs;
      var notifications = 0;
      list.addListener(() => notifications++);

      // Assign identical elements
      list.assignAll([1, 2, 3]);
      expect(notifications, 0);

      // Assign different elements
      list.assignAll([1, 2, 4]);
      expect(notifications, 1);
      expect(list, [1, 2, 4]);
    });

    test('ListExtension.assign clears and replaces on standard List', () {
      final stdList = <String>['a', 'b'];
      stdList.assign('c');
      expect(stdList, ['c']);
    });

    test('ListExtension.assignAll clears and replaces on standard List', () {
      final stdList = <String>['a', 'b'];
      stdList.assignAll(['x', 'y']);
      expect(stdList, ['x', 'y']);
    });
  });

  group('Sint 1.6.1 - Pillar S: RxSet Conditional Refresh', () {
    test('RxSet.clear does not notify when already empty', () {
      final set = <String>{}.obs;
      var notifications = 0;
      set.addListener(() => notifications++);

      set.clear();
      expect(notifications, 0);

      set.add('item1');
      expect(notifications, 1);

      set.clear();
      expect(notifications, 2);
    });

    test('RxSet.removeAll does not notify when removing non-existent elements', () {
      final set = <int>{1, 2, 3}.obs;
      var notifications = 0;
      set.addListener(() => notifications++);

      set.removeAll([4, 5]);
      expect(notifications, 0);

      set.removeAll([2]);
      expect(notifications, 1);
      expect(set, {1, 3});
    });
  });
}
