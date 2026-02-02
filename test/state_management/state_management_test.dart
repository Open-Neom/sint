// SINT v1.0.0 - State Management Pillar (S) Educational Suite
// High-Fidelity Infrastructure for Open Neom
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:sint/core/sint_core.dart'; // Core reactive types

void main() {

  group('Pillar S: Educational Performance & Logic', () {
    const int iterations = 50000;

    test('Benchmark & Educational Walkthrough', () async {
      print('\n${'='*50}');
      print('SINT PILLAR S: REACTIVE ARCHITECTURE LESSON');
      print('Philosophy: "Do the right things"');
      print('Infrastructure: Open Neom Standard');
      print('='*50 + '\n');

      // STEP 1: Initialization
      print('[STEP 1] Initializing SINT Rx Variable (.obs)');
      final rx = 0.obs;
      int notifiedCount = 0;

      // STEP 2: The Listener
      print('[STEP 2] Registering Listener to the Observer Registry');
      rx.listen((val) {
        notifiedCount++;
      });
      print('Note: SINT avoids Stream overhead to save RAM and LOC');

      // STEP 3: High-Load Stress Test
      print('\n[STEP 3] Starting High-Load Stress Test ($iterations updates)');
      final timer = Stopwatch()..start();

      for (var i = 1; i <= iterations; i++) {
        rx.value = i;
      }

      // STEP 4: Explaining the Event Loop
      print('[STEP 4] Yielding to Dart Event Loop...');
      print('Why? SINT processes notifications in Microtasks to keep UI High-Fidelity.');

      // Yield execution to allow the microtask queue to process notifications
      await Future.delayed(Duration.zero);
      timer.stop();

      // STEP 5: Results and Analysis
      final totalTime = timer.elapsedMicroseconds;
      final avgTime = totalTime / iterations;

      print('\n${'-'*30}');
      print('BENCHMARK RESULTS (Open Neom Standard)');
      print('Total Time: ${totalTime}us');
      print('Avg Speed:  ${avgTime.toStringAsFixed(4)}us/op');
      print('Reference: SINT v1 baseline is ~4.53us/op');
      print('-'*30);

      // Final verification
      print('\n[FINAL VALIDATION] Checking Reactive Integrity...');
      if (notifiedCount == iterations) {
        print('SUCCESS: $notifiedCount/$iterations updates captured.');
      } else {
        print('FAILURE: Integrity gap detected in Pillar S.');
      }
      print('='*50 + '\n');

      expect(notifiedCount, iterations);
    });

    test('Educational: Deduplication Logic', () async {
      print('[LESSON: DEDUPLICATION]');
      final reactiveValue = 'Initial'.obs;
      int changes = 0;
      reactiveValue.listen((_) => changes++);

      print('Action: Calling same value "Initial" 3 times...');
      reactiveValue('Initial');
      reactiveValue('Initial');
      reactiveValue('Initial');

      await Future.delayed(Duration.zero);
      print('Result: $changes notifications (Expected 0 due to equality check)');
      expect(changes, 0);
    });
  });
}