// SINT v1.5.0 - Route Matching Benchmarks (navigation overhaul)
// Methodology: warmup + 7 rounds, median/p95 via bench_harness.dart.
// Isolated RouteParser.matchRoute — no WidgetTester pumps.
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

import 'bench_harness.dart';

RouteParser _buildParser(int n) {
  final routes = <SintPage>[
    SintPage(name: '/', page: () => const SizedBox()),
  ];
  for (var i = 0; i < n; i++) {
    routes.add(SintPage(name: '/route$i', page: () => const SizedBox()));
    routes.add(SintPage(name: '/user$i/:id', page: () => const SizedBox()));
  }
  return RouteParser(routes: routes);
}

void main() {
  group('Pillar N: Route Matching Benchmarks', () {
    for (final n in [10, 100]) {
      test('route matching with $n registered route pairs', () async {
        final parser = _buildParser(n);
        final results = <BenchResult>[];

        // Worst case for a flat scan: the target is the LAST registered.
        results.add(await runBench('literal match, last of $n', () {
          parser.matchRoute('/route${n - 1}');
        }, iterations: 1000));

        results.add(await runBench('param match, last of $n', () {
          parser.matchRoute('/user${n - 1}/42?tab=x');
        }, iterations: 1000));

        results.add(await runBench('miss (unknown), $n', () {
          parser.matchRoute('/missing/deep/path');
        }, iterations: 1000));

        printBenchTable('PILLAR N: ROUTE MATCHING ($n route pairs)', results);
      });
    }
  });
}
