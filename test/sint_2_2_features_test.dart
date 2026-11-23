// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

// ── Test Fixtures ────────────────────────────────────────────────────────────

abstract class _GreetService {
  String greet();
}

class _RealGreetController extends SintController implements _GreetService {
  int closes = 0;

  @override
  String greet() => 'real';

  @override
  void onClose() {
    closes++;
    super.onClose();
  }
}

class _FakeGreetController extends SintController implements _GreetService {
  _FakeGreetController(this.label);

  final String label;
  int closes = 0;

  @override
  String greet() => label;

  @override
  void onClose() {
    closes++;
    super.onClose();
  }
}

class _PermanentInfraService extends SintService {
  int closes = 0;

  @override
  void onClose() {
    closes++;
    super.onClose();
  }
}

class _TransientController extends SintController {
  final count = 0.obs;
  int closes = 0;

  @override
  void onClose() {
    closes++;
    super.onClose();
  }
}

class _LocalDraft {
  _LocalDraft(this.id);
  final int id;
}

class _GreetSintView extends SintView<_GreetService> {
  const _GreetSintView();

  @override
  Widget build(BuildContext context) {
    return Text('view:${controller.greet()}');
  }
}

class _SyncAuthGuard extends SintMiddleware {
  _SyncAuthGuard(this.isAuthenticated);

  final bool Function() isAuthenticated;

  @override
  RouteSettings? redirect(String? route) {
    if (!isAuthenticated() && route != '/login') {
      return const RouteSettings(name: '/login');
    }
    return null;
  }
}

class _BlockingGuard extends SintMiddleware {
  @override
  RouteDecoder? redirectDelegate(RouteDecoder route) {
    if (route.pageSettings?.uri.path == '/blocked') {
      return null;
    }
    return route;
  }
}

class _DynamicBindingMiddleware extends SintMiddleware {
  @override
  List<R>? onBindingsStart<R>(List<R>? bindings) {
    if (bindings case final List<BindingsInterface> list) {
      list.add(BindingsBuilder.put(() => _LocalDraft(777)));
    }
    return bindings;
  }
}

class _ParentRouteBinding extends Binding {
  @override
  List<Bind> dependencies() => [
    Bind.put<_RealGreetController>(_RealGreetController()),
  ];
}

class _CountingValueNotifier extends ValueNotifier<int> {
  _CountingValueNotifier(super.value);

  int addCalls = 0;
  int removeCalls = 0;

  @override
  void addListener(VoidCallback listener) {
    addCalls++;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    removeCalls++;
    super.removeListener(listener);
  }
}

// 50 distinct dummy types to verify MultiBinder O(1) widget-tree depth:
class _S01 {}

class _S02 {}

class _S03 {}

class _S04 {}

class _S05 {}

class _S06 {}

class _S07 {}

class _S08 {}

class _S09 {}

class _S10 {}

class _S11 {}

class _S12 {}

class _S13 {}

class _S14 {}

class _S15 {}

class _S16 {}

class _S17 {}

class _S18 {}

class _S19 {}

class _S20 {}

