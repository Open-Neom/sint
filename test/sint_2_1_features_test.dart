import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

class _CounterController extends SintController {
  _CounterController([this.label = 'global']);

  final String label;
  final count = 0.obs;
  late final doubled = computed(() => count.value * 2);
  bool wasClosed = false;

  @override
  void onClose() {
    wasClosed = true;
    super.onClose();
  }
}

class _SessionService extends SintService {
  bool closed = false;

  @override
  void onClose() {
    closed = true;
    super.onClose();
  }
}

class _GetxStyleBinding extends Bindings {
  @override
  void dependencies() {
    Sint.lazyPut<_CounterController>(() => _CounterController('from_bindings'));
  }
}

class _CounterView extends SintView<_CounterController> {
  const _CounterView({this.customTag});

  final String? customTag;

  @override
  String? get tag => customTag;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Text(
        '${controller.label}:${controller.count.value}',
        textDirection: TextDirection.ltr,
      ),
    );
  }
}

class _OrderArgs {
  const _OrderArgs({required this.itemName, required this.quantity});

  final String itemName;
  final int quantity;
}

abstract class _PaymentGatewayService {
  String get gatewayId;
}

class _StripeGatewayController extends SintController
    implements _PaymentGatewayService {
  @override
  String get gatewayId => 'stripe';
}

class _WooGatewayController extends SintController
    implements _PaymentGatewayService {
  @override
  String get gatewayId => 'woo';
}

class _PaypalGatewayController extends SintController
    implements _PaymentGatewayService {
  @override
  String get gatewayId => 'paypal';
}

class _GuestGuardMiddleware extends SintMiddleware {
  _GuestGuardMiddleware({required this.isAuthenticated}) : super(priority: -100);

  final bool Function() isAuthenticated;
  final List<String?> visited = <String?>[];

  @override
  FutureOr<RouteDecoder?> redirectDelegate(RouteDecoder route) {
    final path = route.pageSettings?.name ?? route.route?.name;
    visited.add(path);
    if (!isAuthenticated() && path == '/secret') {
      return RouteDecoder.fromRoute('/login');
    }
    return route;
  }
}

