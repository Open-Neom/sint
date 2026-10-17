import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:sint/sint.dart';

void main() {
  tearDown(Sint.reset);

  testWidgets(
    'SintRouterOutlet renders nested routes and updates on navigation',
    (tester) async {
      await tester.pumpWidget(
        SintApp(
          design: SintDesign.material,
          initialRoute: '/dashboard/overview',
          sintPages: [
            SintPage(
              name: '/dashboard',
              participatesInRootNavigator: true,
              page: () => material.Scaffold(
                body: Column(
                  children: [
                    IndexedRouteBuilder(
                      routes: const [
                        '/dashboard/overview',
                        '/dashboard/settings',
                      ],
                      builder: (context, routes, index) =>
                          Text('active-index:$index'),
                    ),
                    Expanded(
                      child: SintRouterOutlet(
                        anchorRoute: '/dashboard',
                        initialRoute: '/dashboard/overview',
                      ),
                    ),
                  ],
                ),
              ),
              children: [
                SintPage(
                  name: '/overview',
                  page: () => const Center(child: Text('Overview Page')),
                ),
                SintPage(
                  name: '/settings',
                  page: () => const Center(child: Text('Settings Page')),
                ),
              ],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Overview Page'), findsOneWidget);
      expect(find.text('active-index:0'), findsOneWidget);

      Sint.toNamed('/dashboard/settings');
      await tester.pumpAndSettle();

      expect(find.text('Settings Page'), findsOneWidget);
      expect(find.text('active-index:1'), findsOneWidget);
    },
  );

  test('GetRouterOutlet deprecated alias resolves to SintRouterOutlet', () {
    // ignore: deprecated_member_use_from_same_package
    expect(GetRouterOutlet, equals(SintRouterOutlet));
  });
}
