import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:sint/sint.dart';

class _TrackingPageTransitionsBuilder extends material.PageTransitionsBuilder {
  _TrackingPageTransitionsBuilder(this.onBuild);

  final VoidCallback onBuild;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    onBuild();
    return child;
  }
}

class _DynamicIdController extends SintController {
  int value = 0;

  void bump(Object id) {
    value++;
    update([id]);
  }
}

void main() {
  tearDown(Sint.reset);

  testWidgets(
    'SintAppBar renders standalone material_ui AppBar & respects materialTheme when enableLegacyCompatibility is false',
    (tester) async {
      await tester.pumpWidget(
        SintApp(
          design: SintDesign.material,
          enableLegacyCompatibility: false,
          materialTheme: material.ThemeData.dark().copyWith(
            appBarTheme: const material.AppBarTheme(
              foregroundColor: Color(0xFF00E5FF),
            ),
          ),
          initialRoute: '/',
          sintPages: [
            SintPage(
              name: '/',
              page: () => material.Scaffold(
                appBar: const SintAppBar(title: 'home'),
                body: material.ElevatedButton(
                  onPressed: () => Sint.toNamed('/details'),
                  child: const Text('Go'),
                ),
              ),
            ),
            SintPage(
              name: '/details',
              page: () => const material.Scaffold(
                appBar: SintAppBar(title: 'details'),
                body: Text('Detail Body'),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(material.AppBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.text('Detail Body'), findsOneWidget);
      expect(find.byType(material.IconButton), findsOneWidget);

      await tester.tap(find.byType(material.IconButton));
      await tester.pumpAndSettle();

      expect(find.text('Go'), findsOneWidget);
    },
  );

  testWidgets(
    'SintSnackBar renders standalone material_ui widgets, skips unused pulse ticker for non-Icon widgets, and closes cleanly',
    (tester) async {
      await tester.pumpWidget(
        SintApp(
          design: SintDesign.material,
          enableLegacyCompatibility: false,
          initialRoute: '/',
          sintPages: [
            SintPage(
              name: '/',
              page: () => const material.Scaffold(body: Text('Root')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final progressController = AnimationController(
        vsync: tester,
        duration: const Duration(seconds: 1),
        value: 0.5,
      );
      addTearDown(progressController.dispose);

      final controller = Sint.snackbar(
        'Saved',
        'Standalone snackbar body',
        icon: const SizedBox(width: 16, height: 16),
        shouldIconPulse: true,
        showProgressIndicator: true,
        progressIndicatorController: progressController,
        barBlur: 0,
        duration: const Duration(seconds: 30),
        animationDuration: const Duration(milliseconds: 50),
      );

      // Because `icon` is a non-Icon widget, no infinite pulse ticker runs;
      // the 50ms slide-in settles immediately without timing out.
      await tester.pumpAndSettle();

      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Standalone snackbar body'), findsOneWidget);
      expect(find.byType(material.LinearProgressIndicator), findsOneWidget);

      await controller.close(withAnimations: false);
      await tester.pumpAndSettle();
      expect(find.text('Standalone snackbar body'), findsNothing);
    },
  );

  testWidgets(
    'Sint.snackbar and Sint.showOverlay work safely in standalone MaterialApp without SintRoot',
    (tester) async {
      await tester.pumpWidget(
        const material.MaterialApp(
          home: material.Scaffold(body: Text('Plain Host')),
        ),
      );
      await tester.pumpAndSettle();

      final snackbar = Sint.snackbar(
        'Hello',
        'Fallback snackbar',
        barBlur: 0,
        duration: null,
        animationDuration: const Duration(milliseconds: 50),
      );
      await tester.pumpAndSettle();
      expect(find.text('Fallback snackbar'), findsOneWidget);
      await snackbar.close(withAnimations: false);
      await tester.pumpAndSettle();
      expect(find.text('Fallback snackbar'), findsNothing);

      final result = await Sint.showOverlay<int>(asyncFunction: () async => 42);
      expect(result, 42);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'SintApp honors custom standalone materialTheme.pageTransitionsTheme',
    (tester) async {
      var transitionBuilds = 0;
      final builder = _TrackingPageTransitionsBuilder(() => transitionBuilds++);
      await tester.pumpWidget(
        SintApp(
          design: SintDesign.material,
          enableLegacyCompatibility: false,
          materialTheme: material.ThemeData(
            pageTransitionsTheme: material.PageTransitionsTheme(
              builders: {
                for (final platform in TargetPlatform.values) platform: builder,
              },
            ),
          ),
          initialRoute: '/',
          sintPages: [
            SintPage(
              name: '/',
              page: () => material.Scaffold(
                body: material.TextButton(
                  onPressed: () => Sint.toNamed('/next'),
                  child: const Text('Next'),
                ),
              ),
            ),
            SintPage(
              name: '/next',
              page: () => const material.Scaffold(body: Text('Second')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Second'), findsOneWidget);
      expect(transitionBuilds, greaterThan(0));
    },
  );

  testWidgets(
    'RouteData.ofRoute recognizes standalone material_ui and cupertino_ui modal routes',
    (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        material.MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      final matDialog = material.DialogRoute<void>(
        context: capturedContext,
        builder: (_) => const SizedBox(),
      );
      final matSheet = material.ModalBottomSheetRoute<void>(
        builder: (_) => const SizedBox(),
        isScrollControlled: false,
      );
      final cupDialog = cupertino.CupertinoDialogRoute<void>(
        context: capturedContext,
        builder: (_) => const SizedBox(),
      );
      final cupPopup = cupertino.CupertinoModalPopupRoute<void>(
        builder: (_) => const SizedBox(),
      );

      expect(RouteData.ofRoute(matDialog).isDialog, isTrue);
      expect(RouteData.ofRoute(matSheet).isBottomSheet, isTrue);
      expect(RouteData.ofRoute(cupDialog).isDialog, isTrue);
      expect(RouteData.ofRoute(cupPopup).isBottomSheet, isTrue);
    },
  );

  test('ListNotifier prunes empty dynamic id groups upon listener disposal', () {
    final controller = _DynamicIdController();
    var calls = 0;

    for (var i = 0; i < 500; i++) {
      final id = 'row_$i';
      final dispose = controller.addListenerId(id, () => calls++);
      controller.bump(id);
      dispose();
    }

    expect(calls, 500);
    // Re-triggering disposed ids is a safe no-op and does not invoke listeners.
    controller.bump('row_0');
    controller.bump('row_499');
    expect(calls, 500);

    // Re-subscribing to a previously pruned id works seamlessly.
    final disposeAgain = controller.addListenerId('row_0', () => calls++);
    controller.bump('row_0');
    expect(calls, 501);
    disposeAgain();
    controller.dispose();
  });
}
