import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as legacy;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:sint/sint.dart';

List<SintPage> _pages(Widget child) => [SintPage(name: '/', page: () => child)];

class _Counter extends SintController {
  int value = 0;
  int closes = 0;

  void increment() {
    value++;
    update();
  }

  @override
  void onClose() {
    closes++;
    super.onClose();
  }
}

void main() {
  tearDown(Sint.reset);

  testWidgets(
    'auto selects one host and the matching typed theme',
    (tester) async {
      final materialTheme = material.ThemeData(
        primaryColor: const Color(0xff123456),
      );
      const cupertinoTheme = cupertino.CupertinoThemeData(
        primaryColor: Color(0xff654321),
      );
      late BuildContext pageContext;
      await tester.pumpWidget(
        SintApp(
          materialTheme: materialTheme,
          cupertinoTheme: cupertinoTheme,
          sintPages: _pages(
            Builder(
              builder: (context) {
                pageContext = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(SintRoot), findsOneWidget);
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        expect(find.byType(cupertino.CupertinoApp), findsOneWidget);
        expect(
          pageContext.cupertinoTheme.primaryColor,
          cupertinoTheme.primaryColor,
        );
      } else {
        expect(find.byType(material.MaterialApp), findsOneWidget);
        expect(
          pageContext.materialTheme.primaryColor,
          materialTheme.primaryColor,
        );
      }
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant.all(),
  );

  testWidgets(
    'imperative theme changes preserve reactive controller and root',
    (tester) async {
      final controller = _Counter();
      late BuildContext pageContext;
      await tester.pumpWidget(
        SintApp(
          design: SintDesign.material,
          materialTheme: material.ThemeData.light(),
          materialDarkTheme: material.ThemeData.dark(),
          sintPages: _pages(
            Builder(
              builder: (context) {
                pageContext = context;
                return SintBuilder<_Counter>(
                  init: controller,
                  builder: (c) => Text('${c.value}'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final root = Sint.rootController;
      Sint.changeMaterialThemeMode(material.ThemeMode.dark);
      controller.increment();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(pageContext.materialTheme.brightness, Brightness.dark);
      expect(find.text('1'), findsOneWidget);
      expect(Sint.rootController, same(root));
      expect(Sint.find<_Counter>(), same(controller));
      await tester.pumpWidget(const SizedBox());
      expect(controller.closes, 1);
    },
  );

  testWidgets(
    'parent theme updates reach descendants without replacing the root',
    (tester) async {
      late BuildContext pageContext;
      final pages = _pages(
        Builder(
          builder: (context) {
            pageContext = context;
            return const SizedBox();
          },
        ),
      );
      await tester.pumpWidget(
        SintApp(
          materialTheme: material.ThemeData(
            primaryColor: const Color(0xff123456),
          ),
          sintPages: pages,
        ),
      );
      await tester.pumpAndSettle();
      final root = Sint.rootController;
      await tester.pumpWidget(
        SintApp(
          materialTheme: material.ThemeData(
            primaryColor: const Color(0xffabcdef),
          ),
          sintPages: pages,
        ),
      );
      await tester.pumpAndSettle();
      expect(pageContext.materialTheme.primaryColor, const Color(0xffabcdef));
      expect(Sint.rootController, same(root));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('changing one argument preserves other imperative theme values', (
    tester,
  ) async {
    final pages = _pages(const SizedBox());
    final theme = material.ThemeData(primaryColor: const Color(0xff123456));
    final darkTheme = material.ThemeData.dark();
    Widget app({
      material.ThemeData? light,
      GlobalKey<material.ScaffoldMessengerState>? messengerKey,
    }) => SintApp(
      materialTheme: light,
      materialDarkTheme: darkTheme,
      materialScaffoldMessengerKey: messengerKey,
      sintPages: pages,
    );
    await tester.pumpWidget(app(light: theme));
    await tester.pumpAndSettle();
    final root = Sint.rootController;
    Sint.changeMaterialThemeMode(material.ThemeMode.dark);
    await tester.pumpAndSettle();
    final messengerKey = GlobalKey<material.ScaffoldMessengerState>();
    await tester.pumpWidget(app(light: theme, messengerKey: messengerKey));
    await tester.pumpAndSettle();
    expect(root.config.materialThemeMode, material.ThemeMode.dark);
    expect(root.config.materialScaffoldMessengerKey, same(messengerKey));
    await tester.pumpWidget(app(messengerKey: messengerKey));
    await tester.pumpAndSettle();
    expect(root.config.materialTheme, isNull);
    expect(root.config.materialThemeMode, material.ThemeMode.dark);
    expect(Sint.rootController, same(root));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'legacy theme still uses the SDK host on iOS',
    (tester) async {
      await tester.pumpWidget(
        SintApp(
          // ignore: deprecated_member_use
          theme: legacy.ThemeData.dark(),
          sintPages: _pages(const legacy.Scaffold(body: Text('legacy'))),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(legacy.MaterialApp), findsOneWidget);
      expect(find.byType(cupertino.CupertinoApp), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'mixed legacy and standalone arguments give an actionable error',
    (tester) async {
      await tester.pumpWidget(
        SintApp(
          // ignore: deprecated_member_use
          theme: legacy.ThemeData(),
          materialTheme: material.ThemeData(),
          sintPages: _pages(const SizedBox()),
        ),
      );
      expect(
        tester.takeException(),
        isA<FlutterError>().having(
          (error) => error.toString(),
          'message',
          contains('Remove theme'),
        ),
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final design in [SintDesign.material, SintDesign.cupertino]) {
    testWidgets(
      'compatibility bridges support legacy convenience overlays in $design',
      (tester) async {
        await tester.pumpWidget(
          SintApp(
            design: design,
            sintPages: _pages(const legacy.Scaffold(body: Text('legacy page'))),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        Sint.defaultDialog(title: 'Legacy alert', textCancel: 'Dismiss');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(legacy.AlertDialog), findsOneWidget);
        await tester.tap(find.text('Dismiss'));
        await tester.pumpAndSettle();
        expect(find.byType(legacy.AlertDialog), findsNothing);
        final snackbar = Sint.snackbar('Notice', 'Compatibility message');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Compatibility message'), findsOneWidget);
        snackbar.close(withAnimations: false);
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'standalone $design supports Material descendants and overlays',
      (tester) async {
        late BuildContext pageContext;
        await tester.pumpWidget(
          SintApp(
            design: design,
            enableLegacyCompatibility: false,
            sintPages: _pages(
              material.Scaffold(
                body: Builder(
                  builder: (context) {
                    pageContext = context;
                    return const Text('modern');
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(material.ScaffoldMessenger.maybeOf(pageContext), isNotNull);
        Sint.dialog(const Text('dialog'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('dialog'), findsOneWidget);
        Sint.closeDialog();
        await tester.pumpAndSettle();
        expect(find.text('dialog'), findsNothing);
        Sint.bottomSheet(const SizedBox(height: 80, child: Text('sheet')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('sheet'), findsOneWidget);
        Sint.closeBottomSheet();
        await tester.pumpAndSettle();
        expect(find.text('sheet'), findsNothing);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