const _orderRoute = SintRoute<_OrderArgs, String>('/orders/:orderId');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Sint.reset);

  group('Pillar S — ValueListenable interop, Zero-Stream Workers, SintStatus/RxFuture & SintView', () {
    testWidgets('Rx and Computed work natively inside Flutter ValueListenableBuilder',
        (tester) async {
      final c = _CounterController();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              ValueListenableBuilder<int>(
                valueListenable: c.count,
                builder: (_, val, _) => Text('rx:$val'),
              ),
              ValueListenableBuilder<int>(
                valueListenable: c.doubled,
                builder: (_, val, _) => Text('comp:$val'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('rx:0'), findsOneWidget);
      expect(find.text('comp:0'), findsOneWidget);

      c.count.value = 7;
      await tester.pump();

      expect(find.text('rx:7'), findsOneWidget);
      expect(find.text('comp:14'), findsOneWidget);
      c.onDelete();
    });

    testWidgets('External ValueNotifier.rxValue works inside Obx and Computed without leaks',
        (tester) async {
      final externalNotifier = ValueNotifier<int>(3);
      final showExternal = true.obs;
      final derived = Sint.computed(() => externalNotifier.rxValue * 10);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Obx(() {
            if (!showExternal.value) return const Text('hidden');
            // Read twice in the same pass to verify listener deduplication.
            final sum = externalNotifier.rxValue + externalNotifier.rxValue;
            return Text('sum:$sum|derived:${derived.value}');
          }),
        ),
      );

      expect(find.text('sum:6|derived:30'), findsOneWidget);

      externalNotifier.value = 5;
      await tester.pump();
      expect(find.text('sum:10|derived:50'), findsOneWidget);

      // Turn off conditional branch: Obx should detach from externalNotifier.
      showExternal.value = false;
      await tester.pump();
      expect(find.text('hidden'), findsOneWidget);

      final mirrored = externalNotifier.toRx();
      expect(mirrored.value, 5);
      externalNotifier.value = 9;
      expect(mirrored.value, 9);

      mirrored.close();
      derived.dispose();
      showExternal.close();
      externalNotifier.dispose();
    });

    test('ever and once fire synchronously and coalesce inside Sint.batch', () {
      final c = _CounterController();
      final events = <int>[];
      final onceEvents = <int>[];

      c.ever<int>(c.count, events.add);
      c.once<int>(c.count, onceEvents.add);

      Sint.batch(() {
        c.count.value = 1;
        c.count.value = 2;
        c.count.value = 3;
      });

      // Synchronous delivery without awaiting microtasks, coalesced to final value 3!
      expect(events, [3]);
      expect(onceEvents, [3]);

      c.count.value = 4;
      expect(events, [3, 4]);
      expect(onceEvents, [3]);
      c.onDelete();
    });

    test('sealed SintStatus supports exhaustive switch and stale-while-revalidate RxFuture', () async {
      String describe(SintStatus<String> status) => switch (status) {
            LoadingStatus(:final previousData) =>
              previousData != null ? 'refreshing:$previousData' : 'loading',
            SuccessStatus(:final data) => 'ok:$data',
            ErrorStatus<String, Object?>(:final error, :final previousData) =>
              'err:$error(prev:$previousData)',
            ErrorStatus<Object?, Object?>(:final error) => 'err:$error',
            EmptyStatus() => 'empty',
            CustomStatus() => 'custom',
          };

      expect(describe(SintStatus.loading()), 'loading');
      expect(describe(SintStatus.refreshing('v1')), 'refreshing:v1');
      expect(SintStatus.refreshing('v1').isRefreshing, isTrue);
      expect(SintStatus.refreshing('v1').dataOrNull, 'v1');
      expect(SintStatus<String>.loading().isRefreshing, isFalse);
      expect(SintStatus<String>.loading().dataOrNull, isNull);

      var attempt = 0;
      final rxFut = RxFuture<String>.idle(() async {
        attempt++;
        if (attempt == 2) throw StateError('network');
        return 'payload_$attempt';
      });

      expect(rxFut.value.isEmpty, isTrue);
      await rxFut.reload();
      expect(describe(rxFut.value), 'ok:payload_1');

      // Revalidate retains previousData on error and during loading!
      final revalidateFuture = rxFut.revalidate();
      expect(rxFut.value.isRefreshing, isTrue);
      expect(rxFut.value.dataOrNull, 'payload_1');
      await revalidateFuture;
      expect(rxFut.value.isError, isTrue);
      expect(rxFut.value.dataOrNull, 'payload_1');

      // Guard helper
      final guarded = await RxFuture.guard<int>(() async => 42);
      expect(guarded, SintStatus<int>.success(42));
      rxFut.close();
    });

    test('RxFuture discards stale out-of-order responses', () {
      fakeAsync((async) {
        final slow = Completer<String>();
        final fast = Completer<String>();
        var call = 0;

        final futureRx = RxFuture<String>(() {
          call++;
          return call == 1 ? slow.future : fast.future;
        });

        // Trigger a second reload before the first completes.
        futureRx.reload();
        fast.complete('newest');
        async.flushMicrotasks();
        expect(futureRx.value, SintStatus<String>.success('newest'));

        // Now complete the older request — must NOT overwrite 'newest'.
        slow.complete('stale');
        async.flushMicrotasks();
        expect(futureRx.value, SintStatus<String>.success('newest'));
        futureRx.close();
      });
    });

    testWidgets('SintView resolves default and tagged controllers', (tester) async {
      Sint.put(_CounterController('main'));
      Sint.put(_CounterController('tagged')..count.value = 99, tag: 'special');

      await tester.pumpWidget(
        const Column(
          children: [
            _CounterView(),
            _CounterView(customTag: 'special'),
          ],
        ),
      );

      expect(find.text('main:0'), findsOneWidget);
      expect(find.text('tagged:99'), findsOneWidget);
    });
  });

  group('Pillar I — SintService, GetX 4 Bindings/BindingsBuilder, SintScope & Legacy Aliases', () {
    test('SintService defaults to permanent: true across put and lazyPut', () {
      Sint.put(_SessionService());
      Sint.put(_CounterController());

      Sint.deleteAll(force: false);

      expect(Sint.isRegistered<_SessionService>(), isTrue);
      expect(Sint.find<_SessionService>().closed, isFalse);
      expect(Sint.isRegistered<_CounterController>(), isFalse);

      // Explicit permanent: false is respected.
      Sint.put(_SessionService(), tag: 'temp', permanent: false);
      expect(Sint.delete<_SessionService>(tag: 'temp'), isTrue);
    });

    testWidgets('Bindings and BindingsBuilder work with initialBinding and SintPage',
        (tester) async {
      await tester.pumpWidget(
        SintMaterialApp(
          initialBinding: _GetxStyleBinding(),
          initialRoute: '/start',
          sintPages: [
            SintPage(
              name: '/start',
              page: () => const _CounterView(),
            ),
            SintPage(
              name: '/inline',
              binding: BindingsBuilder(() {
                Sint.lazyPut<_CounterController>(
                  () => _CounterController('inline')..count.value = 5,
                  tag: 'inline_tag',
                );
              }),
              page: () => const _CounterView(customTag: 'inline_tag'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('from_bindings:0'), findsOneWidget);

      Sint.toNamed('/inline');
      await tester.pumpAndSettle();
      expect(find.text('inline:5'), findsOneWidget);
    });

    testWidgets('SintScope overrides dependencies cleanly and disposes on unmount',
        (tester) async {
      final globalCtrl = Sint.put(_CounterController('global'));
      late _CounterController scopedCtrl;

      await tester.pumpWidget(
        SintScope(
          overrides: [
            SintOverride.lazy<_CounterController>(() {
              scopedCtrl = _CounterController('scoped')..count.value = 42;
              return scopedCtrl;
            }),
          ],
          child: const _CounterView(),
        ),
      );

      expect(find.text('scoped:42'), findsOneWidget);
      expect(scopedCtrl.wasClosed, isFalse);
      expect(globalCtrl.wasClosed, isFalse);

      // Unmount SintScope -> scoped controller closes, global stays untouched!
      await tester.pumpWidget(const SizedBox.shrink());
      expect(scopedCtrl.wasClosed, isTrue);
      expect(Sint.find<_CounterController>().label, 'global');
    });

    test('SintScope.run works in headless unit tests and legacy aliases compile', () async {
      Sint.put(_CounterController('prod'));

      final scopedLabel = await SintScope.run<String>(
        overrides: [
          SintOverride.value<_CounterController>(_CounterController('mock')),
        ],
        body: () async {
          await Future<void>.delayed(Duration.zero);
          return Sint.find<_CounterController>().label;
        },
      );

      expect(scopedLabel, 'mock');
      expect(Sint.findOrNull<_CounterController>()?.label, 'prod');
      expect(Sint.findOrNull<_SessionService>(), isNull);

      // Verify deprecated GetX migration typedefs resolve cleanly:
      // ignore: deprecated_member_use_from_same_package
      expect(_SessionService(), isA<GetxService>());
      // ignore: deprecated_member_use_from_same_package
      expect(const _CounterView(), isA<GetView<_CounterController>>());
    });

    test(
        'Bind.contract & aliases support Service-first default, ID/tag, and registration order',
        () async {
      // 1) Multi-implementation Service contract (external modules only use _PaymentGatewayService):
      Bind.contract<_PaymentGatewayService, _StripeGatewayController>(
        () => _StripeGatewayController(),
        tag: 'stripe',
        fenix: true,
      );
      Bind.contract<_PaymentGatewayService, _WooGatewayController>(
        () => _WooGatewayController(),
        tag: 'woo',
        fenix: true,
      );
      Bind.contract<_PaymentGatewayService, _PaypalGatewayController>(
        () => _PaypalGatewayController(),
        tag: 'paypal',
        isDefault: true, // overrides untagged default while keeping insertion order
        fenix: true,
      );

      // Default resolution (isDefault: true -> paypal; without isDefault -> 1st registered)
      expect(Sint.find<_PaymentGatewayService>().gatewayId, 'paypal');

      // Resolution by ID/tag using ONLY the core Service interface:
      expect(Sint.find<_PaymentGatewayService>(tag: 'stripe').gatewayId, 'stripe');
      expect(Sint.find<_PaymentGatewayService>(tag: 'woo').gatewayId, 'woo');

      // Resolution by registration order using ONLY the core Service interface:
      expect(Sint.findAt<_PaymentGatewayService>(0).gatewayId, 'stripe');
      expect(Sint.findAt<_PaymentGatewayService>(1).gatewayId, 'woo');
      expect(Sint.findAt<_PaymentGatewayService>(2).gatewayId, 'paypal');
      expect(
        Sint.findAll<_PaymentGatewayService>().map((g) => g.gatewayId).toList(),
        ['stripe', 'woo', 'paypal'],
      );

      // Intra-module resolution inside the owning package shares the exact singleton:
      expect(
        identical(
          Sint.find<_PaymentGatewayService>(tag: 'woo'),
          Sint.find<_WooGatewayController>(),
        ),
        isTrue,
      );

      // 2) Single-controller aliases on lazyPut cleans up all bound slots on delete:
      Sint.reset();
      Bind.lazyPut<_PaymentGatewayService>(
        () => _StripeGatewayController(),
        aliases: [_StripeGatewayController],
      );
      final viaService = Sint.find<_PaymentGatewayService>();
      final viaController = Sint.find<_StripeGatewayController>();
      expect(identical(viaService, viaController), isTrue);

      await Bind.delete<_PaymentGatewayService>();
      expect(Sint.isRegistered<_PaymentGatewayService>(), isFalse);
      expect(Sint.isRegistered<_StripeGatewayController>(), isFalse);
    });
  });

  group('Pillar N — SintRoute<TArgs, TResult> & SintTestMode query params', () {
    testWidgets('SintRoute navigates with typed args, path/query params and typed result',
        (tester) async {
      String? capturedOrderId;
      String? capturedTab;
      _OrderArgs? capturedArgs;

      await tester.pumpWidget(
        SintMaterialApp(
          initialRoute: '/',
          sintPages: [
            SintPage(
              name: '/',
              page: () => const SizedBox.shrink(),
            ),
            _orderRoute.page(
              page: () {
                capturedOrderId = Sint.pathParam('orderId');
                capturedTab = Sint.queryParam('tab');
                capturedArgs = _orderRoute.argsOrNull;
                return GestureDetector(
                  onTap: () => Sint.back(result: 'confirmed_${capturedArgs?.quantity}'),
                  child: const Text('confirm_order'),
                );
              },
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final resultFuture = _orderRoute.to(
        pathParams: {'orderId': 'ORD-99'},
        queryParams: {'tab': 'summary'},
        arguments: const _OrderArgs(itemName: 'Synth', quantity: 3),
      );
      await tester.pumpAndSettle();

      expect(capturedOrderId, 'ORD-99');
      expect(capturedTab, 'summary');
      expect(capturedArgs?.itemName, 'Synth');

      await tester.tap(find.text('confirm_order'));
      await tester.pumpAndSettle();

      expect(await resultFuture, 'confirmed_3');
    });

    test('SintTestMode supports queryParam, queryParams and resets via Sint.reset', () {
      Sint.testMode = true;
      SintTestMode.setTestParameters({'bookId': 'b-10'});
      SintTestMode.setTestQueryParameters({'sort': 'asc', 'page': '2'});

      expect(Sint.pathParam('bookId'), 'b-10');
      expect(Sint.queryParam('sort'), 'asc');
      expect(Sint.queryParamOrDefault('missing', 'fallback'), 'fallback');
      expect(Sint.queryParams, {'sort': 'asc', 'page': '2'});

      Sint.reset();
      expect(Sint.testMode, isFalse);
      expect(SintTestMode.queryParam('sort'), isNull);
    });

    testWidgets(
        'globalMiddlewares intercepts routes across modules without cloning SintPage',
        (tester) async {
      var loggedIn = false;
      final guard = _GuestGuardMiddleware(isAuthenticated: () => loggedIn);

      await tester.pumpWidget(
        SintMaterialApp(
          initialRoute: '/home',
          globalMiddlewares: [guard],
          sintPages: [
            SintPage(
              name: '/home',
              page: () => const Text('home_page'),
            ),
            SintPage(
              name: '/login',
              page: () => const Text('login_page'),
            ),
            SintPage(
              name: '/secret',
              page: () => const Text('secret_page'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('home_page'), findsOneWidget);

      // Unauthenticated navigation to /secret redirects to /login via globalMiddlewares:
      Sint.toNamed('/secret');
      await tester.pumpAndSettle();
      expect(find.text('login_page'), findsOneWidget);

      // Once authenticated, /secret opens directly:
      loggedIn = true;
      Sint.toNamed('/secret');
      await tester.pumpAndSettle();
      expect(find.text('secret_page'), findsOneWidget);
      expect(guard.visited, containsAll(['/home', '/secret', '/login']));
    });
  });

  group('Pillar T — O(1) Locale Cache, Single-Pass trParams & Lazy Translations', () {
    test('Language-only Locale resolves regional maps and direct map mutations invalidate cache', () {
      Sint.locale = const Locale('es');
      Sint.fallbackLocale = const Locale('en', 'US');
      Sint.addTranslations({
        'es_MX': {'greeting': 'Hola MX'},
        'en_US': {'only_en': 'Fallback EN'},
      });

      expect('greeting'.tr, 'Hola MX');
      expect('only_en'.tr, 'Fallback EN');

      // Direct mutation on Sint.translations must immediately reflect without stale cache.
      Sint.translations['es'] = {'greeting': 'Hola Neutro'};
      expect('greeting'.tr, 'Hola Neutro');

      final missing = <String>[];
      Sint.onMissingTranslationKey = (key, _) => missing.add(key);
      expect('unknown_key'.tr, 'unknown_key');
      expect(missing, ['unknown_key']);
    });

    test('Single-pass trParams prevents @param value collisions and supports plurals', () {
      Sint.locale = const Locale('en', 'US');
      Sint.addTranslations({
        'en_US': {
          'pair': '@first -> @second',
          'items': '%s item',
          'items_zero': 'No items',
          'items_other': '%s items',
        },
      });

      // With sequential replaceAll, '@first' -> '@second' would get overwritten by second!
      final interpolated = 'pair'.trParams({
        'first': '@second',
        'second': 'REAL_SECOND',
      });
      expect(interpolated, '@second -> REAL_SECOND');

      expect('items'.trPlural(null, 0, ['0']), 'No items');
      expect('items'.trPlural(null, 1, ['1']), '1 item');
      expect('items'.trPlural(null, 5, ['5']), '5 items');
    });

    test('registerLazyTranslations loads locale bundle once on demand', () async {
      var loadCalls = 0;
      Sint.registerLazyTranslations('fr', () async {
        loadCalls++;
        return {'hello': 'Bonjour'};
      });

      expect(await Sint.ensureLocaleLoaded(const Locale('fr', 'FR')), isTrue);
      expect(await Sint.ensureLocaleLoaded(const Locale('fr', 'CA')), isFalse);
      expect(loadCalls, 1);

      Sint.locale = const Locale('fr', 'FR');
      expect('hello'.tr, 'Bonjour');
    });
  });
}
