// SINT v1.3.1 - Navigation Pillar (N) Hotfix Regression Suite
// Covers the 1.3.1 navigation fixes:
//  - Fix 4: popUntilOriginalRoute inverted condition
//  - Fix 5: offAllNamed completes pending navigation futures
//  - Fix 6: removeLastHistory no longer recurses infinitely
//  - Fix 7: optional route params ('/user/:id?') don't crash on absence
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => Sint.reset());

  group('Fix 7 — optional route params', () {
    test("'/user/:id?' matches '/user' without crashing", () {
      final parser = RouteParser(routes: [
        SintPage(name: '/', page: () => Container()),
        SintPage(name: '/user/:id?', page: () => Container()),
      ]);

      final decoder = parser.matchRoute('/user');

      expect(decoder.route, isNotNull,
          reason: 'optional param absent must still match the route');
      expect(decoder.route!.name, '/user');
      expect(decoder.route!.parameters, isNot(contains('id')));
    });

    test("'/user/:id?' matches '/user/42' and captures the param", () {
      final parser = RouteParser(routes: [
        SintPage(name: '/', page: () => Container()),
        SintPage(name: '/user/:id?', page: () => Container()),
      ]);

      final decoder = parser.matchRoute('/user/42');

      expect(decoder.route, isNotNull);
      expect(decoder.route!.parameters?['id'], '42');
    });

    test("'/user/:id?' matches '/user/' (trailing slash) without crashing",
        () {
      final parser = RouteParser(routes: [
        SintPage(name: '/', page: () => Container()),
        SintPage(name: '/user/:id?', page: () => Container()),
      ]);

      final decoder = parser.matchRoute('/user/');

      expect(decoder.route, isNotNull);
      expect(decoder.route!.parameters, isNot(contains('id')));
    });

    test('required params still parse as before', () {
      final parser = RouteParser(routes: [
        SintPage(name: '/', page: () => Container()),
        SintPage(name: '/user/:id/profile', page: () => Container()),
      ]);

      final decoder = parser.matchRoute('/user/abc123/profile');

      expect(decoder.route, isNotNull);
      expect(decoder.route!.parameters?['id'], 'abc123');
    });
  });

  group('Fix 6 — removeLastHistory', () {
    test('returns normally (no stack overflow)', () {
      // On IO platforms this is a deliberate no-op; the previous
      // implementation called itself unconditionally and overflowed
      // the stack.
      expect(() => removeLastHistory('/some-url'), returnsNormally);
    });
  });

  group('Fix 5 — offAllNamed completes pending futures', () {
    testWidgets('future of a route removed by offAllNamed completes',
        (tester) async {
      await tester.pumpWidget(SintMaterialApp(
        initialRoute: '/',
        sintPages: [
          SintPage(name: '/', page: () => const Scaffold(body: Text('home'))),
          SintPage(name: '/a', page: () => const Scaffold(body: Text('a'))),
          SintPage(name: '/b', page: () => const Scaffold(body: Text('b'))),
        ],
      ));
      await tester.pumpAndSettle();

      final pending = Sint.toNamed('/a');
      await tester.pumpAndSettle();
      expect(Sint.currentRoute, '/a');

      Sint.offAllNamed('/b');
      await tester.pumpAndSettle();
      expect(Sint.currentRoute, '/b');

      // Before the fix, this future hung forever (removed via removeLast()
      // without completing its completer).
      await expectLater(
        pending!.timeout(const Duration(seconds: 2)),
        completion(isNull),
      );
    });
  });

  // NOTE — Fix 4 (popUntilOriginalRoute == → !=) is intentionally NOT
  // covered by a widget test: the `_push` branch that consumes
  // `PreventDuplicateHandlingMode.popUntilOriginalRoute` is currently
  // unreachable through the public navigation flow because
  // `SintPage.copyWith` does not carry `preventDuplicateHandlingMode`,
  // so every route decoded via matchRoute/_configureRouterDecoder resets
  // to the default `reorderRoutes` (a pre-existing latent issue, out of
  // scope for this hotfix release). The inverted-condition fix itself is
  // applied at sint_delegate.dart (`while (_activePages.last !=
  // onStackPage)`) and is trusted to the existing navigation suite.
}
