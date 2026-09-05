@Tags(['benchmark'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';
import 'bench_harness.dart';

class P0BenchController extends SintController {}

void main() {
  tearDown(Sint.reset);
  group('Synchronous state notification', () {
    for (final listeners in [0, 1, 10, 100]) {
      test('RxInt with $listeners listeners validates delivery', () async {
        final rx = 0.obs;
        var updates = 0;
        var delivered = 0;
        for (var i = 0; i < listeners; i++) {
          rx.addListener(() {
            delivered++;
          });
        }
        final result = await runBench('state.rx.sync.listeners=$listeners', () {
          rx.value = ++updates;
        });
        expect(updates, result.totalOperations);
        expect(rx.value, updates);
        expect(delivered, updates * listeners);
        rx.close();
        printBenchTable('RxInt synchronous callback delivery', [result]);
      });

      test('ValueNotifier with $listeners listeners validates delivery',
          () async {
        final notifier = ValueNotifier<int>(0);
        var updates = 0;
        var delivered = 0;
        for (var i = 0; i < listeners; i++) {
          notifier.addListener(() {
            delivered++;
          });
        }
        final result = await runBench(
            'state.value_notifier.sync.listeners=$listeners', () {
          notifier.value = ++updates;
        });
        expect(notifier.value, result.totalOperations);
        expect(delivered, updates * listeners);
        notifier.dispose();
        printBenchTable(
            'ValueNotifier synchronous callback delivery', [result]);
      });
    }

    test('Controller.update validates callback count', () async {
      final controller = P0BenchController();
      var delivered = 0;
      controller.addListener(() {
        delivered++;
      });
      final result = await runBench(
          'state.controller.update.listeners=1', controller.update);
      expect(delivered, result.totalOperations);
      controller.dispose();
      printBenchTable('Manual synchronous notification', [result]);
    });

    test('Repeated equal Rx assignment delivers no notifications', () async {
      final rx = 1.obs;
      rx.value = 2;
      var delivered = 0;
      rx.addListener(() {
        delivered++;
      });
      final result = await runBench('state.rx.equal_assignment', () {
        rx.value = 2;
      });
      expect(rx.value, 2);
      expect(delivered, 0);
      rx.close();
      printBenchTable('Rx equality short circuit', [result]);
    });
  });

  test('Hot typed/tagged lookup validates instance identity', () async {
    final expected = Sint.put(P0BenchController(), tag: 'p0');
    var matches = 0;
    final result =
        await runBench('di.find.hot.tagged.controller.registry=1', () {
      if (identical(Sint.find<P0BenchController>(tag: 'p0'), expected)) {
        matches++;
      }
    });
    expect(matches, result.totalOperations);
    printBenchTable('Hot dependency lookup', [result]);
  });
}
