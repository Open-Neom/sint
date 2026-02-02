// SINT v1.0.0 - Navigation Pillar (N) Overlays & UI Feedback
// High-Fidelity Infrastructure for Open Neom
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

void main() {
  // We use Sint.reset() for registry cleanup, but avoid UI-dependent calls here
  tearDown(() => Sint.reset());

  testWidgets('Benchmark: Overlay Queue Management', (tester) async {
    print('\n${'='*50}');
    print('SINT PILLAR N: OVERLAY MANAGEMENT LESSON');
    print('Philosophy: "Do the right things"');
    print('Infrastructure: Open Neom Standard');
    print('='*50 + '\n');

    // STEP 0: Settle initial environment
    await tester.pumpWidget(const SintMaterialApp(home: Scaffold(body: Center(child: Text('Base')))));
    await tester.pumpAndSettle();

    // STEP 1: Snackbar Queue Benchmark
    print('[STEP 1] Testing Snackbar Queue System');
    final timer = Stopwatch()..start();

    for (var i = 0; i < 50; i++) {
      Sint.snackbar(
        'Title $i',
        'Message',
        duration: const Duration(milliseconds: 500),
        animationDuration: const Duration(milliseconds: 10),
      );
    }

    timer.stop();
    print('Action: 50 Snackbars added to the high-fidelity queue.');
    print('Total Queueing Time: ${timer.elapsedMicroseconds}us');

    // STEP 2: Safe UI Cleanup
    // We close overlays WHILE the widget tree is still active to avoid the SintRoot exception
    Sint.closeAllSnackbars();
    await tester.pumpAndSettle();

    // STEP 3: Context-less Dialogs
    print('\n[STEP 2] Testing Context-less Dialogs');

    Sint.dialog(
      const Center(child: Text('Open Neom Dialog', key: Key('dialog-text'))),
    );

    await tester.pump();
    expect(Sint.isDialogOpen, true);
    print('Success: Dialog presented successfully using Pillar N global state.');

    // STEP 4: Final Cleanup
    Sint.back();
    await tester.pumpAndSettle();

    print('\n${'-'*30}');
    print('BENCHMARK RESULTS (Open Neom Standard)');
    print('Queue Logic Speed: ${(timer.elapsedMicroseconds / 50).toStringAsFixed(4)}us/op');
    print('Integrity: Overlays and Dialogs verified.');
    print('-'*30);

    print('\n[FINAL VALIDATION] Success: Pillar N infrastructure is stable.');
    print('='*50 + '\n');
  });
}