void main() {
  setUp(() {
    Sint.reset();
    RouterReportManager.dispose();
    Sint.smartManagement = SmartManagement.full;
  });

  tearDown(() {
    Sint.reset();
    RouterReportManager.dispose();
  });

  group('SINT 2.2.0 — Pillar I: MultiBinder O(1) Depth & autoRemove Fixes', () {
    testWidgets(
      'Binds flattens 20+ registrations into a single MultiBinder Element (-95% depth) while preserving Bind.of',
      (tester) async {
        late BuildContext leafContext;
        late BuildContext outerContext;

        final c = _TransientController();
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (ctx) {
                outerContext = ctx;
                return Binds(
                  binds: [
                    Bind.put<_S01>(_S01()),
                    Bind.put<_S02>(_S02()),
                    Bind.put<_S03>(_S03()),
                    Bind.put<_S04>(_S04()),
                    Bind.put<_S05>(_S05()),
                    Bind.put<_S06>(_S06()),
                    Bind.put<_S07>(_S07()),
                    Bind.put<_S08>(_S08()),
                    Bind.put<_S09>(_S09()),
                    Bind.put<_S10>(_S10()),
                    Bind.lazyPut<_S11>(() => _S11()),
                    Bind.lazyPut<_S12>(() => _S12()),
                    Bind.lazyPut<_S13>(() => _S13()),
                    Bind.lazyPut<_S14>(() => _S14()),
                    Bind.lazyPut<_S15>(() => _S15()),
                    Bind.lazyPut<_S16>(() => _S16()),
                    Bind.lazyPut<_S17>(() => _S17()),
                    Bind.lazyPut<_S18>(() => _S18()),
                    Bind.lazyPut<_S19>(() => _S19()),
                    Bind.lazyPut<_S20>(() => _S20()),
                    Bind.put<_TransientController>(c),
                  ],
                  child: Builder(
                    builder: (inner) {
                      leafContext = inner;
                      final resolved = Bind.of<_TransientController>(
                        inner,
                        rebuild: true,
                      );
                      return Text('count:${resolved.count.value}');
                    },
                  ),
                );
              },
            ),
          ),
        );

        expect(find.text('count:0'), findsOneWidget);

        // Count Element hops from leafContext up to outerContext:
        // Builder -> MultiBinder -> Binds -> outerContext = 3 hops (NOT 42+!)
        var hops = 0;
        (leafContext as Element).visitAncestorElements((el) {
          hops++;
          return !identical(el, outerContext);
        });
        expect(hops, lessThanOrEqualTo(3));

        // Verify granular InheritedModel rebuild via Bind.of(..., rebuild: true)
        c.update();
        await tester.pump();
        expect(find.text('count:0'), findsOneWidget);
      },
    );

    testWidgets(
      'Bind.put / Bind.putContract respect autoRemove: !permanent (disposes non-permanent, keeps permanent & SintService)',
      (tester) async {
        final transient = _TransientController();
        final explicitPermanent = _TransientController();
        final infraService = _PermanentInfraService();
        final contractImpl = _RealGreetController();

        await tester.pumpWidget(
          Binds(
            binds: [
              Bind.put<_TransientController>(transient),
              Bind.put<_TransientController>(
                explicitPermanent,
                tag: 'perm',
                permanent: true,
              ),
              Bind.put<_PermanentInfraService>(infraService),
              Bind.putContract<_GreetService, _RealGreetController>(
                contractImpl,
              ),
            ],
            child: const SizedBox(),
          ),
        );

        expect(Sint.isRegistered<_TransientController>(), isTrue);
        expect(Sint.isRegistered<_GreetService>(), isTrue);

        // Unmount Binds
        await tester.pumpWidget(const SizedBox());

        // Non-permanent instances auto-removed cleanly:
        expect(transient.closes, 1);
        expect(Sint.isRegistered<_TransientController>(), isFalse);
        expect(contractImpl.closes, 1);
        expect(Sint.isRegistered<_GreetService>(), isFalse);

        // Permanent & SintService instances survive unmount:
        expect(explicitPermanent.closes, 0);
        expect(Sint.isRegistered<_TransientController>(tag: 'perm'), isTrue);
        expect(infraService.closes, 0);
        expect(Sint.isRegistered<_PermanentInfraService>(), isTrue);
      },
    );

    testWidgets(
      'SintRoot mounts root binds & initialBinding List<Bind> (supporting Bind.create + onInit/onClose) and SintPageRoute merges bindings + binds',
      (tester) async {
        var rootMounted = 0;
        var rootClosed = 0;
        var nextDraftId = 100;

        await tester.pumpWidget(
          SintMaterialApp(
            binds: [
              Bind.create<_LocalDraft>((_) => _LocalDraft(++nextDraftId)),
              Bind.lazyPut<_S01>(
                () => _S01(),
                onInit: () => rootMounted++,
                onClose: () => rootClosed++,
              ),
            ],
            initialRoute: '/merged',
            sintPages: [
              SintPage(
                name: '/merged',
                binding: _ParentRouteBinding(),
                binds: [Bind.put<_TransientController>(_TransientController())],
                page: () => Builder(
                  builder: (context) {
                    final draft = Bind.of<_LocalDraft>(context);
                    final greet = Sint.find<_RealGreetController>().greet();
                    final count = Sint.find<_TransientController>().count.value;
                    return Text('draft:${draft.id}|$greet|$count');
                  },
                ),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(rootMounted, 1);
        expect(find.text('draft:101|real|0'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        expect(rootClosed, 1);
      },
    );

    test('Sint.putContractAsync, SintOverride.contract, and scope-aware findAll/findAt work together', () async {
      final asyncImpl =
          await Sint.putContractAsync<_GreetService, _RealGreetController>(
            () async => _RealGreetController(),
            tag: 'primary',
          );
      expect(Sint.find<_GreetService>(), same(asyncImpl));
      expect(Sint.find<_RealGreetController>(), same(asyncImpl));

      late _FakeGreetController scopedInstance;
      final result = SintScope.run<String>(
        overrides: [
          SintOverride.contract<_GreetService, _FakeGreetController>(
            () => scopedInstance = _FakeGreetController('scoped'),
            tag: 'primary',
            isDefault: true,
          ),
        ],
        body: () {
          expect(Sint.find<_GreetService>().greet(), 'scoped');
          expect(Sint.find<_FakeGreetController>(), same(scopedInstance));
          expect(Sint.findAll<_GreetService>().single.greet(), 'scoped');
          expect(Sint.findAt<_GreetService>(0).greet(), 'scoped');
          return Sint.find<_GreetService>().greet();
        },
      );

      expect(result, 'scoped');
      expect(scopedInstance.closes, 1);
      expect(Sint.find<_GreetService>().greet(), 'real');
    });

    testWidgets(
      'SintView, Obx, and SintBuilder resolve side-by-side sibling SintScopes and unscoped siblings cleanly',
      (tester) async {
        final logs = <String>[];
        Sint.log = (msg, {isError = false}) {
          if (isError) logs.add(msg);
        };
        expect(Sint.isPrepared<_S20>(), isFalse);
        expect(logs, isEmpty); // No spurious error log on boolean query!

        Sint.contract<_GreetService, _RealGreetController>(
          () => _RealGreetController(),
        );
        final globalCounter = Sint.put(_TransientController());
        final leftCounter = _TransientController()..count.value = 10;
        final rightCounter = _TransientController()..count.value = 20;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                SintScope(
                  overrides: [
                    SintOverride.contractValue<
                      _GreetService,
                      _FakeGreetController
                    >(_FakeGreetController('left')),
                    SintOverride.value<_TransientController>(leftCounter),
                  ],
                  child: Column(
                    children: [
                      const _GreetSintView(),
                      Obx(
                        () => Text(
                          'obx:${Sint.find<_GreetService>().greet()}:${Sint.find<_TransientController>().count.value}',
                        ),
                      ),
                      SintBuilder<_TransientController>(
                        builder: (c) => Text('b:${c.count.value}'),
                      ),
                    ],
                  ),
                ),
                SintScope(
                  overrides: [
                    SintOverride.contractValue<
                      _GreetService,
                      _FakeGreetController
                    >(_FakeGreetController('right')),
                    SintOverride.value<_TransientController>(rightCounter),
                  ],
                  child: Column(
                    children: [
                      const _GreetSintView(),
                      Obx(
                        () => Text(
                          'obx:${Sint.find<_GreetService>().greet()}:${Sint.find<_TransientController>().count.value}',
                        ),
                      ),
                      SintBuilder<_TransientController>(
                        builder: (c) => Text('b:${c.count.value}'),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    const _GreetSintView(),
                    Obx(
                      () => Text(
                        'obx:${Sint.find<_GreetService>().greet()}:${Sint.find<_TransientController>().count.value}',
                      ),
                    ),
                    SintBuilder<_TransientController>(
                      builder: (c) => Text('b:${c.count.value}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

        expect(find.text('view:left'), findsOneWidget);
        expect(find.text('view:right'), findsOneWidget);
        expect(find.text('view:real'), findsOneWidget);
        expect(find.text('obx:left:10'), findsOneWidget);
        expect(find.text('obx:right:20'), findsOneWidget);
        expect(
          find.text('obx:real:${globalCounter.count.value}'),
          findsOneWidget,
        );
        expect(find.text('b:10'), findsOneWidget);
        expect(find.text('b:20'), findsOneWidget);
        expect(find.text('b:0'), findsOneWidget);
      },
    );
  });

  group('SINT 2.2.0 — Pillar N: Unified Middleware Guards & Initial Route', () {
    testWidgets(
      'Synchronous SintMiddleware.redirect works in Navigator 2.0 across toNamed, offNamed, and offAllNamed',
      (tester) async {
        var authed = false;
        await tester.pumpWidget(
          SintMaterialApp(
            initialRoute: '/login',
            globalMiddlewares: [_SyncAuthGuard(() => authed)],
            sintPages: [
              SintPage(name: '/login', page: () => const Text('LOGIN')),
              SintPage(name: '/dashboard', page: () => const Text('DASHBOARD')),
              SintPage(name: '/settings', page: () => const Text('SETTINGS')),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('LOGIN'), findsOneWidget);

        // Unauthenticated toNamed redirects to /login
        Sint.toNamed('/dashboard');
        await tester.pumpAndSettle();
        expect(Sint.currentRoute, '/login');

        // Unauthenticated offAllNamed ALSO enforces middleware instead of bypassing!
        Sint.offAllNamed('/settings');
        await tester.pumpAndSettle();
        expect(Sint.currentRoute, '/login');
        expect(find.text('LOGIN'), findsOneWidget);

        // Once authenticated, offAllNamed succeeds
        authed = true;
        Sint.offAllNamed('/dashboard');
        await tester.pumpAndSettle();
        expect(Sint.currentRoute, '/dashboard');
        expect(find.text('DASHBOARD'), findsOneWidget);
      },
    );

    testWidgets(
      'Cancelled middleware (returning null) in offAllNamed preserves existing navigation stack',
      (tester) async {
        await tester.pumpWidget(
          SintMaterialApp(
            initialRoute: '/',
            globalMiddlewares: [_BlockingGuard()],
            sintPages: [
              SintPage(name: '/', page: () => const Text('HOME')),
              SintPage(name: '/details', page: () => const Text('DETAILS')),
              SintPage(name: '/blocked', page: () => const Text('BLOCKED')),
            ],
          ),
        );
        await tester.pumpAndSettle();

        Sint.toNamed('/details');
        await tester.pumpAndSettle();
        expect(Sint.currentRoute, '/details');

        Sint.offAllNamed('/blocked');
        await tester.pumpAndSettle();

        // Stack was NOT wiped because middleware cancelled '/blocked'
        expect(Sint.currentRoute, '/details');
        expect(find.text('DETAILS'), findsOneWidget);
      },
    );

    testWidgets(
      'Explicit non-root initialRoute is honored on first boot even when "/" is also registered',
      (tester) async {
        await tester.pumpWidget(
          SintMaterialApp(
            initialRoute: '/onboarding',
            sintPages: [
              SintPage(name: '/', page: () => const Text('ROOT')),
              SintPage(name: '/onboarding', page: () => const Text('ONBOARD')),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(Sint.currentRoute, '/onboarding');
        expect(find.text('ONBOARD'), findsOneWidget);

        // Subsequent explicit navigation to '/' works normally
        Sint.offAllNamed('/');
        await tester.pumpAndSettle();
        expect(Sint.currentRoute, '/');
        expect(find.text('ROOT'), findsOneWidget);
      },
    );

    testWidgets(
      'SintMiddleware.onBindingsStart can append dynamic bindings even when SintPage.bindings is const []',
      (tester) async {
        await tester.pumpWidget(
          SintMaterialApp(
            initialRoute: '/dyn',
            sintPages: [
              SintPage(
                name: '/dyn',
                middlewares: [_DynamicBindingMiddleware()],
                page: () => Text('dyn:${Sint.find<_LocalDraft>().id}'),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('dyn:777'), findsOneWidget);
      },
    );
  });

  group(
    'SINT 2.2.0 — Pillar T + S: Reactive .tr & Zero-Reassemble updateLocale',
    () {
      testWidgets(
        'Obx(.tr) and Sint.computed(.tr) react in O(1) on Sint.updateLocale with lazy bundles and zero performReassemble crash',
        (tester) async {
          Sint.addTranslations({
            'en': {'hello': 'Hello'},
            'es': {'hello': 'Hola'},
          });
          Sint.registerLazyTranslations('fr', () async => {'hello': 'Bonjour'});
          Sint.locale = const Locale('en');

          final upperGreeting = Sint.computed(() => 'hello'.tr.toUpperCase());
          var obxBuilds = 0;

          await tester.pumpWidget(
            SintMaterialApp(
              locale: const Locale('en'),
              initialRoute: '/',
              sintPages: [
                SintPage(
                  name: '/',
                  page: () => Column(
                    children: [
                      Obx(() {
                        obxBuilds++;
                        return Text(
                          'tr:${'hello'.tr}|${Sint.locale?.languageCode}',
                        );
                      }),
                      Obx(() => Text('comp:${upperGreeting.value}')),
                    ],
                  ),
                ),
              ],
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('tr:Hello|en'), findsOneWidget);
          expect(find.text('comp:HELLO'), findsOneWidget);
          final buildsBefore = obxBuilds;

          // Switch to 'es' via Sint.updateLocale — no schedulerPhase crash!
          await Sint.updateLocale(const Locale('es'));
          await tester.pumpAndSettle();

          expect(find.text('tr:Hola|es'), findsOneWidget);
          expect(find.text('comp:HOLA'), findsOneWidget);
          expect(obxBuilds, greaterThan(buildsBefore));

          // Switch to lazy 'fr' bundle
          await Sint.updateLocale(const Locale('fr'));
          await tester.pumpAndSettle();

          expect(find.text('tr:Bonjour|fr'), findsOneWidget);
          expect(find.text('comp:BONJOUR'), findsOneWidget);

          upperGreeting.dispose();
        },
      );

      test(
        'Headless Sint.updateLocale works in pure unit tests without SintRoot',
        () async {
          Sint.addTranslations({
            'en': {'k': 'One'},
            'es': {'k': 'Uno'},
          });
          Sint.locale = const Locale('en');
          final derived = Sint.computed(() => 'k'.tr);
          expect(derived.value, 'One');

          await Sint.updateLocale(const Locale('es'));
          expect(derived.value, 'Uno');
          derived.dispose();
        },
      );
    },
  );

  group('SINT 2.2.0 — Pillar S: Single-Slot Obx, Incremental Externals & Collections', () {
    testWidgets(
      'Obx promotes seamlessly from 1-signal fast slot to multi-signal and reuses external ValueNotifier listeners across rebuilds',
      (tester) async {
        final mode = 0.obs;
        final extra = 10.obs;
        final externalNotifier = _CountingValueNotifier(5);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              children: [
                // Starts on 1-signal fast slot (mode == 0), then promotes to 2-signal (mode == 1)
                Obx(
                  () => Text(
                    mode.value == 0
                        ? 'single:${mode.value}'
                        : 'multi:${mode.value + extra.value}',
                  ),
                ),
                // Reads both an Rx and an external ValueNotifier
                Obx(() => Text('ext:${mode.value + externalNotifier.rxValue}')),
              ],
            ),
          ),
        );

        expect(find.text('single:0'), findsOneWidget);
        expect(find.text('ext:5'), findsOneWidget);
        expect(externalNotifier.addCalls, 1);
        expect(externalNotifier.removeCalls, 0);

        // Promote first Obx to multi-signal AND rebuild second Obx:
        // externalNotifier listener must be REUSED (not removed & re-added!)
        mode.value = 1;
        await tester.pump();
        expect(find.text('multi:11'), findsOneWidget);
        expect(find.text('ext:6'), findsOneWidget);
        expect(externalNotifier.addCalls, 1);
        expect(externalNotifier.removeCalls, 0);

        extra.value = 20;
        await tester.pump();
        expect(find.text('multi:21'), findsOneWidget);

        // Prune back to 1 signal (extra changes should no longer rebuild)
        mode.value = 0;
        await tester.pump();
        expect(find.text('single:0'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        expect(externalNotifier.removeCalls, 1);
      },
    );

    test('Rx.trigger notifies synchronous ListNotifier engine (ever / Obx / Computed) even when value is unchanged', () {
      final pulse = 2.obs;
      var syncHits = 0;
      final sub = pulse.addListener(() => syncHits++);

      pulse.value = 2; // unchanged after initial -> firstRebuild consumes 1st
      final baseline = syncHits;

      pulse.value = 2; // identical value -> 0 notifications
      expect(syncHits, baseline);

      pulse.trigger(2); // explicit trigger with identical value -> notifies!
      expect(syncHits, baseline + 1);

      sub();
    });

    test('RxList.insert/removeAt emit 1 notification (not O(N)) and RxMap/RxSet.assignAll short-circuit on equal contents', () {
      final list = <int>[1, 2, 3, 4, 5].obs;
      var listHits = 0;
      list.addListener(() => listHits++);

      list.insert(0, 0);
      expect(listHits, 1);
      expect(list, [0, 1, 2, 3, 4, 5]);

      final removed = list.removeAt(0);
      expect(removed, 0);
      expect(listHits, 2);

      list.addAll(const <int>[]);
      expect(listHits, 2); // empty addAll emits 0 spurious notifications

      final map = <String, int>{'a': 1, 'b': 2}.obs;
      var mapHits = 0;
      map.addListener(() => mapHits++);

      map.assignAll({'a': 1, 'b': 2}); // equal content -> 0 notifications
      expect(mapHits, 0);
      expect(map.containsKey('a'), isTrue);

      map.assign('x', 99);
      expect(mapHits, 1);
      expect(map, {'x': 99});
      map.assign('x', 99); // equal single entry -> 0 notifications
      expect(mapHits, 1);

      final set = <String>{'k1', 'k2'}.obs;
      var setHits = 0;
      set.addListener(() => setHits++);

      set.assignAll({'k2', 'k1'}); // equal content -> 0 notifications
      expect(setHits, 0);

      set.assign('only');
      expect(setHits, 1);
      set.assign('only'); // equal single item -> 0 notifications
      expect(setHits, 1);
    });
  });
}
