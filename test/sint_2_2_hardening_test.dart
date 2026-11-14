import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

// ── Test Fixtures ────────────────────────────────────────────────────────────

class _HeadlessReadyController extends SintController {
  bool readyFired = false;

  @override
  void onReady() {
    super.onReady();
    readyFired = true;
  }
}

class _CycleA {
  _CycleA() {
    Sint.find<_CycleB>();
  }
}

class _CycleB {
  _CycleB() {
    Sint.find<_CycleA>();
  }
}

class _KeepFactoryController extends SintController {
  static int instancesCreated = 0;
  final int instanceNumber = ++instancesCreated;
  bool closed = false;

  @override
  void onClose() {
    closed = true;
    super.onClose();
  }
}

abstract interface class _AuthContract {
  String get label;
}

class _AuthImpl extends SintController implements _AuthContract {
  _AuthImpl(this.label);

  @override
  final String label;
  bool closed = false;

  @override
  void onClose() {
    closed = true;
    super.onClose();
  }
}

class _IdSwitchController extends SintController {
  int value = 0;

  void bumpAlpha() {
    value++;
    update(['alpha']);
  }

  void bumpBeta() {
    value++;
    update(['beta']);
  }
}

class _EverAllController extends SintController {
  _EverAllController(this.a, this.b);

  final RxInt a;
  final RxString b;
  final List<Object?> events = <Object?>[];

  @override
  void onInit() {
    super.onInit();
    everAll([a, b], (val) => events.add(val));
  }
}

class _MutableBox {
  _MutableBox(this.count);
  int count;
}

class _CancelRouteMiddleware extends SintMiddleware {
  @override
  Future<RouteDecoder?> redirectDelegate(RouteDecoder route) async => null;
}

class _RedirectToUnknownMiddleware extends SintMiddleware {
  @override
  Future<RouteDecoder?> redirectDelegate(RouteDecoder route) async {
    return RouteDecoder.fromRoute('/unregistered-404');
  }
}

class _OrderBinding implements BindingsInterface<void> {
  _OrderBinding(this.name, this.log);
  final String name;
  final List<String> log;

  @override
  void dependencies() {
    log.add(name);
  }
}

class _ConstTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => const {
        'en_US': {
          'hello': 'Hello',
          'audit': 'Admin @admin / Email @admin_email / Handle @user-name',
        },
      };
}

