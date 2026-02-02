// SINT v1.0.0 - State Management Pillar (S) Simple vs Reactive
// High-Fidelity Infrastructure for Open Neom
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

void main() {
  group('Pillar S: Simple vs Reactive Performance', () {
    const int iterations = 50000;

    test('Benchmark: update() vs .obs assignment', () async {
      print('\n${'='*50}');
      print('SINT PILLAR S: SIMPLE VS REACTIVE LESSON');
      print('Infrastructure: Open Neom Standard');
      print('='*50 + '\n');

      final controller = Sint.put(SimpleController());
      final rxValue = 0.obs;

      // STEP 1: Simple State Benchmark
      print('[STEP 1] Benchmarking Simple State (update())');
      final timerSimple = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        controller.increment();
      }
      timerSimple.stop();
      print('Action: $iterations manual updates executed.');

      // STEP 2: Reactive State Benchmark
      print('\n[STEP 2] Benchmarking Reactive State (.obs)');
      final timerRx = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        rxValue.value = i;
      }
      timerRx.stop();
      print('Action: $iterations reactive assignments executed.');

      // STEP 3: Results Analysis
      final simpleAvg = timerSimple.elapsedMicroseconds / iterations;
      final rxAvg = timerRx.elapsedMicroseconds / iterations;

      print('\n${'-'*30}');
      print('BENCHMARK RESULTS (Open Neom Standard)');
      print('Simple Update Avg: ${simpleAvg.toStringAsFixed(4)}us/op');
      print('Reactive Rx Avg:   ${rxAvg.toStringAsFixed(4)}us/op');
      print('Note: Simple state is often faster for batch processing.');
      print('-'*30);
      print('='*50 + '\n');
    });
  });
}

class SimpleController extends SintController {
  int count = 0;
  void increment() {
    count++;
    update(); // Simple state notification
  }
}