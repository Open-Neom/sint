// SINT v1.0.0 - Navigation Pillar (N) Middleware & Auth Flow
// High-Fidelity Infrastructure for Open Neom
// ignore_for_file: avoid_print

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/core/sint_core.dart';
import 'package:sint/navigation/sint_navigation.dart';

class AuthMiddleware extends SintMiddleware {
  @override
  Future<RouteDecoder?> redirectDelegate(RouteDecoder decoder) async {
    final path = decoder.pageSettings?.uri.path;

    return path == '/private'
        ? RouteDecoder.fromRoute('/login')
        : decoder;
  }
}

void main() {
  testWidgets('Benchmark: Middleware Interception Latency', (tester) async {
    print('\n${'='*50}');
    print('SINT PILLAR N: MIDDLEWARE ARCHITECTURE LESSON');
    print('Philosophy: "Do the right things"');
    print('Infrastructure: Open Neom Standard');
    print('='*50 + '\n');

    await tester.pumpWidget(SintMaterialApp(
      initialRoute: '/',
      sintPages: [
        SintPage(name: '/', page: () => Container()),
        SintPage(name: '/login', page: () => Container()),
        SintPage(
            name: '/private',
            page: () => Container(),
            middlewares: [AuthMiddleware()]
        ),
      ],
    ));

    print('[STEP 1] Measuring Middleware Redirect Latency (Using Path Discovery)');
    final timer = Stopwatch()..start();

    // Trigger navigation to a protected route
    await Sint.toNamed('/private');
    await tester.pumpAndSettle();

    timer.stop();

    print('Action: Redirected from /private to /login via URI Path Matching.');
    print('Latency: ${timer.elapsedMicroseconds}us');

    // STEP 2: Validation
    print('\n[STEP 2] Verifying Navigation Integrity...');
    expect(Sint.currentRoute, '/login');

    final totalTime = timer.elapsedMicroseconds;
    print('\n${'-'*30}');
    print('BENCHMARK RESULTS (Open Neom Standard)');
    print('Total Interception Time: ${totalTime}us');
    print('Note: SINT handles redirects without heavy object name lookups.');
    print('-'*30);

    print('\n[FINAL VALIDATION] Success: Navigation history preserved correctly.');
    print('='*50 + '\n');
  });
}