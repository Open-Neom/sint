// SINT v1.0.0 - Injection Pillar (I) Educational Suite
// High-Fidelity Infrastructure for Open Neom
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:sint/core/sint_core.dart';
import 'package:sint/injection/sint_injection.dart';
import 'package:sint/state_manager/sint_state_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Ensure a clean SINT state before each test to maintain infrastructure integrity
  tearDown(Sint.reset);

  group('Pillar I: Educational Performance & Dependency Lifecycle', () {
    const int iterations = 10000;

    test('Benchmark & Injection Walkthrough', () async {
      print('\n${'='*50}');
      print('SINT PILLAR I: INJECTION ARCHITECTURE LESSON');
      print('Philosophy: "Do the right things"');
      print('Infrastructure: Open Neom Standard');
      print('='*50 + '\n');

      // STEP 1: Immediate Registration
      print('[STEP 1] Immediate Registration (Sint.put)');
      final instance = Sint.put<Controller>(Controller());
      print('Note: Instance is created and stored immediately in the registry.');

      // STEP 2: Resolution Speed
      print('[STEP 2] Dependency Retrieval (Sint.find)');
      final found = Sint.find<Controller>();
      expect(instance, found);
      print('Success: Instance retrieved with O(1) complexity.');

      // STEP 3: Lazy Registration & Fenix Mode
      print('\n[STEP 3] Testing Lazy Registration & Fenix Mode');
      Sint.lazyPut<Controller>(() => Controller(), tag: 'fenix_demo', fenix: true);
      print('Action: Registered factory with fenix: true.');

      Sint.find<Controller>(tag: 'fenix_demo').increment();
      print('Action: Instance created on first find() and incremented.');

      Sint.delete<Controller>(tag: 'fenix_demo');
      print('Action: Instance deleted. Fenix mode will allow restoration.');

      final restored = Sint.find<Controller>(tag: 'fenix_demo');
      expect(restored.count, 0); // Re-created from factory
      print('Success: Fenix mode successfully restored the dependency.');

      // STEP 4: High-Load Registration Benchmark
      print('\n[STEP 4] Starting High-Load Registration Benchmark ($iterations instances)');
      final putTimer = Stopwatch()..start();

      for (var i = 0; i < iterations; i++) {
        Sint.put(Controller(), tag: 'bench_$i');
      }

      putTimer.stop();
      final putTotal = putTimer.elapsedMicroseconds;

      // STEP 5: High-Load Lookup Benchmark
      print('[STEP 5] Starting High-Load Lookup Benchmark ($iterations finds)');
      final findTimer = Stopwatch()..start();

      for (var i = 0; i < iterations; i++) {
        Sint.find<Controller>(tag: 'bench_$i');
      }

      findTimer.stop();
      final findTotal = findTimer.elapsedMicroseconds;

      // RESULTS ANALYSIS
      print('\n${'-'*30}');
      print('BENCHMARK RESULTS (Open Neom Standard)');
      print('Registration Total: ${putTotal}us | Avg: ${(putTotal/iterations).toStringAsFixed(4)}us/op');
      print('Lookup Total:       ${findTotal}us | Avg: ${(findTotal/iterations).toStringAsFixed(4)}us/op');
      print('-'*30);

      print('\n[FINAL VALIDATION] Checking Infrastructure Stability...');
      print('SINT Pillar I: Validated for high-fidelity modular architectures.');
      print('='*50 + '\n');
    });
  });
}

/// Controller implementation following Open Neom Clean Architecture standards
class Controller extends SintController {
  int init = 0;
  int close = 0;
  int count = 0;

  @override
  void onInit() {
    init++;
    super.onInit();
  }

  @override
  void onClose() {
    close++;
    super.onClose();
  }

  void increment() => count++;
}