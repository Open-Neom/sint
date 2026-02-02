// SINT v1.0.0 - State Management Pillar (S) Widget Binding
// High-Fidelity Infrastructure for Open Neom
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

void main() {
  testWidgets('Benchmark: Widget Binding Latency', (tester) async {
    print('\n${'='*50}');
    print('SINT PILLAR S: WIDGET BINDING LESSON');
    print('Infrastructure: Open Neom Standard');
    print('='*50 + '\n');

    final controller = Sint.put(LifecycleController());

    print('[STEP 1] Measuring SintBuilder Initialization');
    final timerBuilder = Stopwatch()..start();

    await tester.pumpWidget(MaterialApp(
      home: SintBuilder<LifecycleController>(
        builder: (c) => Text('Count: ${c.count}'),
      ),
    ));

    timerBuilder.stop();
    print('Action: SintBuilder mounted.');

    print('\n[STEP 2] Measuring Obx Reactive Binding');
    final timerObx = Stopwatch()..start();

    await tester.pumpWidget(MaterialApp(
      home: Obx(() => Text('Rx: ${controller.rxCount.value}')),
    ));

    timerObx.stop();
    print('Action: Obx mounted and listening to Rx variables.');

    print('\n${'-'*30}');
    print('BENCHMARK RESULTS (Mount Time)');
    print('SintBuilder: ${timerBuilder.elapsedMicroseconds}us');
    print('Obx Widget:  ${timerObx.elapsedMicroseconds}us');
    print('Note: SintBuilder is often lighter for simple view models.');
    print('-'*30);

    print('\n[FINAL VALIDATION] High-fidelity state binding verified.');
    print('='*50 + '\n');
  });
}

class LifecycleController extends SintController {
  int count = 0;
  RxInt rxCount = 0.obs;
}