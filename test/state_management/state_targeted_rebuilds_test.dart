// SINT v1.0.0 - Infrastructure Performance Summary
// High-Fidelity Audit for Open Neom
// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

void main() {
  // Reset SINT state between tests for high-fidelity isolation
  tearDown(() => Sint.reset());

  group('Open Neom: 5-Pillar Performance Audit', () {

    test('1. Pillar S: Reactive Benchmark vs Native Tools', () async {
      print('\n' + '='*50 + '\nPILLAR S: HIGH-LOAD REACTIVE AUDIT\n' + '='*50);
      const int iterations = 30000;
      final rxTimer = Stopwatch()..start();
      final rxCompleter = Completer<int>();
      final rx = 0.obs;

      rx.listen((v) {
        if (v == iterations) {
          rxTimer.stop();
          rxCompleter.complete(rxTimer.elapsedMicroseconds);
        }
      });

      for (var i = 1; i <= iterations; i++) rx.value = i;
      final sintRxTime = await rxCompleter.future;

      print('SINT Rx Total Time: ${sintRxTime}us');
      print('Avg Speed: ${(sintRxTime / iterations).toStringAsFixed(4)}us/op');
    });

    testWidgets('2. Pillar T: Translation with Dynamic Parameters', (tester) async {
      print('\n[PILLAR T] Benchmarking trParams Interpolation');

      await tester.pumpWidget(SintMaterialApp(
        translations: BenchmarkTranslations(),
        locale: const Locale('en', 'US'),
        home: const Scaffold(),
      ));

      // [FIX] Settle initialization timers from SintRoot before benchmarking
      await tester.pumpAndSettle();

      final timer = Stopwatch()..start();
      const iterations = 10000;
      for (var i = 0; i < iterations; i++) {
        final _ = 'welcome_user'.trParams({'name': 'Serzen', 'id': '$i'});
      }
      timer.stop();

      print('Iterations: $iterations dynamic lookups');
      print('Avg Speed:  ${(timer.elapsedMicroseconds / iterations).toStringAsFixed(4)}us/op');

      // [FIX] Clear any remaining timers before disposing the test
      await tester.pumpAndSettle();
    });

    test('3. Pillar I: Deep Dependency Resolution', () async {
      print('\n[PILLAR I] Registering and Finding Nested Controllers');
      // Setup dependency chain
      for(int i=0; i<10; i++) Sint.put(BenchmarkController(), tag: 'depth_$i');

      final timer = Stopwatch()..start();
      const iterations = 5000;
      for (var i = 0; i < iterations; i++) {
        Sint.find<BenchmarkController>(tag: 'depth_9');
      }
      timer.stop();

      print('Lookup iterations: $iterations (Depth: 10)');
      print('Avg Latency:       ${(timer.elapsedMicroseconds / iterations).toStringAsFixed(4)}us/find');
    });

    testWidgets('4. Pillar N: Multiple Middleware Chain Execution', (tester) async {
      print('\n[PILLAR N] Measuring 5 Middleware Interception Layers');

      await tester.pumpWidget(SintMaterialApp(
        initialRoute: '/',
        sintPages: [
          SintPage(name: '/', page: () => const SizedBox()),
          SintPage(
            name: '/protected',
            page: () => const SizedBox(),
            transition: Transition.noTransition,
            middlewares: List.generate(5, (_) => BenchmarkAuthMiddleware()),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      final timer = Stopwatch()..start();
      Sint.toNamed('/protected');

      // [FIX] Use timed pump to ensure the middleware chain and routing state settle
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      timer.stop();

      print('Total Middleware Chain Latency (5 layers): ${timer.elapsedMicroseconds}us');
      expect(Sint.currentRoute, '/protected');
    });

    test('5. Core: Stream-to-Rx Synchronization Latency', () async {
      print('\n[CORE] Stream-to-Rx Binding Latency');
      final controller = StreamController<int>();
      final rx = 0.obs;
      rx.bindStream(controller.stream);

      final timer = Stopwatch()..start();
      controller.add(100);

      // Yielding to microtask queue for high-fidelity sync
      await Future.delayed(Duration.zero);
      timer.stop();

      print('Stream-to-Rx Sync Latency: ${timer.elapsedMicroseconds}us');
      await controller.close();
      print('\n' + '='*50 + '\n');
    });
  });
}

// --- INFRASTRUCTURE MOCKS ---
class BenchmarkController extends SintController {}
class BenchmarkAuthMiddleware extends SintMiddleware {
  @override
  Future<RouteDecoder?> redirectDelegate(RouteDecoder decoder) async => decoder;
}
class BenchmarkTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {'welcome_user': 'Welcome, @name! Your ID is @id.'},
  };
}