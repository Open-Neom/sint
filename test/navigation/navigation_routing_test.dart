// SINT v1.0.0 - Navigation Pillar (N) Routing & Dynamic Params
// High-Fidelity Infrastructure for Open Neom
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

void main() {
  // Ensure a clean state for each routing test
  tearDown(() => Sint.reset());

  testWidgets('Benchmark: Dynamic URL Parameter Parsing', (tester) async {
    print('\n${'='*50}');
    print('SINT PILLAR N: DYNAMIC ROUTING LESSON');
    print('Philosophy: "Do the right things"');
    print('Infrastructure: Open Neom Standard');
    print('='*50 + '\n');

    // STEP 0: Settle initial environment
    await tester.pumpWidget(SintMaterialApp(
      initialRoute: '/',
      sintPages: [
        SintPage(name: '/', page: () => Container()),
        SintPage(name: '/user/:id/profile', page: () => Container()),
      ],
    ));
    await tester.pumpAndSettle();

    print('[STEP 1] Testing Complex URL Parsing and Pattern Matching');
    const iterations = 1000;
    final timer = Stopwatch()..start();

    for (var i = 0; i < iterations; i++) {
      // In Open Neom, we test the efficiency of the routing engine.
      // Sint.toNamed is asynchronous. To measure pure parsing,
      // we yield to the engine periodically or at the end.
      Sint.toNamed('/user/$i/profile?session=active&token=xyz');
    }

    // [FIX] Yield to the event loop to allow the routing engine
    // to finish the last match and populate Sint.parameters.
    await tester.pump();

    timer.stop();
    final totalTime = timer.elapsedMicroseconds;
    final avgTime = totalTime / iterations;

    print('\n${'-'*30}');
    print('BENCHMARK: URL Parsing & Pattern Matching');
    print('Iterations: $iterations complex URLs');
    print('Total Time: ${totalTime}us');
    print('Avg Speed:  ${avgTime.toStringAsFixed(4)}us/parsing');
    print('-'*30);

    // STEP 2: Verifying Parameter Retrieval
    print('\n[STEP 2] Verifying Parameter Retrieval from Global State');

    // Check the results of the final iteration
    expect(Sint.parameters['id'], '${iterations - 1}');
    expect(Sint.parameters['session'], 'active');

    print('Success: Dynamic parameter "id" (${Sint.parameters['id']}) captured correctly.');
    print('Success: Query parameter "session" (${Sint.parameters['session']}) captured correctly.');

    print('\n[FINAL VALIDATION] High-fidelity routing verified for Open Neom.');
    print('='*50 + '\n');
  });
}