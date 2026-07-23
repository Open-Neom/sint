// SINT v1.4.0 - P0 Hot-Path Benchmarks (release 1.4.0)
// Methodology: warmup + 7 rounds, median/p95 via bench_harness.dart.
// These are pure-Dart microbenchmarks (no WidgetTester pumps), fast enough
// to run inside the normal test suite.
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

import 'bench_harness.dart';

class P0BenchController extends SintController {}

void main() {
  tearDown(() => Sint.reset());

  group('P0 Hot-Path Benchmarks', () {
    test('S1. Pure notification path (RxInt, 1 listener)', () async {
      final results = <BenchResult>[];

      // 3. No listeners: baseline of the empty path.
      final rxAlone = 0.obs;
      var sink = 0;
      results.add(await runBench('S3. no-listeners (empty path)', () {
        rxAlone.value = sink++;
      }));

      // 1. Pure notification: 1 RxInt with 1 empty listener.
      final rx = 0.obs;
      rx.addListener(() {});
      var i = 0;
      results.add(await runBench('S1. pure notification (1 listener)', () {
        rx.value = i++;
      }));

      printBenchTable('P0 BENCH: RxInt notification hot path', results);
    });

    test('S2. Fan-out scaling (0, 1, 10, 100 listeners)', () async {
      final results = <BenchResult>[];
      for (final n in [0, 1, 10, 100]) {
        final rx = 0.obs;
        for (var l = 0; l < n; l++) {
          rx.addListener(() {});
        }
        var i = 0;
        results.add(await runBench('S2. fan-out ($n listeners)', () {
          rx.value = i++;
        }));
      }
      printBenchTable('P0 BENCH: RxInt fan-out scaling', results);
    });

    test('I1. Sint.find with tag (20k finds)', () async {
      Sint.put(P0BenchController(), tag: 'p0');
      var sink = 0;
      final result = await runBench('I1. Sint.find (tagged)', () {
        final c = Sint.find<P0BenchController>(tag: 'p0');
        sink += c.hashCode & 1;
      });
      printBenchTable('P0 BENCH: dependency lookup', [result]);
      expect(sink, greaterThanOrEqualTo(0));
    });

    test('S4. SintController.update() with 1 listener', () async {
      final controller = P0BenchController();
      controller.addListener(() {});
      final result = await runBench('S4. update() (1 listener)', () {
        controller.update();
      });
      printBenchTable('P0 BENCH: SintController.update()', [result]);
    });
  });
}
