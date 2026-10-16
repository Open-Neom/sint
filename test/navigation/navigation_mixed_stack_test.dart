import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

void main() {
  testWidgets('system back pops an imperative route before its SINT host', (
    tester,
  ) async {
    final host = await _mount(tester);
    final homeResult = host.delegate.toNamed<String>('/home');
    await tester.pumpAndSettle();
    final routeResult = host.navigator.push<String>(
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('imperative route')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(await routeResult, isNull);
    expect(find.text('home'), findsOneWidget);
    expect(host.names, ['/', '/home']);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(await homeResult, isNull);
    expect(find.text('root'), findsOneWidget);
    expect(host.names, ['/']);
  });

  testWidgets(
    'imperative pop completes SINT result and cannot resurrect page',
    (tester) async {
      final host = await _mount(tester);
      final homeResult = host.delegate.toNamed<String>('/home');
      await tester.pumpAndSettle();
      host.navigator.pop('finished');
      await tester.pumpAndSettle();
      expect(await homeResult, 'finished');
      expect(host.names, ['/']);

      final detailResult = host.delegate.toNamed<String>('/detail');
      await tester.pumpAndSettle();
      expect(find.text('detail'), findsOneWidget);
      expect(host.names, ['/', '/detail']);
      host.delegate.back<String>('detail closed');
      await tester.pumpAndSettle();
      expect(await detailResult, 'detail closed');
      expect(host.names, ['/']);
      expect(find.text('root'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('imperative replacement removes SINT pages and returns to root', (
    tester,
  ) async {
    final host = await _mount(tester);
    final homeResult = host.delegate.toNamed<String>('/home');
    await tester.pumpAndSettle();
    final replacement = host.navigator.pushAndRemoveUntil<String>(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/replacement'),
        builder: (_) => const Scaffold(body: Text('replacement')),
      ),
      (route) => route.isFirst,
    );
    await tester.pumpAndSettle();
    expect(await homeResult, isNull);
    expect(host.names, ['/']);
    expect(find.text('replacement'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(await replacement, isNull);
    expect(find.text('root'), findsOneWidget);
    final again = host.delegate.toNamed<String>('/home');
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
    host.navigator.pop('again');
    await tester.pumpAndSettle();
    expect(await again, 'again');
    expect(host.names, ['/']);
  });

  testWidgets('removeRoute synchronizes a non-top page and preserves result', (
    tester,
  ) async {
    final host = await _mount(tester);
    final homeResult = host.delegate.toNamed<String>('/home');
    await tester.pumpAndSettle();
    final homeRoute = ModalRoute.of(tester.element(find.text('home')))!;
    final detailResult = host.delegate.toNamed<String>('/detail');
    await tester.pumpAndSettle();
    host.navigator.removeRoute(homeRoute, 'removed');
    await tester.pumpAndSettle();
    expect(await homeResult, 'removed');
    expect(host.names, ['/', '/detail']);
    expect(find.text('detail'), findsOneWidget);
    await host.delegate.popRoute();
    await tester.pumpAndSettle();
    expect(await detailResult, isNull);
    expect(find.text('root'), findsOneWidget);
    expect(host.names, ['/']);
  });

  testWidgets('delegate back is idempotent with Navigator removal callbacks', (
    tester,
  ) async {
    final host = await _mount(tester);
    final result = host.delegate.toNamed<String>('/home');
    await tester.pumpAndSettle();
    host.delegate.back<String>('done');
    await tester.pumpAndSettle();
    expect(await result, 'done');
    expect(host.names, ['/']);
    expect(await host.delegate.popRoute(), isFalse);
    expect(host.names, ['/']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('system back respects a SINT page PopScope', (tester) async {
    final allowed = ValueNotifier(false);
    addTearDown(allowed.dispose);
    final invocations = <bool>[];
    final host = await _mount(
      tester,
      home: ValueListenableBuilder<bool>(
        valueListenable: allowed,
        builder: (_, canPop, _) => PopScope<String>(
          canPop: canPop,
          onPopInvokedWithResult: (didPop, result) => invocations.add(didPop),
          child: const Scaffold(body: Text('home')),
        ),
      ),
    );
    final result = host.delegate.toNamed<String>('/home');
    await tester.pumpAndSettle();
    expect(await host.delegate.popRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(invocations, [false]);
    expect(host.names, ['/', '/home']);
    expect(find.text('home'), findsOneWidget);
    allowed.value = true;
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(await result, isNull);
    expect(host.names, ['/']);
  });

  testWidgets('pageless PopScope cannot accidentally remove its SINT host', (
    tester,
  ) async {
    final host = await _mount(tester);
    final home = host.delegate.toNamed<String>('/home');
    await tester.pumpAndSettle();
    var rejected = 0;
    final imperativeRoute = host.navigator.push<String>(
      MaterialPageRoute(
        builder: (_) => PopScope<String>(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) rejected++;
          },
          child: const Scaffold(body: Text('guarded route')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(rejected, 1);
    expect(find.text('guarded route'), findsOneWidget);
    expect(host.names, ['/', '/home']);
    host.navigator.pop();
    await tester.pumpAndSettle();
    expect(await imperativeRoute, isNull);
    host.delegate.back<String>();
    await tester.pumpAndSettle();
    expect(await home, isNull);
    expect(host.names, ['/']);
  });

  testWidgets('system back at the initial root bubbles without emptying it', (
    tester,
  ) async {
    final host = await _mount(tester);
    expect(await host.delegate.popRoute(), isFalse);
    await tester.pumpAndSettle();
    expect(host.names, ['/']);
    expect(find.text('root'), findsOneWidget);
  });

  for (final usePicker in [true, false]) {
    testWidgets(
      'filtered visual pages preserve history and back (${usePicker ? 'picker' : 'participation'})',
      (tester) async {
        final host = await _mount(
          tester,
          showOnlyCurrentPage: usePicker,
          participatingPagesOnly: !usePicker,
        );
        var homeCompleted = false;
        final home = host.delegate.toNamed<String>('/home');
        home.then((_) => homeCompleted = true);
        await tester.pumpAndSettle();
        final detail = host.delegate.toNamed<String>('/detail');
        await tester.pumpAndSettle();

        expect(host.names, ['/', '/home', '/detail']);
        expect(homeCompleted, isFalse);
        expect(
          ModalRoute.of(tester.element(find.text('detail')))!.isFirst,
          isTrue,
        );
        expect(await host.delegate.popRoute(result: 'detail closed'), isTrue);
        await tester.pumpAndSettle();
        expect(await detail, 'detail closed');
        expect(host.names, ['/', '/home']);
        expect(homeCompleted, isFalse);
        expect(find.text('home'), findsOneWidget);

        expect(await host.delegate.popRoute(result: 'home closed'), isTrue);
        await tester.pumpAndSettle();
        expect(await home, 'home closed');
        expect(host.names, ['/']);
        expect(find.text('root'), findsOneWidget);
        expect(await host.delegate.popRoute(), isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('page-mode back retains a filtered nested page branch', (
    tester,
  ) async {
    final host = await _mount(
      tester,
      showOnlyCurrentPage: true,
      nestedHome: true,
    );
    final home = host.delegate.toNamed<String>('/home');
    await tester.pumpAndSettle();
    final detail = host.delegate.toNamed<String>('/home/detail');
    await tester.pumpAndSettle();
    expect(host.names, ['/', '/home', '/home/detail']);
    expect(find.text('nested detail'), findsOneWidget);

    expect(
      await host.delegate.popRoute(
        popMode: PopMode.page,
        result: 'nested closed',
      ),
      isTrue,
    );
    await tester.pumpAndSettle();
    expect(await detail, 'nested closed');
    expect(host.names, ['/', '/home']);
    expect(find.text('home'), findsOneWidget);
    expect(await host.delegate.popRoute(popMode: PopMode.page), isTrue);
    await tester.pumpAndSettle();
    expect(await home, isNull);
    expect(host.names, ['/']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('declarative back retains middleware on the returning page', (
    tester,
  ) async {
    final middleware = _RecordingMiddleware();
    final host = await _mount(tester, homeMiddlewares: [middleware]);
    final home = host.delegate.toNamed<String>('/home');
    await tester.pumpAndSettle();
    final detail = host.delegate.toNamed<String>('/detail');
    await tester.pumpAndSettle();
    expect(middleware.visits, ['/home']);

    expect(await host.delegate.popRoute(result: 'closed'), isTrue);
    await tester.pumpAndSettle();
    expect(await detail, 'closed');
    expect(middleware.visits, ['/home', '/home']);
    expect(host.names, ['/', '/home']);
    expect(find.text('home'), findsOneWidget);
    host.delegate.back<String>();
    await tester.pumpAndSettle();
    expect(await home, isNull);
  });

  testWidgets('direct SintNavigator retains the legacy onPopPage callback', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final pages = <Page<String>>[
      const MaterialPage(key: ValueKey('root'), child: Text('root')),
      const MaterialPage(key: ValueKey('detail'), child: Text('detail')),
    ];
    final results = <Object?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => SintNavigator(
            key: navigatorKey,
            pages: List.of(pages),
            onPopPage: (route, result) {
              if (!route.didPop(result)) return false;
              results.add(result);
              setState(() => pages.removeLast());
              return true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    navigatorKey.currentState!.pop('closed');
    await tester.pumpAndSettle();
    expect(results, ['closed']);
    expect(find.text('root'), findsOneWidget);
    expect(find.text('detail'), findsNothing);
  });
}

class _RecordingMiddleware extends SintMiddleware {
  final visits = <String?>[];

  @override
  Future<RouteDecoder?> redirectDelegate(RouteDecoder decoder) async {
    visits.add(decoder.pageSettings?.name);
    return decoder;
  }
}

class _Host {
  _Host(this.delegate);
  final SintDelegate delegate;
  NavigatorState get navigator => delegate.navigatorKey.currentState!;
  List<String?> get names =>
      delegate.activePages.map((entry) => entry.route?.name).toList();
}

Future<_Host> _mount(
  WidgetTester tester, {
  Widget? home,
  List<SintMiddleware> homeMiddlewares = const [],
  bool showOnlyCurrentPage = false,
  bool participatingPagesOnly = false,
  bool nestedHome = false,
}) async {
  final pages = [
    SintPage<String>(
      name: '/',
      transition: Transition.noTransition,
      page: () => const Scaffold(body: Text('root')),
    ),
    SintPage<String>(
      name: '/home',
      participatesInRootNavigator: participatingPagesOnly ? true : null,
      transition: Transition.noTransition,
      page: () => home ?? const Scaffold(body: Text('home')),
      middlewares: homeMiddlewares,
      children: [
        if (nestedHome)
          SintPage<String>(
            name: '/detail',
            transition: Transition.noTransition,
            page: () => const Scaffold(body: Text('nested detail')),
          ),
      ],
    ),
    SintPage<String>(
      name: '/detail',
      participatesInRootNavigator: participatingPagesOnly ? true : null,
      transition: Transition.noTransition,
      page: () => const Scaffold(body: Text('detail')),
    ),
  ];
  final delegate = SintDelegate(
    pages: pages,
    initialRoute: '/',
    pickPagesForRootNavigator: showOnlyCurrentPage
        ? (current) => [current.route!]
        : null,
  );
  final provider = PlatformRouteInformationProvider(
    initialRouteInformation: RouteInformation(uri: Uri(path: '/')),
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    delegate.dispose();
    provider.dispose();
    Sint.resetInstance();
  });
  await tester.pumpWidget(
    SintMaterialApp.router(
      enableLog: false,
      sintPages: pages,
      routerDelegate: delegate,
      routeInformationProvider: provider,
    ),
  );
  await tester.pumpAndSettle();
  return _Host(delegate);
}