void main() {
  tearDown(() {
    _KeepFactoryController.instancesCreated = 0;
    Sint.smartManagement = SmartManagement.full;
    Sint.reset();
  });

  group('SINT 2.2 — Idle Frame & WidgetBinding Lifecycle', () {
    testWidgets(
      'SintController.onReady fires on next pump even when registered while SchedulerPhase is idle',
      (tester) async {
        final ctrl = Sint.put(_HeadlessReadyController());
        expect(ctrl.initialized, isTrue);
        expect(ctrl.readyFired, isFalse);

        await tester.pump();
        expect(ctrl.readyFired, isTrue);
      },
    );
  });

  group('SINT 2.2 — Pillar I (Injection, Scopes, SmartManagement & Binds)', () {
    test('detects circular dependencies with StateError and recovers cleanly',
        () {
      Sint.lazyPut<_CycleA>(() => _CycleA());
      Sint.lazyPut<_CycleB>(() => _CycleB());

      expect(
        () => Sint.find<_CycleA>(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Circular dependency detected'),
          ),
        ),
      );

      // Registry state is clean after unwinding; replacing breaks the cycle.
      Sint.reset();
      Sint.put<String>('recovered');
      expect(Sint.find<String>(), 'recovered');
    });

    test(
      'SmartManagement.keepFactory disposes instance on delete while preserving lazy factory',
      () {
        Sint.smartManagement = SmartManagement.keepFactory;
        Sint.lazyPut<_KeepFactoryController>(() => _KeepFactoryController());

        final first = Sint.find<_KeepFactoryController>();
        expect(first.instanceNumber, 1);
        expect(first.closed, isFalse);

        final deleted = Sint.delete<_KeepFactoryController>();
        expect(deleted, isTrue);
        expect(first.closed, isTrue);
        expect(Sint.isRegistered<_KeepFactoryController>(), isTrue);
        expect(Sint.isPrepared<_KeepFactoryController>(), isTrue);

        final second = Sint.find<_KeepFactoryController>();
        expect(second.instanceNumber, 2);
        expect(identical(first, second), isFalse);
      },
    );

    testWidgets(
      'Bind.put and Bind.contract survive unmount/remount and support Bind.of<Contract>(context)',
      (tester) async {
        final showSubtree = true.obs;
        final contractBind = Bind.contract<_AuthContract, _AuthImpl>(
          () => _AuthImpl('open-neom'),
        );
        final valueBind = Bind.put<RxInt>(RxInt(42));

        _AuthContract? resolvedContract;
        RxInt? resolvedRx;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Obx(() {
              if (!showSubtree.value) return const SizedBox.shrink();
              return MultiBinder(
                binds: [contractBind, valueBind],
                child: Builder(
                  builder: (context) {
                    resolvedContract = Bind.of<_AuthContract>(context);
                    resolvedRx = Bind.of<RxInt>(context);
                    return Text('${resolvedContract?.label}:${resolvedRx?.value}');
                  },
                ),
              );
            }),
          ),
        );

        expect(find.text('open-neom:42'), findsOneWidget);
        final firstImpl = Sint.find<_AuthImpl>();
        expect(firstImpl.closed, isFalse);

        // Unmount disposes the owned instance.
        showSubtree.value = false;
        await tester.pump();
        expect(firstImpl.closed, isTrue);
        expect(Sint.isRegistered<_AuthContract>(), isFalse);

        // Remounting the same Bind instances re-registers cleanly without BindError.
        showSubtree.value = true;
        await tester.pump();
        expect(find.text('open-neom:42'), findsOneWidget);
        final secondImpl = Sint.find<_AuthImpl>();
        expect(identical(firstImpl, secondImpl), isFalse);
        expect(secondImpl.closed, isFalse);
      },
    );

    testWidgets(
      'Bind.of<T>(context) resolves nearest ancestor across nested Binder and MultiBinder',
      (tester) async {
        String? innerValue;
        String? innermostValue;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Binder<String>(
              init: () => 'outer-local-0',
              global: false,
              child: MultiBinder(
                binds: [
                  Bind.create<String>((_) => 'innermost-local-1'),
                ],
                child: Builder(
                  builder: (deepCtx) {
                    innermostValue = Bind.of<String>(deepCtx);
                    return Binder<String>(
                      init: () => 'leaf-local-2',
                      global: false,
                      child: Builder(
                        builder: (leafCtx) {
                          innerValue = Bind.of<String>(leafCtx);
                          return const SizedBox.shrink();
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        expect(innermostValue, 'innermost-local-1');
        expect(innerValue, 'leaf-local-2');
      },
    );

    testWidgets(
      'SintBuilder dynamically switches group id and passes accurate oldWidget to didUpdateWidget',
      (tester) async {
        final ctrl = Sint.put(_IdSwitchController());
        final activeId = 'alpha'.obs;
        Object? capturedOldId;
        Object? capturedNewId;
        var builderRuns = 0;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Obx(
              () => SintBuilder<_IdSwitchController>(
                id: activeId.value,
                didUpdateWidget: (oldWidget, state) {
                  capturedOldId = oldWidget.id;
                  capturedNewId = state.widget.id;
                },
                builder: (c) {
                  builderRuns++;
                  return Text('v=${c.value}');
                },
              ),
            ),
          ),
        );

        expect(find.text('v=0'), findsOneWidget);
        expect(builderRuns, 1);

        ctrl.bumpAlpha();
        await tester.pump();
        expect(find.text('v=1'), findsOneWidget);

        // Switch id from 'alpha' to 'beta'.
        activeId.value = 'beta';
        await tester.pump();
        expect(capturedOldId, 'alpha');
        expect(capturedNewId, 'beta');

        final runsAfterSwitch = builderRuns;
        // 'alpha' updates must no longer rebuild this SintBuilder.
        ctrl.bumpAlpha();
        await tester.pump();
        expect(builderRuns, runsAfterSwitch);

        // 'beta' updates MUST rebuild this SintBuilder.
        ctrl.bumpBeta();
        await tester.pump();
        expect(find.text('v=3'), findsOneWidget);
        expect(builderRuns, runsAfterSwitch + 1);
      },
    );

    testWidgets(
      'Side-by-side sibling SintScopes isolate Bind.lazyPut resolution inside Binder',
      (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                SintScope(
                  overrides: [SintOverride.value<String>('left-scope')],
                  child: Binder<_AuthImpl>(
                    init: () => _AuthImpl(Sint.find<String>()),
                    global: false,
                    child: Builder(
                      builder: (ctx) => Text(Bind.of<_AuthImpl>(ctx).label),
                    ),
                  ),
                ),
                SintScope(
                  overrides: [SintOverride.value<String>('right-scope')],
                  child: Binder<_AuthImpl>(
                    init: () => _AuthImpl(Sint.find<String>()),
                    global: false,
                    child: Builder(
                      builder: (ctx) => Text(Bind.of<_AuthImpl>(ctx).label),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        expect(find.text('left-scope'), findsOneWidget);
        expect(find.text('right-scope'), findsOneWidget);
      },
    );
  });

  group('SINT 2.2 — Pillar S (Glitch-Free & Lazy Computed, Workers, Rx & Queue)',
      () {
    test(
      'Diamond Computed graph is glitch-free outside Sint.batch and skips downstream when middle nodes memoize',
      () {
        final a = 1.obs;
        var dRuns = 0;
        final seenPairs = <(int, int)>[];

        final b = Sint.computed(() => a.value * 2);
        final c = Sint.computed(() => a.value * 10);
        final d = Sint.computed(() {
          dRuns++;
          final pair = (b.value, c.value);
          seenPairs.add(pair);
          return pair.$1 + pair.$2;
        });

        expect(d.value, 12);
        expect(dRuns, 1);
        expect(seenPairs, [(2, 10)]);

        // Mutate `a` OUTSIDE `Sint.batch`: `d` must evaluate ONCE with (4, 20),
        // never observing intermediate glitch (4, 10) or (2, 20).
        a.value = 2;
        expect(d.value, 24);
        expect(dRuns, 2);
        expect(seenPairs, [(2, 10), (4, 20)]);

        // Parity diamond where middle nodes memoize equal booleans:
        final n = 2.obs;
        var paritySinkRuns = 0;
        final isEven = Sint.computed(() => n.value.isEven);
        final modTwoZero = Sint.computed(() => n.value % 2 == 0);
        final bothEven = Sint.computed(() {
          paritySinkRuns++;
          return isEven.value && modTwoZero.value;
        });

        expect(bothEven.value, isTrue);
        expect(paritySinkRuns, 1);

        // 2 -> 4: both middle nodes recompute to `true` (unchanged), so
        // `bothEven` transitions check -> clean with ZERO recomputations!
        n.value = 4;
        expect(bothEven.value, isTrue);
        expect(paritySinkRuns, 1);

        d.dispose();
        c.dispose();
        b.dispose();
        bothEven.dispose();
        modTwoZero.dispose();
        isEven.dispose();
      },
    );

    testWidgets(
      'Sint.computed(lazy: true) defers unobserved evaluations and settles automatically when observed by Obx',
      (tester) async {
        final count = 1.obs;
        var runs = 0;
        final expensive = Sint.computed(
          () {
            runs++;
            return count.value * 100;
          },
          lazy: true,
        );

        expect(runs, 1);
        expect(expensive.peek, 100);

        // Unobserved mutations mark dirty in O(1) with 0 evaluations.
        count.value = 2;
        count.value = 3;
        count.value = 4;
        expect(runs, 1);

        // Reading `.value` evaluates once on demand.
        expect(expensive.value, 400);
        expect(runs, 2);

        // Mounting an Obx attaches an eager listener so updates propagate live.
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Obx(() => Text('val=${expensive.value}')),
          ),
        );
        expect(find.text('val=400'), findsOneWidget);

        count.value = 7;
        await tester.pump();
        expect(find.text('val=700'), findsOneWidget);

        expensive.dispose();
      },
    );

    test('SintController.everAll listens synchronously without Streams and cleans up onClose',
        () {
      final a = 0.obs;
      final b = 'init'.obs;
      final ctrl = _EverAllController(a, b)..onStart();

      a.value = 1;
      b.value = 'next';
      expect(ctrl.events, [1, 'next']);

      ctrl.onDelete();
      expect(a.listenersLength, 0);
      expect(b.listenersLength, 0);

      a.value = 2;
      expect(ctrl.events, [1, 'next']);
    });

    test('RxFuture and ErrorStatus preserve stackTrace and expose stackTraceOrNull',
        () async {
      final resource = RxFuture<int>(() async {
        throw ArgumentError('bad input');
      });

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(resource.value.isError, isTrue);
      expect(resource.value.errorOrNull.toString(), contains('bad input'));
      expect(resource.value.stackTraceOrNull, isNotNull);
      expect(
        (resource.value as ErrorStatus<int, Object?>).stackTrace.toString(),
        contains('sint_2_2_hardening_test.dart'),
      );
      resource.close();
    });

    test(
      'Rx.trigger fires on first call with initial value, Rx.update notifies in-place, and RxBool/RxInt/RxnBool avoid tracking leaks',
      () async {
        final rxInt = 10.obs;
        final syncTriggered = <int>[];
        final streamTriggered = <int>[];
        rxInt.addListener(() => syncTriggered.add(rxInt.peek));
        final sub = rxInt.listen(streamTriggered.add);

        // First trigger with the same initial value MUST notify both sync and stream listeners.
        rxInt.trigger(10);
        rxInt.trigger(10);
        expect(syncTriggered, [10, 10]);
        await Future<void>.delayed(Duration.zero);
        expect(streamTriggered, [10, 10]);
        await sub.cancel();

        // Assigning equal value skips spurious notification (`trigger` forces it).
        final rxSame = 5.obs;
        var sameNotifies = 0;
        rxSame.addListener(() => sameNotifies++);
        rxSame.value = 5;
        expect(sameNotifies, 0);

        // In-place update on identical mutable reference notifies listeners.
        final box = _MutableBox(1).obs;
        var boxNotifies = 0;
        box.addListener(() => boxNotifies++);
        box.update((val) {
          val!.count = 99;
          return val;
        });
        expect(box.value.count, 99);
        expect(boxNotifies, 1);

        // RxBool.toggle and RxInt.+ inside Computed do NOT subscribe to self.
        final flag = false.obs;
        final counter = 1.obs;
        final driver = 0.obs;
        var sideEffectRuns = 0;
        final watcher = Sint.computed(() {
          sideEffectRuns++;
          final d = driver.value;
          if (d > 0) {
            flag.toggle();
            counter + 5;
            return '$d:${counter.peek}';
          }
          return '0';
        });
        expect(watcher.value, '0');
        driver.value = 1;
        expect(watcher.value, '1:6');
        final runsAfterDriver = sideEffectRuns;

        // Mutating `flag` or `counter` must NOT re-trigger `watcher` because
        // `toggle()` and `operator +` used untracked `peek`.
        flag.value = false;
        counter.value = 50;
        expect(sideEffectRuns, runsAfterDriver);
        watcher.dispose();

        // RxnBool.operator ^ handles null value safely without TypeError.
        final nullableBool = RxnBool();
        expect(nullableBool ^ true, isNull);
        nullableBool.value = true;
        expect(nullableBool ^ true, isFalse);
      },
    );

    test(
      'RxList/RxSet self-addAll avoid ConcurrentModificationError and RxMap coalesces bulk mutations',
      () {
        final list = <int>[1, 2].obs;
        list.addAll(list);
        expect(list, [1, 2, 1, 2]);

        final set = <int>{1, 2}.obs;
        set.addAll(set);
        expect(set, {1, 2});

        final map = <String, int>{'a': 1, 'b': 2}.obs;
        var mapNotifies = 0;
        map.addListener(() => mapNotifies++);

        map.update('a', (v) => v + 10);
        expect(mapNotifies, 1);

        map.updateAll((k, v) => v * 2);
        expect(mapNotifies, 2);
        expect(map, {'a': 22, 'b': 4});

        map.addEntries(const [MapEntry('c', 3), MapEntry('d', 4)]);
        expect(mapNotifies, 3);
      },
    );

    test('SintQueue drains 500 sequential microtasks iteratively in FIFO order',
        () async {
      final queue = SintQueue();
      final order = <int>[];
      final futures = <Future<int>>[
        for (var i = 0; i < 500; i++)
          queue.add<int>(() {
            order.add(i);
            return i;
          }),
      ];

      final results = await Future.wait(futures);
      expect(results.length, 500);
      expect(order.first, 0);
      expect(order.last, 499);
    });
  });

  group('SINT 2.2 — Pillar N (Router 2.0 Middlewares, Params, Outlets & Overlays)',
      () {
    testWidgets(
      'offNamed middleware cancellation preserves active stack and redirect to unknown route renders unknownRoute',
      (tester) async {
        await tester.pumpWidget(
          SintMaterialApp.router(
            routeInformationParser:
                SintInformationParser(initialRoute: '/home'),
            unknownRoute: SintPage(
              name: '/404',
              page: () => const Text('CUSTOM_404'),
            ),
            sintPages: [
              SintPage(name: '/home', page: () => const Text('HOME_PAGE')),
              SintPage(
                name: '/blocked',
                page: () => const Text('BLOCKED_PAGE'),
                middlewares: [_CancelRouteMiddleware()],
              ),
              SintPage(
                name: '/broken-redirect',
                page: () => const Text('BROKEN_REDIRECT'),
                middlewares: [_RedirectToUnknownMiddleware()],
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('HOME_PAGE'), findsOneWidget);

        // Cancelled `offNamed` must NOT pop `/home` or leave an empty stack.
        await Sint.rootController.rootDelegate.offNamed('/blocked');
        await tester.pumpAndSettle();
        expect(find.text('HOME_PAGE'), findsOneWidget);
        expect(find.text('BLOCKED_PAGE'), findsNothing);

        // Redirecting to an unregistered route renders `unknownRoute` cleanly.
        unawaited(
          Sint.rootController.rootDelegate.toNamed('/broken-redirect'),
        );
        await tester.pumpAndSettle();
        expect(find.text('CUSTOM_404'), findsOneWidget);
      },
    );

    testWidgets(
      'pathParam and routeParam cannot be shadowed by query parameters and survive refreshRoutes',
      (tester) async {
        final pages = [
          SintPage(
            name: '/users/:id',
            page: () => Builder(
              builder: (_) => Text(
                'path=${Sint.rootController.rootDelegate.pathParam('id')}|'
                'route=${Sint.rootController.rootDelegate.routeParam}|'
                'tab=${Sint.rootController.rootDelegate.parameters['tab']}|'
                'mergedId=${Sint.rootController.rootDelegate.parameters['id']}',
              ),
            ),
          ),
        ];

        await tester.pumpWidget(
          SintMaterialApp.router(
            routeInformationParser: SintInformationParser(
              initialRoute: '/users/real-42?id=spoofed&tab=security',
            ),
            sintPages: pages,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('path=real-42|route=real-42|tab=security|mergedId=real-42'),
          findsOneWidget,
        );

        // Hot-reload `refreshRoutes(pages)` preserves query parameters and path priority.
        Sint.rootController.rootDelegate.refreshRoutes(pages);
        await tester.pumpAndSettle();
        expect(
          find.text('path=real-42|route=real-42|tab=security|mergedId=real-42'),
          findsOneWidget,
        );
      },
    );

    test(
      'RouteParser matches multi-segment :path+ parameters and orders parent bindings before child bindings',
      () {
        final order = <String>[];
        final parser = RouteParser(
          routes: [
            SintPage(
              name: '/docs',
              page: () => const SizedBox.shrink(),
              binding: _OrderBinding('parent-single', order),
              bindings: [_OrderBinding('parent-list', order)],
              children: [
                SintPage(
                  name: '/:slug+',
                  page: () => const SizedBox.shrink(),
                  binding: _OrderBinding('child-single', order),
                  bindings: [_OrderBinding('child-list', order)],
                ),
              ],
            ),
          ],
        );

        final settings = PageSettings(
          Uri.parse('/docs/guides/v2/getting-started'),
        );
        final match = parser.matchRoute(
          '/docs/guides/v2/getting-started',
          arguments: settings,
        );
        expect(match.route, isNotNull);
        expect(match.pathParams['slug'], 'guides/v2/getting-started');
        expect(match.parameters['slug'], 'guides/v2/getting-started');

        for (final b in match.route!.bindings) {
          b.dependencies();
        }
        match.route!.binding?.dependencies();
        expect(
          order,
          ['parent-list', 'parent-single', 'child-list', 'child-single'],
        );
      },
    );

    testWidgets(
      'IndexedRouteBuilder matches segment boundaries and longest prefix without "/" hijacking sibling tabs',
      (tester) async {
        var currentIndex = -1;
        await tester.pumpWidget(
          SintMaterialApp.router(
            routeInformationParser:
                SintInformationParser(initialRoute: '/homework'),
            sintPages: [
              SintPage(
                name: '/',
                participatesInRootNavigator: true,
                page: () => IndexedRouteBuilder<List<String>>(
                  routes: const ['/', '/home', '/homework'],
                  builder: (context, routes, index) {
                    currentIndex = index;
                    return Text('tab=$index');
                  },
                ),
                children: [
                  SintPage(name: '/home', page: () => const SizedBox.shrink()),
                  SintPage(
                    name: '/homework',
                    page: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(currentIndex, 2);

        unawaited(Sint.rootController.rootDelegate.toNamed('/home'));
        await tester.pumpAndSettle();
        expect(currentIndex, 1);

        unawaited(Sint.rootController.rootDelegate.toNamed('/'));
        await tester.pumpAndSettle();
        expect(currentIndex, 0);
      },
    );

    test('SintRoute.uri builds typed Uri and SintApp honors custom transitionDuration',
        () {
      const orderRoute = SintRoute<String, bool>('/orders/:id');
      final uri = orderRoute.uri(
        pathParams: {'id': 'ord_9'},
        queryParams: {'view': 'summary'},
      );
      expect(uri.path, '/orders/ord_9');
      expect(uri.queryParameters['view'], 'summary');
    });

    testWidgets(
      'Sint.showOverlay removes blocking overlay entries even when asyncFunction throws an Error',
      (tester) async {
        await tester.pumpWidget(
          SintMaterialApp(
            transitionDuration: const Duration(milliseconds: 123),
            home: const Scaffold(body: Text('BASE_SCREEN')),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          Sint.defaultTransitionDuration,
          const Duration(milliseconds: 123),
        );

        Object? caught;
        final overlayFuture = Sint.showOverlay<void>(
          asyncFunction: () async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            throw StateError('overlay boom');
          },
          loadingWidget: const Center(child: Text('LOADING_SPINNER')),
        ).catchError((Object e) {
          caught = e;
        });

        await tester.pump();
        expect(find.text('LOADING_SPINNER'), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 20));
        await overlayFuture;
        await tester.pumpAndSettle();

        expect(caught, isA<StateError>());
        // Loading overlay MUST be removed even though StateError (an Error, not Exception) was thrown.
        expect(find.text('LOADING_SPINNER'), findsNothing);
        expect(find.text('BASE_SCREEN'), findsOneWidget);
      },
    );
  });

  group('SINT 2.2 — Pillar T (Immutable Translations, Lazy Deduplication, trParams & PathTranslator)',
      () {
    test(
      'appendTranslations works after const Translations maps and fires a single notification',
      () {
        Sint.addTranslations(_ConstTranslations().keys);
        Sint.locale = const Locale('en', 'US');

        var reactiveReads = 0;
        final translated = Sint.computed(() {
          reactiveReads++;
          return '${'hello'.tr}|${'extra'.tr}';
        });
        expect(translated.value, 'Hello|extra');
        expect(reactiveReads, 1);

        // Must NOT throw UnsupportedError: Cannot modify unmodifiable map,
        // and must notify reactive `.tr` subscribers ONCE for the whole batch.
        Sint.appendTranslations(const {
          'en_US': {'extra': 'Extra Value', 'a': '1', 'b': '2'},
          'es_MX': {'hello': 'Hola'},
        });

        expect('hello'.tr, 'Hello');
        expect('extra'.tr, 'Extra Value');
        expect(translated.value, 'Hello|Extra Value');
        expect(reactiveReads, 2);
        translated.dispose();
      },
    );

    test('concurrent ensureLocaleLoaded calls deduplicate in-flight loader execution',
        () async {
      var loaderCalls = 0;
      Sint.registerLazyTranslations('fr', () async {
        loaderCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return {'greeting': 'Bonjour (fr)'};
      });

      await Future.wait([
        Sint.ensureLocaleLoaded(const Locale('fr', 'FR')),
        Sint.ensureLocaleLoaded(const Locale('fr', 'FR')),
        Sint.ensureLocaleLoaded(const Locale('fr', 'FR')),
      ]);

      expect(loaderCalls, 1);
      Sint.locale = const Locale('fr', 'FR');
      expect('greeting'.tr, 'Bonjour (fr)');
    });

    test(
      'trParams avoids prefix-corrupting longer @placeholders while still replacing hyphenated tokens',
      () {
        Sint.addTranslations(_ConstTranslations().keys);
        Sint.locale = const Locale('en', 'US');

        final rendered = 'audit'.trParams({
          'admin': 'root',
          'admin_email': 'ops@openneom.dev',
          'user-name': 'serzen',
        });

        expect(
          rendered,
          'Admin root / Email ops@openneom.dev / Handle serzen',
        );
      },
    );

    test(
      'PathTranslator prevents localized segment collisions from hijacking canonical routes and resets cleanly',
      () {
        Sint.pathTranslator = PathTranslator.build(
          translations: const {
            'fr': {
              'cat': 'chat',
              'chat': 'discussion',
            },
          },
          routeSegments: const {'cat', 'chat'},
        );
        Sint.locale = const Locale('fr', 'FR');
        Sint.fallbackLocale = const Locale('en', 'US');

        // Canonical `/chat/room-1` must NOT be rewritten to `/cat/room-1`!
        expect(
          Sint.pathTranslator!.canonicalizePath('/chat/room-1'),
          '/chat/room-1',
        );
        expect(
          Sint.pathTranslator!.canonicalizePath('/discussion/room-1'),
          '/chat/room-1',
        );

        Sint.reset();
        expect(Sint.locale, isNull);
        expect(Sint.fallbackLocale, isNull);
        expect(Sint.pathTranslator, isNull);
      },
    );
  });
}
