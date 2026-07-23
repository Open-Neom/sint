// SINT v1.5.0 - Navigation Overhaul Tests
// Features: route index + extended syntax, pathParams/queryParams,
// web fixes (W1-W3), middleware fixes (M1, M4), copyWith propagation.
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

SintPage _page(String name,
        {List<SintMiddleware>? middlewares,
        PreventDuplicateHandlingMode? mode}) =>
    SintPage(
      name: name,
      page: () => const SizedBox(),
      middlewares: middlewares ?? const [],
      preventDuplicateHandlingMode:
          mode ?? PreventDuplicateHandlingMode.reorderRoutes,
    );

void main() {
  tearDown(() => Sint.reset());

  group('Feature 1 — Route index', () {
    test('literal match works (index happy path)', () {
      final parser = RouteParser(routes: [
        _page('/'),
        _page('/home'),
        _page('/user/:id'),
      ]);
      final decoder = parser.matchRoute('/home');
      expect(decoder.route, isNotNull);
      expect(decoder.route!.name, '/home');
    });

    test('param match captures value', () {
      final parser = RouteParser(routes: [
        _page('/'),
        _page('/user/:id'),
      ]);
      final settings = PageSettings(Uri.parse('/user/42'));
      final decoder = parser.matchRoute('/user/42', arguments: settings);
      expect(decoder.route, isNotNull);
      expect(settings.params['id'], '42');
      expect(settings.pathParams['id'], '42');
    });

    test('precedence: literal wins over earlier-registered param', () {
      // Param registered FIRST — the index must still prefer the literal.
      final parser = RouteParser(routes: [
        _page('/user/:id'),
        _page('/user/new'),
      ]);
      final decoder = parser.matchRoute('/user/new');
      expect(decoder.route!.name, '/user/new');
    });

    test('first-wins preserved among same-rank routes', () {
      final parser = RouteParser(routes: [
        SintPage(
            name: '/user/:id', page: () => const SizedBox(), title: 'first'),
        SintPage(
            name: '/user/:name', page: () => const SizedBox(), title: 'second'),
      ]);
      final decoder = parser.matchRoute('/user/42');
      expect(decoder.route!.title, 'first');
    });

    test('index invalidation: routes added after first match are found', () {
      final parser = RouteParser(routes: [_page('/a')]);
      expect(parser.matchRoute('/a').route, isNotNull);
      parser.addRoute(_page('/b'));
      expect(parser.matchRoute('/b').route, isNotNull);
      parser.removeRoute(parser.routes.last);
      expect(parser.matchRoute('/b').route, isNull);
    });

    test('duplicate route registration warns but does not throw', () {
      final parser = RouteParser(routes: []);
      parser.addRoute(_page('/a'));
      // Same pattern — must only log a warning (first-wins, retrocompat).
      expect(() => parser.addRoute(_page('/a')), returnsNormally);
      expect(parser.matchRoute('/a').route, isNotNull);
    });
  });

  group('Feature 2 — Extended route syntax', () {
    test('pattern param :id(\\d+) matches digits only', () {
      final parser = RouteParser(routes: [_page('/user/:id(\\d+)')]);
      final hit = parser.matchRoute('/user/42');
      expect(hit.route, isNotNull);
      final settings = PageSettings(Uri.parse('/user/42'));
      parser.matchRoute('/user/42', arguments: settings);
      expect(settings.pathParams['id'], '42');

      final miss = parser.matchRoute('/user/abc');
      expect(miss.route, isNull);
    });

    test('wildcard :path* captures remaining segments with slashes', () {
      final parser = RouteParser(routes: [_page('/docs/:path*')]);
      final settings = PageSettings(Uri.parse('/docs/a/b/c'));
      final decoder = parser.matchRoute('/docs/a/b/c', arguments: settings);
      expect(decoder.route, isNotNull);
      expect(settings.pathParams['path'], 'a/b/c');
    });

    test('wildcard requires at least one segment', () {
      final parser = RouteParser(routes: [_page('/docs/:path*')]);
      expect(parser.matchRoute('/docs').route, isNull);
    });

    test('dotted param separator is escaped (bug A4)', () {
      final parser = RouteParser(routes: [_page('/file.:ext')]);
      final hit = parser.matchRoute('/file.txt');
      expect(hit.route, isNotNull);
      // A raw '.' in the old regex matched ANY char — must not anymore.
      expect(parser.matchRoute('/fileXtxt').route, isNull);
    });

    test('literal plus in path segment is preserved (bug A2)', () {
      final parser = RouteParser(routes: [_page('/doc/:name')]);
      final settings = PageSettings(Uri.parse('/doc/a+b'));
      parser.matchRoute('/doc/a+b', arguments: settings);
      // decodeQueryComponent turned '+' into a space; decodeComponent not.
      expect(settings.pathParams['name'], 'a+b');
    });

    test('encoded slash %2F decodes to / within the segment (bug A2)', () {
      final parser = RouteParser(routes: [_page('/doc/:name')]);
      final settings = PageSettings(Uri.parse('/doc/a%2Fb'));
      parser.matchRoute('/doc/a%2Fb', arguments: settings);
      expect(settings.pathParams['name'], 'a/b');
    });

    test('unicode path params round-trip via percent-encoding', () {
      final parser = RouteParser(routes: [_page('/user/:name')]);
      final encoded = '/user/${Uri.encodeComponent('ñandú')}';
      final settings = PageSettings(Uri.parse(encoded));
      parser.matchRoute(encoded, arguments: settings);
      expect(settings.pathParams['name'], 'ñandú');
    });
  });

  group('Feature 3 — resolveRoutePath', () {
    test('substitutes path params and appends query', () {
      final url = resolveRoutePath('/user/:id',
          pathParams: {'id': '42'}, queryParams: {'tab': 'posts'});
      expect(url, '/user/42?tab=posts');
    });

    test('substitutes pattern params by name', () {
      final url = resolveRoutePath('/user/:id(\\d+)', pathParams: {'id': '7'});
      expect(url, '/user/7');
    });

    test('substitutes wildcard param', () {
      final url = resolveRoutePath('/docs/:path*', pathParams: {'path': 'a/b'});
      expect(url, '/docs/a%2Fb');
    });

    test('encodes special characters per segment', () {
      final url = resolveRoutePath('/user/:id', pathParams: {'id': 'a/b c'});
      expect(url, '/user/a%2Fb%20c');
    });

    test('preserves an existing query string', () {
      final url = resolveRoutePath('/user/:id?lang=es',
          pathParams: {'id': '42'}, queryParams: {'tab': 'posts'});
      expect(url, '/user/42?lang=es&tab=posts');
    });

    test('unresolved params are left as-is', () {
      final url = resolveRoutePath('/user/:id', pathParams: {'other': '1'});
      expect(url, '/user/:id');
    });
  });

  group('Feature 3 — toNamed with pathParams/queryParams (integration)', () {
    testWidgets('navigates to substituted URL and exposes separated params',
        (tester) async {
      await tester.pumpWidget(SintMaterialApp(
        initialRoute: '/',
        sintPages: [
          _page('/'),
          _page('/user/:id'),
        ],
      ));
      await tester.pumpAndSettle();

      Sint.toNamed('/user/:id',
          pathParams: {'id': '42'}, queryParams: {'tab': 'posts'});
      await tester.pumpAndSettle();

      // currentRoute keeps the classic path-only semantics (no query).
      expect(Sint.currentRoute, '/user/42');
      expect(Sint.pathParams, {'id': '42'});
      expect(Sint.queryParams, {'tab': 'posts'});
      // Legacy merged view keeps working (retrocompat).
      expect(Sint.parameters['id'], '42');
      expect(Sint.parameters['tab'], 'posts');
    });

    testWidgets('path params round-trip with special characters',
        (tester) async {
      await tester.pumpWidget(SintMaterialApp(
        initialRoute: '/',
        sintPages: [
          _page('/'),
          _page('/doc/:name'),
        ],
      ));
      await tester.pumpAndSettle();

      Sint.toNamed('/doc/:name', pathParams: {'name': 'a/b ñ'});
      await tester.pumpAndSettle();

      expect(Sint.pathParams['name'], 'a/b ñ');
    });
  });

  group('W3 + copyWith — restorationId & preventDuplicateHandlingMode', () {
    test('copyWith keeps restorationId (was lost to self-reference)', () {
      final page = SintPage(
        name: '/a',
        page: () => const SizedBox(),
        restorationId: 'rid-a',
      );
      final copy = page.copyWith(name: '/b');
      expect(copy.restorationId, 'rid-a');
    });

    test('copyWith propagates preventDuplicateHandlingMode', () {
      final page = SintPage(
        name: '/a',
        page: () => const SizedBox(),
        preventDuplicateHandlingMode:
            PreventDuplicateHandlingMode.popUntilOriginalRoute,
      );
      final copy = page.copyWith(parameters: const {'x': 'y'});
      expect(copy.preventDuplicateHandlingMode,
          PreventDuplicateHandlingMode.popUntilOriginalRoute);
    });

    test('restoreRouteInformation passes route state', () {
      final parser = SintInformationParser(initialRoute: '/');
      final settings = PageSettings(Uri.parse('/a'), 'my-state');
      final decoder = RouteDecoder([_page('/a')], settings);
      final info = parser.restoreRouteInformation(decoder);
      expect(info.state, 'my-state');
    });
  });

  group('W3 + 1.3.1 activation — popUntilOriginalRoute end-to-end', () {
    testWidgets('duplicate push with popUntilOriginalRoute pops back to original',
        (tester) async {
      await tester.pumpWidget(SintMaterialApp(
        initialRoute: '/',
        sintPages: [
          _page('/'),
          _page('/a', mode: PreventDuplicateHandlingMode.popUntilOriginalRoute),
          _page('/b'),
        ],
      ));
      await tester.pumpAndSettle();

      Sint.toNamed('/a');
      await tester.pumpAndSettle();
      Sint.toNamed('/b');
      await tester.pumpAndSettle();
      expect(Sint.currentRoute, '/b');

      // Pushing '/a' again must pop '/b' and land on the ORIGINAL '/a'
      // (the branch fixed in 1.3.1, now reachable because copyWith
      // propagates the mode through route matching).
      Sint.toNamed('/a');
      await tester.pumpAndSettle();

      expect(Sint.currentRoute, '/a');
      final delegate = Sint.rootController.rootDelegate;
      expect(delegate.activePages.length, 2); // '/', '/a'
    });
  });

  group('W1 — browser back/forward sync', () {
    testWidgets('setNewRoutePath to an in-stack URL pops instead of pushing',
        (tester) async {
      await tester.pumpWidget(SintMaterialApp(
        initialRoute: '/',
        sintPages: [
          _page('/'),
          _page('/a'),
          _page('/b'),
        ],
      ));
      await tester.pumpAndSettle();

      Sint.toNamed('/a');
      await tester.pumpAndSettle();
      Sint.toNamed('/b');
      await tester.pumpAndSettle();

      final delegate = Sint.rootController.rootDelegate;
      expect(delegate.activePages.length, 3);

      // Simulate the browser Back button: the platform asks the delegate
      // to restore '/a' — already present in the stack.
      await delegate.setNewRoutePath(RouteDecoder.fromRoute('/a'));
      await tester.pumpAndSettle();

      expect(Sint.currentRoute, '/a');
      expect(delegate.activePages.length, 2);
    });

    testWidgets('setNewRoutePath to the current URL is a no-op',
        (tester) async {
      await tester.pumpWidget(SintMaterialApp(
        initialRoute: '/',
        sintPages: [
          _page('/'),
          _page('/a'),
        ],
      ));
      await tester.pumpAndSettle();

      Sint.toNamed('/a');
      await tester.pumpAndSettle();

      final delegate = Sint.rootController.rootDelegate;
      final before = delegate.activePages.length;

      await delegate.setNewRoutePath(RouteDecoder.fromRoute('/a'));
      await tester.pumpAndSettle();

      expect(delegate.activePages.length, before);
      expect(Sint.currentRoute, '/a');
    });

    testWidgets('setNewRoutePath to an unknown-in-stack URL pushes',
        (tester) async {
      await tester.pumpWidget(SintMaterialApp(
        initialRoute: '/',
        sintPages: [
          _page('/'),
          _page('/a'),
          _page('/b'),
        ],
      ));
      await tester.pumpAndSettle();

      Sint.toNamed('/a');
      await tester.pumpAndSettle();

      final delegate = Sint.rootController.rootDelegate;
      await delegate.setNewRoutePath(RouteDecoder.fromRoute('/b'));
      await tester.pumpAndSettle();

      expect(Sint.currentRoute, '/b');
      expect(delegate.activePages.length, 3);
    });
  });

  group('W2 — SintUrlStrategy', () {
    test('setPath marks the strategy as configured', () {
      SintUrlStrategy.setPath();
      expect(SintUrlStrategy.isSet, isTrue);
    });

    test('setHash marks the strategy as configured', () {
      SintUrlStrategy.setHash();
      expect(SintUrlStrategy.isSet, isTrue);
    });
  });

  group('M1 — unified middleware priority', () {
    testWidgets('runMiddleware honors priority order (stable)', (tester) async {
      final calls = <String>[];

      SintMiddleware recorder(String label, int priority) =>
          _RecorderMiddleware(label, priority, calls);

      await tester.pumpWidget(SintMaterialApp(
        initialRoute: '/',
        sintPages: [
          _page('/'),
          _page('/target', middlewares: [
            recorder('prio5', 5),
            recorder('prio-8', -8),
            recorder('prio2a', 2),
            recorder('prio2b', 2), // stable: declared order among equals
          ]),
        ],
      ));
      await tester.pumpAndSettle();

      Sint.toNamed('/target');
      await tester.pumpAndSettle();

      expect(Sint.currentRoute, '/target');
      expect(calls, ['prio-8', 'prio2a', 'prio2b', 'prio5']);
    });
  });

  group('M4 — redirect cycle guard', () {
    testWidgets('cyclic redirectDelegate fails with a clear error',
        (tester) async {
      await tester.pumpWidget(SintMaterialApp(
        initialRoute: '/',
        sintPages: [
          _page('/'),
          _page('/loop-a', middlewares: [_PingPongMiddleware('/loop-b')]),
          _page('/loop-b', middlewares: [_PingPongMiddleware('/loop-a')]),
        ],
      ));
      await tester.pumpAndSettle();

      Object? error;
      try {
        await Sint.toNamed('/loop-a');
      } catch (e) {
        error = e;
      }
      expect(error, isNotNull);
      expect(error.toString(), contains('Redirect loop detected'));
    });
  });
}

class _RecorderMiddleware extends SintMiddleware {
  _RecorderMiddleware(this.label, int priority, this.calls)
      : super(priority: priority);
  final String label;
  final List<String> calls;

  @override
  Future<RouteDecoder?> redirectDelegate(RouteDecoder decoder) async {
    calls.add(label);
    return decoder;
  }
}

class _PingPongMiddleware extends SintMiddleware {
  _PingPongMiddleware(this.target);
  final String target;

  @override
  Future<RouteDecoder?> redirectDelegate(RouteDecoder decoder) async {
    // Always redirect to the other route — the pipeline must stop at the
    // depth guard instead of looping forever.
    return RouteDecoder.fromRoute(target);
  }
}
