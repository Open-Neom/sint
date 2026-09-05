@Tags(['benchmark'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:sint/sint.dart';
import 'bench_harness.dart';

class LifecycleBenchController extends SintController {
  static int started = 0;
  static int closed = 0;
  // This scenario measures synchronous DI lifecycle, excluding frame callbacks.
  @override
  // ignore: must_call_super
  void onInit() {
    started++;
  }

  @override
  void onClose() {
    closed++;
    super.onClose();
  }
}

class ChainNode {
  ChainNode(this.index, this.child);
  final int index;
  final ChainNode? child;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Sint.isLogEnable = false;
  });
  tearDown(Sint.reset);

  test('Translation interpolation validates final strings', () async {
    Sint.locale = const Locale('en', 'US');
    Sint.addTranslations({
      'en_US': {'bench_welcome': 'Welcome @name, ID @id'}
    });
    var valid = 0;
    final params = {'name': 'SINT', 'id': '42'};
    final result = await runBench('translation.interpolate.two_params', () {
      if ('bench_welcome'.trParams(params) == 'Welcome SINT, ID 42') {
        valid++;
      }
    });
    expect(valid, result.totalOperations);
    printBenchTable(
        'Translation lookup and two parameter substitutions', [result]);
  });

  test('Registration, resolution and synchronous close', () async {
    LifecycleBenchController.started = 0;
    LifecycleBenchController.closed = 0;
    var valid = 0;
    final result = await runBench('di.lifecycle.put_find_delete', () {
      final controller = LifecycleBenchController();
      Sint.put(controller, tag: 'lifecycle');
      if (identical(
          Sint.find<LifecycleBenchController>(tag: 'lifecycle'), controller)) {
        valid++;
      }
      Sint.delete<LifecycleBenchController>(tag: 'lifecycle');
    }, warmup: 100, iterations: 100);
    expect(valid, result.totalOperations);
    expect(LifecycleBenchController.started, result.totalOperations);
    expect(LifecycleBenchController.closed, result.totalOperations);
    expect(
        Sint.isRegistered<LifecycleBenchController>(tag: 'lifecycle'), isFalse);
    printBenchTable('Complete synchronous DI lifecycle', [result]);
  });

  for (final depth in [1, 10]) {
    test('Lazy dependency chain, actual depth $depth', () async {
      for (var index = 0; index < depth; index++) {
        final level = index;
        Sint.lazyPut<ChainNode>(
            () => ChainNode(
                level,
                level + 1 < depth
                    ? Sint.find<ChainNode>(tag: 'chain${level + 1}')
                    : null),
            tag: 'chain$level',
            fenix: true);
      }
      var checksum = 0;
      final result =
          await runBench('di.lazy.cold_chain_create_delete.depth=$depth', () {
        ChainNode? node = Sint.find<ChainNode>(tag: 'chain0');
        while (node != null) {
          checksum += node.index + 1;
          node = node.child;
        }
        for (var i = 0; i < depth; i++) {
          Sint.delete<ChainNode>(tag: 'chain$i');
        }
      }, warmup: 100, iterations: 100);
      expect(checksum, result.totalOperations * depth * (depth + 1) ~/ 2);
      printBenchTable(
          'Lazy chain materialization, traversal and fenix disposal', [result]);
    });

    test('Hot lookup among $depth independent tags is not depth', () async {
      final instances = [for (var i = 0; i < depth; i++) ChainNode(i, null)];
      for (var i = 0; i < depth; i++) {
        Sint.put(instances[i], tag: 'peer$i');
      }
      var valid = 0;
      final result = await runBench('di.find.hot.tagged.registry=$depth', () {
        if (identical(
            Sint.find<ChainNode>(tag: 'peer${depth - 1}'), instances.last)) {
          valid++;
        }
      });
      expect(valid, result.totalOperations);
      printBenchTable('Hot flat registry lookup', [result]);
    });
  }

  for (final length in [10, 1000]) {
    test('Equal list replacement, $length elements', () async {
      final expected = List.generate(length, (index) => index);
      final values = expected.toList().obs;
      var delivered = 0;
      values.addListener(() {
        delivered++;
      });
      final result =
          await runBench('collection.list.assign_all.equal.length=$length', () {
        values.assignAll(expected);
      }, iterations: 100);
      expect(values.toList(), expected);
      expect(delivered, 0);
      values.close();
      printBenchTable(
          'Equal collection assignment, no rebuild request', [result]);
    });

    test('Changed list replacement, $length elements', () async {
      final first = List.generate(length, (index) => index);
      final second = List.generate(length, (index) => index + 1);
      final values = first.toList().obs;
      var delivered = 0;
      var operations = 0;
      values.addListener(() {
        delivered++;
      });
      final result = await runBench(
          'collection.list.assign_all.changed.length=$length', () {
        values.assignAll(++operations % 2 == 1 ? second : first);
      }, iterations: 100);
      expect(delivered, result.totalOperations);
      expect(values.toList(), operations.isOdd ? second : first);
      values.close();
      printBenchTable(
          'Changed collection assignment, one notification', [result]);
    });
  }
}
