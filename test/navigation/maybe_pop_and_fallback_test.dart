import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

void main() {
  tearDown(Sint.reset);

  group('Sint.maybePop, Sint.canPop & safe Sint.pop in SintMaterialApp', () {
    testWidgets('returns false on root route and Sint.pop is a safe no-op', (
      tester,
    ) async {
      await tester.pumpWidget(
        SintMaterialApp(
          initialRoute: '/home',
          sintPages: [
            SintPage(
              name: '/home',
              page: () => const Scaffold(body: Text('Root Home')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(Sint.canPop, isFalse);
      // Calling Sint.pop() on root with no modal must NOT throw AssertionError.
      Sint.pop();
      await tester.pumpAndSettle();
      expect(find.text('Root Home'), findsOneWidget);

      final didPop = await Sint.maybePop();
      expect(didPop, isFalse);
      expect(find.text('Root Home'), findsOneWidget);
    });

    testWidgets('closes open Sint.dialog with result before popping page', (
      tester,
    ) async {
      await tester.pumpWidget(
        SintMaterialApp(
          initialRoute: '/home',
          sintPages: [
            SintPage(
              name: '/home',
              page: () => const Scaffold(body: Text('Home')),
            ),
            SintPage(
              name: '/details',
              page: () => const Scaffold(body: Text('Details')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      Sint.toNamed('/details');
      await tester.pumpAndSettle();
      expect(find.text('Details'), findsOneWidget);
      expect(Sint.canPop, isTrue);

      final dialogFuture = Sint.dialog<String>(
        const AlertDialog(title: Text('Confirm Modal')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Confirm Modal'), findsOneWidget);

      final closedModal = await Sint.maybePop<String>('accepted');
      await tester.pumpAndSettle();
      expect(closedModal, isTrue);
      expect(await dialogFuture, 'accepted');
      expect(find.text('Confirm Modal'), findsNothing);
      // Details page remains intact underneath!
      expect(find.text('Details'), findsOneWidget);

      final poppedPage = await Sint.maybePop();
      await tester.pumpAndSettle();
      expect(poppedPage, isTrue);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('honors PopScope(canPop: false) disposition', (tester) async {
      var blockedAttempts = 0;
      await tester.pumpWidget(
        SintMaterialApp(
          initialRoute: '/home',
          sintPages: [
            SintPage(
              name: '/home',
              page: () => const Scaffold(body: Text('Home')),
            ),
            SintPage(
              name: '/guarded',
              page: () => PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop) blockedAttempts++;
                },
                child: const Scaffold(body: Text('Guarded')),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      Sint.toNamed('/guarded');
      await tester.pumpAndSettle();
      expect(find.text('Guarded'), findsOneWidget);

      await Sint.maybePop();
      await tester.pumpAndSettle();
      expect(blockedAttempts, 1);
      expect(find.text('Guarded'), findsOneWidget);
    });
  });

  group('Standalone MaterialApp fallback (for widget tests)', () {
    testWidgets('Sint.to, Sint.dialog, Sint.pop & Sint.back work in MaterialApp', (
      tester,
    ) async {
      int? returnedFromPage;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextButton(
              onPressed: () async {
                returnedFromPage = await Sint.to<int>(
                  () => Scaffold(
                    body: Column(
                      children: [
                        const Text('Child Page'),
                        TextButton(
                          onPressed: () => Sint.back(result: 42),
                          child: const Text('Return 42'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: const Text('Open Child'),
            ),
          ),
        ),
      );

      expect(Sint.canPop, isFalse);
      await tester.tap(find.text('Open Child'));
      await tester.pumpAndSettle();
      expect(find.text('Child Page'), findsOneWidget);
      expect(Sint.canPop, isTrue);

      final modalRes = Sint.dialog<bool>(
        AlertDialog(
          title: const Text('Plain App Modal'),
          actions: [
            TextButton(
              onPressed: () => Sint.pop(true),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Plain App Modal'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(await modalRes, isTrue);
      expect(find.text('Child Page'), findsOneWidget);

      await tester.tap(find.text('Return 42'));
      await tester.pumpAndSettle();
      expect(returnedFromPage, 42);
      expect(find.text('Open Child'), findsOneWidget);
    });
  });
}
